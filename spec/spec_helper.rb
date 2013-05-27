require File.dirname(__FILE__) + '/../lib/exodus'
Dir["#{File.dirname(__FILE__)}/support/*.rb"].each { |f| require f }
mongo_uri = 'mongodb://exodus:exodus@dharma.mongohq.com:10048/Exodus-test'

Exodus.configure do |config| 
	config.db = 'Exodus-test'
	config.connection = Mongo::MongoClient.from_uri(mongo_uri)
	config.config_file = File.dirname(__FILE__) + '/support/config.yml'
end

