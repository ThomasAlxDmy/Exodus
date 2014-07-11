require File.dirname(__FILE__) + '/../lib/exodus'
require File.dirname(__FILE__) + '/support/test_class_definition'
include Exodus::Testing

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :should
  end
end

Dir["#{File.dirname(__FILE__)}/support/*.rb"].each { |f| require f }
mongo_uri = 'mongodb://exodus:exodus@dharma.mongohq.com:10048/Exodus-test'
local_uri = 'mongodb://localhost:27017/Exodus-test'

Exodus.configure do |config|
	config.db = 'Exodus-test'
	config.config_file = File.dirname(__FILE__) + '/support/config.yml'

	begin
		config.connection = Mongo::MongoClient.from_uri(mongo_uri)
	rescue Mongo::ConnectionFailure => e
		puts e.message, 'Connecting to local db...'
		config.connection = Mongo::MongoClient.from_uri(local_uri)
	end
end


module Exodus::Testing

  # Need to create dynamic classes in order to fully test the migration framework
  def create_dynamic_class(class_name)
    unless Object.const_defined?(class_name.to_sym)
      Object.const_set(class_name, Class.new(Exodus::Migration))
      class_name.constantize.class_eval(CLASS_CONTENT["@#{class_name}".to_sym].to_s)
    end
  end

  def migration_should_be_up(migration)
    migration.status.arguments.should be_empty
    migration.status.current_status.should == 1
    migration.status.direction.should == 'up'
    migration.status.execution_time.should > 0
    migration.status.last_succesful_completion.should_not be nil
  end

  def migration_should_be_down(migration)
    migration.status.arguments.should be_empty
    migration.status.current_status.should == 0
    migration.status.direction.should == 'down'
    migration.status.execution_time.should > 0
  end

  def reset_collections(*classes)
    classes.each {|c| c.collection.drop}
  end

  def instanciate_and_run_up_migrations(*migrations_info)
    migrations = migrations_info.map {|klass,arguments| Exodus.instanciate_migration(klass,arguments)}
    Exodus.run_migrations('up', migrations)
  end

  def get_users_names
    UserSupport.all.map(&:name)
  end
end
