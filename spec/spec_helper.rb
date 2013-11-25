require File.dirname(__FILE__) + '/../lib/exodus'
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

