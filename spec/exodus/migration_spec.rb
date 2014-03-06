require "spec_helper"

describe Exodus::Migration do

  before :all do 
    create_dynamic_class('Migration_test1')
  end


  describe "New Oject" do
    subject { Exodus::Migration.new }

    it "should have a status" do
      subject.status.should_not be_nil
    end

    it "should have default value for [status_complete, rerunnable_safe]" do
      subject.status_complete.should == 1
      (subject.class.rerunnable_safe?).should be_false
    end
  end

  describe "class methods" do
    subject { Exodus::Migration.new }

    describe "#inherited" do
      it "should add a new migrations when a new migration class is created" do
        migration_size = subject.class.load_all([]).size.to_i
        create_dynamic_class('Migration_test2')
        
        subject.class.load_all([]).size.should == migration_size + 1
      end
    end

    describe "#load_all" do
      before :all do 
        create_dynamic_class('CompleteNewMigration')
      end

      it "should override migrations" do
        first_migration = subject.class.load_all([]).first.first 
        override_migration = [first_migration, {:test_args => ['some', 'test', 'arguments']}]
        subject.class.load_all([override_migration]).should include override_migration
      end

      it "should add a new migrations if the migration is not present" do
        migration_classes = subject.class.load_all([]).map{|migration, args| migration}
        reloaded_migration_classes = subject.class.load_all([[CompleteNewMigration.name]]).map{|migration, args| migration} 

        reloaded_migration_classes.should include CompleteNewMigration 
      end
    end
  end

  describe "instance methods" do
    before do
      create_dynamic_class('Migration_test1')
      create_dynamic_class('RerunnableMigrationTest')
    end

    subject { Migration_test1.first_or_create({}) }

    describe "#run" do
      before :each do 
        reset_collections(Migration_test1, UserSupport)
      end

      it "should create a new APIUser when running it up" do
        lambda{ subject.run('up')}.should change { UserSupport.count }.by(1)
        migration_should_be_up(subject)
        subject.status.message.should == 'Creating new APIUser entity'
      end

      it "should delete an APIUser when running it down" do
        subject.run('up')

        lambda{ subject.run('down')}.should change { UserSupport.count }.by(-1)
        migration_should_be_down(subject)
        subject.status.message.should == 'Droping APIUser entity'
      end

      it "should run and rerun when the migration is rerunnable safe" do
        migration = RerunnableMigrationTest.first_or_create({})

        lambda{ migration.run('up')}.should change { UserSupport.count }.by(1)
        migration_should_be_up(migration)
        migration.status.message.should == 'Creating new APIUser entity'

        UserSupport.first.destroy
        UserSupport.count.should == 0
        lambda{ migration.run('up')}.should change { UserSupport.count }.by(1)
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
      before :all do
        reset_collections(Migration_test1, UserSupport)
      end

      it "should execute a block and set the execution_time" do
        lambda do 
          time = subject.send(:time_it) {UserSupport.create(:name => 'testor')}
        end.should change { UserSupport.count }.by(1)
      end
    end

    describe "#completed?" do
      before :all do
        reset_collections(Migration_test1, UserSupport)
      end

      it "should be false when the job is not completed" do
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
      before :all do
        reset_collections(Migration_test1, UserSupport)
      end

      it "should only be runable up when it has never run before" do
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
        subject.class.rerunnable_safe = true

        subject.is_runnable?('up').should be_true 
        subject.is_runnable?('down').should be_true
      end
    end
  end
end