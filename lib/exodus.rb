require 'mongo_mapper'
Dir[File.dirname(__FILE__) + "/exodus/**/*.rb"].sort.each { |file| require file}

module Exodus
	class << self
		attr_reader :migrations_info

		def configuration
		  @migrations_info ||= MigrationInfo.new
		end

		def configure
		  yield(configuration) if block_given?
		end

		# Loads and runs a number of migrations equal to step (or all of them if step is nil)
		def run_migrations(direction, migrations, step = nil)			
			if migrations
				sorted_migrations = sort_migrations(migrations)
				sorted_migrations = order_with_direction(sorted_migrations, direction)
				sorted_migrations = sorted_migrations.shift(step.to_i) if step 

				sorted_migrations.each {|migration_class, args| run_each(migration_class, direction, args)} 
			else
				puts "no migrations given in argument!"
			end
		end

	  def sort_migrations(migrations)
	    migrations.sort_by {|migration,args| migration.migration_number }
	  end

	  def order_with_direction(migrations, direction)
	  	direction == Migration::UP ? migrations : migrations.reverse 
	  end

	  def run_each(migration_class, direction, args = {})
	  	puts "\n"
	  	args ||= {}
	  	
	  	run_one_migration(migration_class, direction, args)
	  	puts "\n"
	  end

	  def run_one_migration(migration_class, direction, args)
	  	# Going throught MRD because MM request returns nil for some reason
	  	current_migration = migration_class.load(migration_class.collection.find('status.arguments' => args).first)
	  	current_migration ||= migration_class.new(:status => {:arguments => args})

	  	if current_migration.is_runnable?(direction)
	  		# Make sure we save all info in case of a failure 
	  		begin
	  			current_migration.run(direction)
	  			current_migration.status.error = nil
	  		rescue Exception => e
	  			current_migration.failure = e
	  			current_migration.save!
	  			raise
	  		end

	  		# save the migration
	    	current_migration.save!
	    else
	    	puts "#{current_migration.class}#{current_migration.status.arguments}(#{direction}) as Already been run (or is not runnable)."
	    end
	  end
	end
end