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

    class << self 
      attr_accessor :migration_number

      # Overides #inherited to have an easy and reliable way to find all migrations
      # Migrations need to have embedded callbacks on depending on the MM's version 
      def inherited(klass)
        klass.embedded_callbacks_on if defined?(MongoMapper::Plugins::EmbeddedCallbacks::ClassMethods) #MongoMapper version compatibility
        klass.migration_number = 0
        @migrations_with_args << [klass]
        super(klass)
      end

      # Using a list of migrations
      # Formats and overrides migrations without arguments using ones that have given arguments
      # Removes duplicates 
      # migrations: list of migrations => [[MyMigration, {:my_args => 'some_args'}]] 
      def load_all(migrations)
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

      # Using a list of migrations formats them and removes duplicates 
      # migrations: list of migrations => [[MyMigration, {:my_args => 'some_args'}]] 
      def load_custom(migrations)
        migrations.map {|migration_str, args| format(migration_str, args) }.uniq
      end

      # Formats a given migration making sure the first argument is a class
      # and the second one -if it exists- is a none empty hash
      def format(migration, args = {})
        migration_klass = migration.is_a?(String) ? migration.constantize : migration
        args.is_a?(Hash) && args.empty? ? [migration_klass] : [migration_klass, args]
      end

      # Prints in the console all migrations class with their name and description  
      def list
        puts "\n Migration n#:  \t\t   Name: \t\t\t\t Description:"
        puts '-' * 100, "\n"

        @migrations_with_args.map do|migration, args|
          m = migration.new
          puts "\t#{migration.migration_number} \t\t #{migration.name} \t\t #{m.description}"
        end

        puts "\n\n"
      end 

      # Prints in the console all migrations that has been ran at least once with their name and description  
      def db_status
        puts "\n Migration n#:  \t   Name: \t\t     Direction:     Arguments:      Current Status: \t Last completion Date: \t\t Current Message:"
        puts '-' * 175, "\n"

        Migration.all.each do|migration|
          puts "\t#{migration.class.migration_number} \t #{migration.class.name} \t #{migration.status.to_string}"
        end

        puts "\n\n"
      end 
    end

    # Makes sure status get instanciated on migration's instanciation
    def initialize(args = {})
      self.build_status(args[:status])
      super(args)
    end

    # Runs the migration following the direction
    # sets the status, the execution time and the last succesful_completion date
    def run(direction)
      self.status.direction = direction

      # reset the status if the job is rerunnable and has already be completed
      self.status = self.status.reset if self.rerunnable_safe && completed?(direction) 
      self.status.execution_time = time_it { self.send(direction) }
      self.status.last_succesful_completion = Time.now
    end

    # Sets an error to migration status 
    def failure=(exception)
      self.status.error = MigrationError.new(:error_message => exception.message, :error_class => exception.class, :error_backtrace => exception.backtrace)
    end

    # Checks if a migration can be run
    def is_runnable?(direction)
      rerunnable_safe || (direction == UP && status.current_status < status_complete) || (direction == DOWN && status.current_status > 0)
    end

    # Checks if a migration as been completed
    def completed?(direction) 
      return false if self.status.execution_time == 0
      (direction == UP && self.status.current_status == self.status_complete) || (direction == DOWN && self.status.current_status == 0)
    end

    protected

    # Executes a given block if the status has not being processed
    # Then update the status
    def step(step_message = nil, step_status = 1)
      unless status.status_processed?(status.direction, step_status)
        self.status.message = step_message
        puts "\t #{step_message}" 

        yield if block_given?
        self.status.current_status += status.direction_to_i
      end
    end

    # Prints a given message with the current time 
    def tick(msg)
      puts "#{Time.now}: #{msg}"
    end

    # Executes a block and returns the time it took to be executed
    def time_it
      puts "Running #{self.class}[#{self.status.arguments}](#{self.status.direction})"

      start = Time.now
      yield if block_given?
      end_time = Time.now - start
      
      puts "Tasks #{self.class} executed in #{end_time} seconds. \n\n"
      end_time
    end

    # contains the code that will be executed when run(up) will be called
    def up
      raise StandardError, 'Needs to be implemented in child class.'
    end

    # contains the code that will be executed when run(down) will be called
    def down
      raise StandardError, 'Needs to be implemented in child class.'
    end
  end
end

Dir[File.dirname(__FILE__) + "/*.rb"].sort.each { |file|  require file;}