module Exodus
  class Migration
    include MongoMapper::Document
    UP = 'up'
    DOWN = 'down'
    @migrations_with_args = []

    timestamps!

    key :description,                 String
    key :status_complete,             Integer, :default => 1
    key :rerunnable_safe,             Boolean, :default => false  # Be careful if the job is rerunnable_safe he will re-run on each db:migrate

    has_one :status, :class_name => "Exodus::MigrationStatus", :autosave => true

    def initialize(args = {})
      # Why I need to do that?!!!
      self.build_status(args[:status])

      super(args)
    end

    def self.inherited(klass)
      klass.embedded_callbacks_on if defined?(MongoMapper::Plugins::EmbeddedCallbacks::ClassMethods)
      klass.migration_number = 0
      @migrations_with_args << [klass]
      super(klass)
    end

    def self.load_all(migrations)
      if migrations
        migrations.each do |migration, args|
          if migration && args
            formated_migration = format(migration, args)
            migration, args = formated_migration

            unless @migrations_with_args.include?(formated_migration)
              @migrations_with_args.delete_if {|loaded_migration, loaded_args| migration == loaded_migration && (loaded_args.nil? || loaded_args.empty?) }
              @migrations_with_args << formated_migration
            end
          end
        end 
      end

      @migrations_with_args
    end

    def self.load_custom(migrations)
      migrations.map {|migration_str, args| format(migration_str, args) }.uniq
    end

    def self.format(migration, args = {})
      migration_klass = migration.is_a?(String) ? migration.constantize : migration
      args.empty? ? [migration_klass] : [migration_klass, args]
    end

    def self.migration_number
      @migration_number
    end

    def self.migration_number=(number)
      @migration_number = number 
    end

    def self.list
      puts "\n Migration n#:  \t\t   Name: \t\t\t\t Description:"
      puts '-' * 100, "\n"

      @migrations_with_args.map do|migration, args|
        m = migration.new
        puts "\t#{migration.migration_number} \t\t #{migration.name} \t\t #{m.description}"
      end

      puts "\n\n"
    end 

    def self.db_status
      puts "\n Migration n#:  \t   Name: \t\t     Direction:     Arguments:      Current Status: \t Last completion Date: \t\t Current Message:"
      puts '-' * 175, "\n"

      Migration.all.each do|migration|
        puts "\t#{migration.class.migration_number} \t #{migration.class.name} \t #{migration.status.to_string}"
      end

      puts "\n\n"
    end 

    def run(direction)
      self.status.direction = direction

      # reset the status if the job is rerunnable and has already be completed
      self.status = self.status.reset if self.rerunnable_safe && completed?(direction) 
      time_it { self.public_send(direction) }
      self.status.last_succesful_completion = Time.now
    end

    def step(step_message = nil, step_status = 1)
      unless status.status_processed?(status.direction, step_status)
        self.status.message = step_message
        puts "\t #{step_message}" 
        yield if block_given?
        self.status.current_status += status.direction_to_i
      end
    end

    def tick(msg)
      puts "#{Time.now}: #{msg}"
    end

    def failure=(exception)
      self.status.error = MigrationError.new(:error_message => exception.message, :error_class => exception.class, :error_backtrace => exception.backtrace)
    end

    def time_it
      puts "Running #{self.class}[#{self.status.arguments}](#{self.status.direction})"

      start = Time.now
      result = yield if block_given?
      end_time = Time.now - start
      
      puts "Tasks #{self.class} executed in #{end_time} seconds. \n\n"
      self.status.execution_time = end_time
    end

    def completed?(direction) 
      return false if self.status.execution_time == 0
      (direction == 'up' && self.status.current_status == self.status_complete) || (direction == 'down' && self.status.current_status == 0)
    end

    def is_runnable?(direction)
      rerunnable_safe || (direction == 'up' && status.current_status < status_complete) || (direction == 'down' && status.current_status > 0)
    end

    def up
      raise StandardError, 'Needs to be implemented in child class.'
    end

    def down
      raise StandardError, 'Needs to be implemented in child class.'
    end
  end
end

Dir[File.dirname(__FILE__) + "/*.rb"].sort.each { |file|  require file;}