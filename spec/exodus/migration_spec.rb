require "spec_helper"
require File.dirname(__FILE__) + "/../../lib/exodus"

describe Exodus::Migration do

  describe "New Oject" do
    subject { Exodus::Migration.new }

    it "should have a status" do
      subject.status.should_not be_nil
    end

    it "should have default value for [status_complete, rerunnable_safe]" do
      subject.status_complete.should == 1
      subject.rerunnable_safe.should be_false
    end
  end

  describe "class methods" do
    subject { Exodus::Migration.new }

    describe "#inherited" do
      it "should add a new migrations when a new migration class is created" do
        migration_size = subject.class.load_all([]).size.to_i
        class Migration_test1 < Exodus::Migration; end

        subject.class.load_all([]).size.should == migration_size + 1
      end
    end

    describe "#load_all" do
      it "should override migrations" do
        first_migration = subject.class.load_all([]).first.first 
        subject.class.load_all([[first_migration, {:test_args => ['some', 'test', 'arguments']}]]).should include [first_migration, {:test_args => ['some', 'test', 'arguments']}] 
      end

      it "should add a new migrations if the migration is not present" do
        migration_classes = subject.class.load_all([]).map{|migration, args| migration}
        class CompleteNewMigration < Exodus::Migration; end
        
        reloaded_migration_classes = subject.class.load_all([[CompleteNewMigration.name]]).map{|migration, args| migration} 
        reloaded_migration_classes.should include CompleteNewMigration 
      end
    end
  end

  describe "instance methods" do
    before do
      class Migration_test1 < Exodus::Migration
        def up 
          step("Creating new APIUser entity", 1) {UserSupport.create(:name =>'testor')}
        end

        def down 
          step("Droping APIUser entity", 0) do 
            user = UserSupport.first
            user.destroy if user
          end
        end
      end
    end

    subject { Migration_test1.first_or_create({}) }

    describe "#run" do
      it "should create a new APIUser when running it up" do
        Migration_test1.collection.drop
        UserSupport.collection.drop

        lambda{ subject.run('up')}.should change { UserSupport.count }.by(1)
        subject.status.arguments.should be_empty
        subject.status.current_status.should == 1
        subject.status.direction.should == 'up'
        subject.status.execution_time.should > 0
        subject.status.last_succesful_completion.should
        subject.status.message.should == 'Creating new APIUser entity'
      end

      it "should delete an APIUser when running it down" do
        Migration_test1.collection.drop
        UserSupport.collection.drop
        subject.run('up')

        lambda{ subject.run('down')}.should change { UserSupport.count }.by(-1)
        subject.status.arguments.should be_empty
        subject.status.current_status.should == 0
        subject.status.direction.should == 'down'
        subject.status.execution_time.should > 0
        subject.status.message.should == 'Droping APIUser entity'
      end
    end

    describe "#failure=" do
      it "should save error information" do
        exception = nil

        begin
          raise StandardError "This is an error"
        rescue Exception  => e
          subject.failure = e
          exception = e
        end

        subject.status.error.error_message.should == exception.message
        subject.status.error.error_class.should == exception.class.name
        subject.status.error.error_backtrace.should == exception.backtrace
      end
    end

    describe "#time_it" do
      it "should execute a block and set the execution_time" do
        Migration_test1.collection.drop
        UserSupport.collection.drop

        lambda do 
          time = subject.send(:time_it) {UserSupport.create(:name => 'testor')}
        end.should change { UserSupport.count }.by(1)
      end
    end

    describe "#completed?" do
      it "should be false when the job is not completed" do
        Migration_test1.collection.drop
        UserSupport.collection.drop

        subject.completed?('up').should be_false
        subject.completed?('down').should be_false
      end

      it "should be completed up when the job has ran up" do
        subject.run('up')

        subject.completed?('up').should be_true
        subject.completed?('down').should be_false
      end

      it "should be completed down when the job has ran down" do
        subject.run('down')

        subject.completed?('up').should be_false
        subject.completed?('down').should be_true
      end
    end

    describe "#is_runnable?" do
      it "should only be runable up when it has never run before" do
        Migration_test1.collection.drop
        UserSupport.collection.drop

        subject.is_runnable?('up').should be_true
        subject.is_runnable?('down').should be_false
      end

      it "should not be runable up when it has ran up before" do
        subject.run('up')

        subject.is_runnable?('up').should be_false
        subject.is_runnable?('down').should be_true
      end

      it "should not be runable down when it has ran down before" do
        subject.run('down')

        subject.is_runnable?('up').should be_true 
        subject.is_runnable?('down').should be_false
      end

      it "should be runable when if the task is safe" do
        subject.rerunnable_safe = true

        subject.is_runnable?('up').should be_true 
        subject.is_runnable?('down').should be_true
      end
    end
  end

  describe "MigrationFramework" do 
    describe "sort_migrations" do 
      it "should return the migrations sorted by migration number" do 
        CompleteNewMigration.migration_number = 10
        sorted_migrations = Exodus::sort_migrations(Exodus::Migration.load_all([]))
        migrations_number = sorted_migrations.map {|migration, args| migration.migration_number }
        migrations_number.should == migrations_number.sort          
      end
    end
  end
end