require 'mongo_mapper'
require File.dirname(__FILE__) + '/exodus/helpers/text_formatter'
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

		# Loads existing migrations into memory
		def load_migrations
			raise StandardError, 'A migrations directory is needed in order to load migrations.' unless migrations_info.migrations_directory
			Dir[migrations_info.migrations_directory + '/*.rb'].each { |file|  require file}
		end

		# Returns the path of the rake file 
		def tasks
			File.dirname(__FILE__) + '/../tasks/exodus.rake'
		end

		# Sorts and executes a number of migrations equal to step (or all of them if step is nil)
		def sort_and_run_migrations(direction, migrations_info, step = nil, show_characteristic = false)			
			if migrations_info
				sorted_migrations_info = order_with_direction(migrations_info, direction)
				runnable_migrations = find_runable_migrations(direction, sorted_migrations_info, step)

				if show_characteristic 
					runnable_migrations.map(&:characteristic)
				else
					run_migrations(direction, runnable_migrations)
				end
			else
				raise StandardError, "no migrations given in argument!"
			end
		end

		# Instanciates all of the migrations and returns the ones that are runnable
		def find_runable_migrations(direction, migrations_info, step)
	  	runnable_migrations = migrations_info.map do |migration_class, args| 
	  		migration = instanciate_migration(migration_class, args)
	  		migration if migration.is_runnable?(direction)
	  	end.compact

	  	step ? runnable_migrations.shift(step.to_i) : runnable_migrations
	  end

	  # Migrations order need to be reverted if the direction is down 
	  # (we want the latest executed migration to be the first reverted)
	  def order_with_direction(migrations_info, direction)
	  	sorted_migrations = sort_migrations(migrations_info)
	  	direction == Migration::UP ? sorted_migrations : sorted_migrations.reverse 
	  end

	  # Sorts migrations using the migration number
	  def sort_migrations(migrations_info)
	    migrations_info.sort_by {|migration,args| migration.migration_number }
	  end

	  # Runs each migration separately, migration's arguments default value is set to an empty hash
	  def run_migrations(direction, migrations)
	  	migrations.each do |migration|
		  	print_tabulation { run_one_migration(migration, direction) }
		  end
	  end
	  
	  # Runs the migration and save the current status into mongo
	  def run_one_migration(migration, direction)
  		begin
  			migration.run(direction)
  			migration.status.error = nil
  		rescue Exception => e
  			migration.failure = e
  			migration.save!
  			raise
  		end

	    migration.save!
	  end

	  # Database lookup to find  a migration given its class and its arguments
	  # Instanciates it if the migration is not present in the database 
	  def instanciate_migration(migration_class, args)
	  	args ||= {}
	  	find_existing_migration(migration_class, args) || migration_class.new(:status => {:arguments => args})
	  end

	  # Looks up in the database if a migration with the same class and same arguments already exists
	  # Returns nil or the migration if one is found
	  def find_existing_migration(migration_class, args)
	  	existing_migrations = migration_class.collection.find('status.arguments' => args)
	  	existing_migrations.detect do |migration|
	  		existing_migration = migration_class.load(migration)

				return existing_migration if existing_migration.is_a?(migration_class)
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