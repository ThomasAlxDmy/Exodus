def time_it(task, &block)
  puts "#{task} starting..."
  start = Time.now
  yield
  puts "#{task} Done in (#{Time.now-start}s)!!"
end

def step
  ENV['STEP']
end

task :require_env do
  require 'csv'
  require File.dirname(__FILE__) + '/../lib/exodus'
  Exodus.load_migrations
end

namespace :db do
  desc "Migrate the database"
  task :migrate => :require_env do 
    time_it "db:migrate#{" step #{step}" if step}" do 
      migrations = Exodus::Migration.load_all(Exodus.migrations_info.migrate)
      Exodus::run_migrations('up', migrations, step)
    end
  end

  desc "Rolls the database back to the previous version"
  task :rollback => :require_env do 
    time_it "db:rollback#{" step #{step}" if step}" do 
      migrations = Exodus::Migration.load_all(Exodus.migrations_info.rollback)
      Exodus::run_migrations('down', migrations, step)
    end
  end

  desc "Shows informations about the current mongo connection"
  task :mongo_info => :require_env do 
    p MongoMapper.database
  end

  namespace :migrate do
    desc "Manually migrates specified migrations (specify migrations or use config/migration.yml)"
    task :custom, [:migrations_info] => :require_env do |t, args|
      time_it "db:migrate_custom#{" step #{step}" if step}" do 
         migrations = if args[:migrations_info]
          YAML.load(args[:migrations_info])
        else
          Exodus::Migration.load_custom(Exodus.migrations_info.migrate_custom)
        end

        Exodus::run_migrations('up', migrations, step)
      end
    end

    desc "Lists all the migrations"
    task :list => :require_env do 
      Exodus::Migration.list
    end

    desc "Loads migration.yml and displays it"
    task :yml_status => :require_env do 
      pp Exodus.migrations_info.to_s
    end

    desc "Displays the current status of migrations"
    task :status => :require_env do 
      Exodus::Migration.db_status
    end
  end

  namespace :rollback do
    desc "Manually rolls the database back using specified migrations (specify migrations or use config/migration.yml)"
    task :custom, [:migrations_info] => :require_env do |t, args|
      time_it "db:rollback_custom#{" step #{step}" if step}" do 
         migrations = if args[:migrations_info]
          YAML.load(args[:migrations_info])
        else
          Exodus::Migration.load_custom(Exodus.migrations_info.rollback_custom)
        end

        Exodus::run_migrations('down', migrations, step)
      end
    end
  end
end