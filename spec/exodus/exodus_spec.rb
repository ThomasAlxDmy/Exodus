require "spec_helper"

describe Exodus do 
  describe "sort_migrations" do 
  	before do
      class Migration_test4 < Exodus::Migration; end
      class Migration_test3 < Exodus::Migration; end

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
      class Migration_test4 < Exodus::Migration; end
      class Migration_test3 < Exodus::Migration; end
      class Migration_test5 < Exodus::Migration; end

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

  describe "tasks" do 
  	it "should return the current path of exodus.rake" do
  		rake_file = Pathname.new(File.dirname(__FILE__) + '/../../tasks/exodus.rake')
  		Pathname.new(Exodus.tasks).realpath.to_s.should == rake_file.realpath.to_s
  	end 
  end

  describe "run_one_migration" do
    before do
      class Migration_test6 < Exodus::Migration
        def up 
          'valid'
        end
      end
      class Migration_test7 < Exodus::Migration
        def up 
          raise StandardError, "the current migration failed"
        end
      end
    end

    before :each do
      Exodus::Migration.collection.drop
    end

    describe "When the migration has not been ran" do 
      describe "with a valid migration" do 
        it "should successfully create the migration" do 
          lambda{ Exodus.run_one_migration(Migration_test6, 'up', {})}.should 
          change {Exodus::Migration}.by(1)
        end
      end

      describe "with a failing migration" do 
        it "should raise an error" do 
          lambda{ Exodus.run_one_migration(Migration_test7, 'up', {})}.should
          raise_error(StandardError) 
        end

        it "should create the migration" do 
          lambda{ Exodus.run_one_migration(Migration_test7, 'up', {})}.should
          change {Exodus::Migration}.by(1)
        end
      end
    end

    describe "When the migration has been ran" do 
      describe "with a valid migration" do 
        it "should not create a new migration" do 
          Exodus.run_one_migration(Migration_test6, 'up', {})

          lambda{ Exodus.run_one_migration(Migration_test6, 'up', {})}.should 
          change {Exodus::Migration}.by(0)
        end
      end

      describe "with a failing migration" do 
        it "should not create a new migration" do 
          Exodus.run_one_migration(Migration_test7, 'up', {}) rescue nil

          lambda{ Exodus.run_one_migration(Migration_test7, 'up', {})}.should 
          change {Exodus::Migration}.by(0)
        end
      end
    end
  end
end