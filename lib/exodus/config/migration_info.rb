require 'yaml'

module Exodus
	class MigrationInfo
		attr_accessor :info, :migrations_directory
		attr_reader :config_file, :db, :connection, :rake_namespace

		def initialize(file = nil)
			config_file = file if file
		end

		def db=(database)
			MongoMapper.database = database
		end

		def connection=(conn)
			MongoMapper.connection = conn
		end

		def config_file=(file)
			if File.exists?(file)
				@config_file = file
				self.info = YAML.load_file(file)
				self.rake_namespace = (info['migration'] && info['migration']['rake_namespace']).to_s
			else
				raise ArgumentError, "#{file} not found"
			end
		end

		def rake_namespace=(namespace)
			@rake_namespace = namespace.to_s.empty? || namespace.end_with?(':') ? namespace.to_s : namespace + ':'
		end

		def migrate
			verify_yml_syntax { @info['migration']['migrate'] }
		end

		def rollback
			verify_yml_syntax { @info['migration']['rollback'] }
		end

		def migrate_custom
			verify_yml_syntax { @info['migration']['custom']['migrate'] }
		end

		def rollback_custom
			verify_yml_syntax { @info['migration']['custom']['rollback'] }
		end

		def to_s
			@info
		end

		private

		def verify_yml_syntax
			Raise StandardError, "No configuration file specified" unless self.config_file

			begin
				yield if block_given?
			rescue
				Raise StandardError, "Syntax error detected in config file #{self.config_file}. To find the correct syntax take a look at the documentation."
			end
		end
	end
end