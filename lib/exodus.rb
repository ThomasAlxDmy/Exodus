require 'mongo_mapper'
require File.dirname(__FILE__) + '/exodus/config/migration_info'
require File.dirname(__FILE__) + '/exodus/migrations/migration'
require File.dirname(__FILE__) + '/exodus/migrations/migration_error'
require File.dirname(__FILE__) + '/exodus/migrations/migration_status'

module Exodus
	class << self
		attr_reader :migrations_info

		def configuration
		  @migrations_info ||= MigrationInfo.new
		end

		def configure
		  yield(configuration) if block_given?
		end

		# Executes a number of migrations equal to step (or all of them if step is nil)
		def run_migrations(direction, migrations, step = nil)			
			if migrations
				sorted_migrations = order_with_direction(sorted_migrations, direction)
				sorted_migrations = sorted_migrations.shift(step.to_i) if step 

				run_each(sorted_migrations)
			else
				puts "no migrations given in argument!"
			end
		end

	  # Migrations order need to be reverted if the direction is down 
	  # (we want the latest executed migration to be the first reverted)
	  def order_with_direction(migrations, direction)
	  	sorted_migrations = sort_migrations(migrations)
	  	direction == Migration::UP ? sorted_migrations : sorted_migrations.reverse 
	  end

	  def sort_migrations(migrations)
	    migrations.sort_by {|migration,args| migration.migration_number }
	  end

	  # Runs each migration separately, migration's arguments default value is set to an empty hash
	  def run_each(direction, migrations)
	  	migrations.each do |migration_class, args|
		  	print_tabulation { run_one_migration(migration_class, direction, args || {}) }
		  end
	  end

	  # Looks up in the database if a migration with the same class and same arguments already exists
	  # Otherwise instanciate a new one
	  # Runs the migration if it is runnable
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

	    	current_migration.save!
	    else
	    	puts "#{current_migration.class}#{current_migration.status.arguments}(#{direction}) as Already been run (or is not runnable)."
	    end
	  end

	  private

	  # Prints tabulation before execting a given block
	  def print_tabulation
	  	puts "\n"
		  yield if block_given?
		  puts "\n"
	  end
	end
end