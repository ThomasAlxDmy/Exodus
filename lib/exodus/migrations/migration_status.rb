module Exodus
  class MigrationStatus
    include MongoMapper::EmbeddedDocument

    key :message,                     String
    key :current_status,  						Integer, :default => 0
    key :execution_time,              Float, :default => 0
    key :last_succesful_completion,   Time
    key :direction,                   String, :default => Migration::UP
    key :arguments, 									Hash, :default => {}

    embedded_in :migration
    has_one :error, :class_name => "Exodus::MigrationError", :autosave => true

    def direction_to_i
      self.direction == Migration::UP ? 1 : -1
    end

    def status_processed?(migration_direction, status_to_process)
    	(migration_direction == Migration::UP && current_status >= status_to_process) || (migration_direction == Migration::DOWN && current_status <= status_to_process)
    end

    def to_string
      "\t#{direction}\t\t #{arguments}\t\t #{current_status} \t\t #{last_succesful_completion} \t\t #{message}"
    end

    def reset
      self.message = nil
      self.current_status = 0
      self.execution_time = 0
      self.last_succesful_completion = nil
    end
  end
end