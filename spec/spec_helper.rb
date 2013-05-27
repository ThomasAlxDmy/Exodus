require File.dirname(__FILE__) + '/../lib/exodus'
Dir["#{File.dirname(__FILE__)}/support/*.rb"].each { |f| require f }

Exodus.configure do |config| 
	config.db = 'database_test'
	config.connection = Mongo::MongoClient.new("127.0.0.1", 27017, :pool_size => 5, :pool_timeout => 5)
	config.config_file = File.dirname(__FILE__) + '/support/config.yml'
end

