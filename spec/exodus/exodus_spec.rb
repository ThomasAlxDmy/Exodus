require "spec_helper"

describe Exodus do 
  describe Exodus::MigrationInfo do 
    describe "#rake_namespace" do 
      it "should use the namespace provided in the yml file" do 
        Exodus.configuration.rake_namespace.should == 'test:'
      end

      it "should be blank when no namespace is given" do 
        Exodus.configuration.rake_namespace = nil
        Exodus.configuration.rake_namespace.should == ''

        Exodus.configuration.rake_namespace = ''
        Exodus.configuration.rake_namespace.should == ''
      end

      it "should end with ':' when a namespace is given" do 
        Exodus.configuration.rake_namespace = 'test1'
        Exodus.configuration.rake_namespace.should == 'test1:'

        Exodus.configuration.rake_namespace = 'test2:'
        Exodus.configuration.rake_namespace.should == 'test2:'
      end
    end
  end

  before :all do
    Exodus::Migration.collection.drop
  end

  describe "sort_migrations" do 
  	before do
      create_dynamic_class('Migration_test4')
      create_dynamic_class('Migration_test3')

      Migration_test3.migration_number = 3
      Migration_test4.migration_number = 4
    end

    it "migrations should not be sorted by default" do 
      unsorted_migrations = Exodus::Migration.load_all([])
      migrations_numbers = unsorted_migrations.map {|migration, args| migration.migration_number }

      migrations_numbers.should_not == migrations_numbers.sort          
    end

    it "should return the migrations sorted by migration number" do 
      unsorted_migrations = Exodus::Migration.load_all([])
      migrations_numbers = unsorted_migrations.map {|migration, args| migration.migration_number }

      sorted_migrations = Exodus::sort_migrations(unsorted_migrations)
      sorted_migrations_numbers = sorted_migrations.map {|migration, args| migration.migration_number }
      sorted_migrations_numbers.should == migrations_numbers.sort          
    end
  end

  describe "order_with_direction" do 
  	before do
      create_dynamic_class('Migration_test4')
      create_dynamic_class('Migration_test3')
      create_dynamic_class('Migration_test5')

      Migration_test3.migration_number = 3
      Migration_test4.migration_number = 4
      Migration_test5.migration_number = 5

      unsorted_migrations = Exodus::Migration.load_all([])
	    @migrations_numbers = unsorted_migrations.map {|migration, args| migration.migration_number }

	    sorted_migrations = Exodus.order_with_direction(unsorted_migrations, 'up')
	    @ordered_up = sorted_migrations.map {|migration, args| migration.migration_number }

			sorted_migrations = Exodus.order_with_direction(unsorted_migrations, 'down')
	    @ordered_down = sorted_migrations.map {|migration, args| migration.migration_number }
    end

    describe "when direction is UP" do
	    it "should be sorted ascendingly" do 
	      @ordered_up.should == @migrations_numbers.sort    
	    end
	  end

    describe "when direction is UP" do
	    it "should be sorted ascendingly" do 
	      @ordered_down.should == @migrations_numbers.sort.reverse    
	    end
	  end
  end

  describe "#tasks" do 
  	it "should return the current path of exodus.rake" do
  		rake_file = Pathname.new(File.dirname(__FILE__) + '/../../tasks/exodus.rake')
  		Pathname.new(Exodus.tasks).realpath.to_s.should == rake_file.realpath.to_s
  	end 
  end

  describe "run_one_migration" do
    before do
      create_dynamic_class('Migration_test6')
      create_dynamic_class('Migration_test7')
    end

    before :each do
      Exodus::Migration.collection.drop
    end

    describe "When the migration has not been ran" do 
      describe "with a valid migration" do 
        it "should successfully create the migration" do 
          migration = Exodus.instanciate_migration(Migration_test6, {})
          lambda{ Exodus.run_one_migration(migration, 'up')}.should change(Exodus::Migration, :count).by(1)
        end
      end

      describe "with a failing migration" do 
        let(:migration) {Exodus.instanciate_migration(Migration_test7, {})}

        it "should raise an error" do 
          lambda {Exodus.run_one_migration(migration, 'up')}.should raise_error(StandardError) 
        end

        it "should still create the migration" do 
          lambda {Exodus.run_one_migration(migration, 'up') rescue nil}.should change(Exodus::Migration, :count).by(1)
        end
      end
    end

    describe "When the migration has been ran" do 
      describe "with a valid migration" do 
        it "should not create a new migration" do 
          migration = Exodus.instanciate_migration(Migration_test6, {})
          Exodus.run_one_migration(migration, 'up')

          lambda {Exodus.run_one_migration(migration, 'up')}.should change(Exodus::Migration, :count).by(0)
        end
      end

      describe "with a failing migration" do 
        it "should not create a new migration" do 
          migration = Exodus.instanciate_migration(Migration_test7, {})
          Exodus.run_one_migration(migration, 'up') rescue nil

          lambda {Exodus.run_one_migration(migration, 'up') rescue nil}.should change(Exodus::Migration, :count).by(0)
        end
      end
    end
  end

  describe "find_existing_migration" do
    before do
      create_dynamic_class('Migration_test6')
      create_dynamic_class('Migration_test8')
    end

    before :each do
      Exodus::Migration.collection.drop
    end

    describe "When no migrations have been ran" do 
      it "should not find any migration" do 
        Exodus.find_existing_migration(Migration_test8, {}).should be_nil
      end
    end

    describe "When a different migration has been ran" do 
      it "should not find any migration" do 
        migration = Exodus.instanciate_migration(Migration_test6, {})
        Exodus.run_one_migration(migration, 'up')

        Exodus.find_existing_migration(Migration_test8, {}).should be_nil
      end
    end

    describe "When the migration has been ran" do 
      it "should find the migration" do 
        migration = Exodus.instanciate_migration(Migration_test8, {})
        Exodus.run_one_migration(migration, 'up')

        Exodus.find_existing_migration(Migration_test8, {}).class.should == Migration_test8
      end
    end

    describe "When all migrations have been ran" do 
      it "should find the migration" do 
        migration6 = Exodus.instanciate_migration(Migration_test6, {})
        migration8 = Exodus.instanciate_migration(Migration_test8, {})
        Exodus.run_one_migration(migration6, 'up')
        Exodus.run_one_migration(migration8, 'up')

        Exodus.find_existing_migration(Migration_test8, {}).class.should == Migration_test8
      end
    end
  end

  describe "run_migrations and sort_and_run_migrations" do
    before do
      create_dynamic_class('Migration_test9')
      create_dynamic_class('Migration_test10')
    end

    before :each do 
      reset_collections(UserSupport,Exodus::Migration)
    end

    let(:migrations_info) { [[Migration_test9, {}], [Migration_test10, {}]]}

    describe "running the same migration in a different order with run_migrations" do 
      it "should successfully run them in different order" do
        instanciate_and_run_up_migrations(*migrations_info) 
        get_users_names.should == ["Thomas", "Tester"]

        reset_collections(UserSupport, Exodus::Migration) 
        migrations = migrations_info.map{|migration_info| Exodus.instanciate_migration(*migration_info)}
        Exodus.run_migrations('up', migrations.reverse)
        get_users_names.should == ["Tester", "Thomas"]
      end
    end

    describe "running the same migration in a different order with sort_and_run_migrations" do 
      it "should successfully run them in the same order" do
        Exodus.sort_and_run_migrations('up', migrations_info)
        get_users_names.should == ["Thomas", "Tester"]

        reset_collections(UserSupport, Exodus::Migration) 
        Exodus.sort_and_run_migrations('up', migrations_info.reverse)
        get_users_names.should == ["Thomas", "Tester"]
      end
    end

    it "should run only one time the same migration" do
      migrations = [[Migration_test9, {}], [Migration_test9, {}]] 
      lambda {Exodus.sort_and_run_migrations('up', migrations)}.should change(Exodus::Migration, :count).by(1)
    end

    it "should run successfully only one time when specifying the step option" do
      migrations = [[Migration_test9, {}], [Migration_test10, {}]] 
      lambda {Exodus.sort_and_run_migrations('up', migrations, 1)}.should change(Exodus::Migration, :count).by(1)
    end

    describe "Getting migration information" do 
      it "should successfully print the migrations information" do
        migrations = [[Migration_test9, {}], [Migration_test10, {}]] 
        Exodus.sort_and_run_migrations('up', migrations, nil, true).should == ["Migration_test9: #{{}}", "Migration_test10: #{{}}"]
      end

      it "should successfully print the first migration information" do
        migrations = [[Migration_test9, {}], [Migration_test10, {}]] 
        Exodus.sort_and_run_migrations('up', migrations, 1, true).should == ["Migration_test9: #{{}}"]
      end
    end
  end
end