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

    # Checks if a status has been processed
    # a Status has been processed when:
    # The current status is superior or equal to the given status and the migration direction is UP
    # The current status is inferior or equal to the given status and the migration direction is DOWN
    def status_processed?(migration_direction, status_to_process)
    	(migration_direction == Migration::UP && current_status >= status_to_process) || (migration_direction == Migration::DOWN && current_status <= status_to_process)
    end

    def to_string
      "\t#{direction}\t\t #{current_status} \t\t #{arguments}\t\t #{last_succesful_completion} \t\t #{message}"
    end

    def to_a
      [direction, current_status, arguments, last_succesful_completion, message]
    end

    def to_a_string
      self.to_a.map(&:to_s)
    end

    # Resets a status
    def reset!
      self.message = nil
      self.current_status = 0
      self.execution_time = 0
      self.last_succesful_completion = nil
    end
  end
end