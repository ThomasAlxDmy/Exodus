Exodus - a migration framework for MongoDb
=============

# Intro 

## A migration Framework for a schemaless database ??

  After working with Mongo for long time now I can tell you working with a schemaless database does not mean you will never need any migrations. Within the same collection Mongo allows to have documents with a complete different structure, however in some case is you might want to keep data consistency; Especially when your code is live in production and used by millions of users. 

  There is a plenty of way to modify documents data structure and after a deep reflexion I realized it makes more sens to use migration framework. A migration framework provides a lot of advantages, such as: 

  * It allows you to know at any time which migration has been ran on any given system  
  * It's Auto runnable on deploy
  * When switching enviromment (dev, pre-prod, prod) you don't need to worry if the script has been ran or not. The framework takes care of it for you


# Installation
  
  Add this line to your application's Gemfile:

      gem 'exodus'

  And then execute bundle install:

      $ bundle

  Or install it yourself as:

    $ gem install exodus

# Configuration

  You need to configure 4 things before using Exodus: the database name, the mongodb connection, the config file location and the path to the directory that will include your migrations:

    require 'exodus'

    Exodus.configure do |config| 
      config.db = 'migration_db'
      config.connection = Mongo::MongoClient.new("127.0.0.1", 27017, :pool_size => 5, :pool_timeout => 5)
      config.config_file = File.dirname(__FILE__) + '/config/migrations.yml'
      config.migrations_directory = File.dirname(__FILE__) + '/models/migrations'
    end

  Then you just need to loads the migrations tasks by adding the following line to your rakefile:

    load Exodus.tasks 

  ... And you're all set!


# Basic knowledge

* All Migrations have to be ruby classes that inherits from Migration class. 
* Migrations have a direction (UP or DOWN)
* UP means the migration has been migrated
* DOWN means the migration has not been run or has been rollbacked
* All migrations have a current_status and status_complete
* When current_status is equal to 0 it means the migration has not been run or has been succesfully rollbacked
* When current_status is equal to status_complete it means the migration has been succefully migrated
* We decided to keep track of migration by enumerating them.
* Migrations will run in order using the migration_number
* Migrations can be rerunnable safe, rerunnable safe migrations will run on each db:migrate even if the migration has already been run!

## To Do when writting your own

* Give it a migration_number
* Initialize it and define status_complete and description
* Write the UP method that will be call when migrating the migration
* Write the DOWN method that will be call when rolling back the migration
* If your migration contains distinct steps that you want to split up I recommand using the "step" DSL


## Good example

    class RenameNameToFirstName < Exodus::Migration
      self.migration_number = 1

      def initialize(args = {})
        super(args)
        self.status_complete = 3
        self.description = 'Change name to first_name'
      end

      def up
        step("Creating first_name index", 1) do
          puts Account.collection.ensure_index({:first_name => 1}, {:unique => true, :sparse => true})
        end

        step("Renaming", 2) do
          puts Account.collection.update({'name' => {'$exists' => true}}, {'$rename' => {'name' => 'first_name'}},{:multi => true})
        end

        step("Dropping name index", 3) do
          puts Account.collection.drop_index([[:name,1]])
        end

        self.status.message = "Migration Executed!"
      end

      def down
        step("Creating name index", 2) do 
          puts Account.collection.ensure_index({:name => 1}, {:unique => true, :sparse => true})
        end

        step("Renaming", 1) do 
          puts Account.collection.update({'first_name' => {'$exists' => true}}, {'$rename' => {'first_name' => 'name'}},{:multi => true})
        end

        step("Dropping first_name index", 0) do 
          puts Account.collection.drop_index([[:first_name,1]])
        end

        self.status.message = "Rollback Executed!"
      end
    end

# Commands

## db:migrate
  Executes all migrations that haven't run yet. You can the STEP enviroment to run only the first x ones.

    rake db:migrate
    rake db:migrate STEP=2

## db:rollback
  Rolls back all migrations that haven't run yet. You can set the STEP enviroment variable to rollback only the last x ones.

    rake db:rollback
    rake db:rollback STEP=2

## db:migrate:custom
  Executes all custom migrations that haven't run yet. Custom migrations will be loaded from your config file. Custom migrations will run in order of appearence. You can set the STEP enviroment variable to rollback only the last x ones.

    rake db:migrate:custom
    rake db:migrate:custom STEP=2

## db:rollback:custom
  Executes all custom migrations that haven't run yet. Custom migrations will be loaded from your config file. Custom migrations will run in order of appearence. You can set the STEP enviroment variable to rollback only the last x ones.

    rake db:rollback:custom
    rake db:rollback:custom STEP=2

## db:migrate:list
  Lists all the migrations.

    rake db:migrate:list

## db:migrate:status
  Gives a preview of what as been run on the current database.

    rake db:migrate:status

## db:migrate:yml_status
  Prints on the screen the content of the yml configuration file

    rake db:migrate:yml_status

## db:mongo_info
  Prints on the screen information about the current mongo connection

    rake db:mongo_info


