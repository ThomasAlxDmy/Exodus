module Exodus
	class MigrationError
		include MongoMapper::EmbeddedDocument
		
	  key :error_message,               String
	  key :error_class,                 String
	  key :error_backtrace,             Array

	  embedded_in :migration_status
	end
end