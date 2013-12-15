require "spec_helper"

describe Exodus::MigrationStatus do

  let(:migration) { Exodus::Migration.new }
  subject {migration.status }

  describe "New Oject" do
    it "should have a status" do
      subject.should_not be_nil
    end
  end

  describe "#reset!" do
    it "should reset the current status" do
      time = Time.now

      subject.message = "test"
      subject.current_status = 1
      subject.execution_time = 2
      subject.last_succesful_completion = time

      subject.message.should == "test"
      subject.current_status.should ==  1
      subject.execution_time.should == 2
      subject.last_succesful_completion.to_i.should == time.to_i

      subject.reset!

      subject.message.should == nil
      subject.current_status.should == 0
      subject.execution_time.should == 0
      subject.last_succesful_completion.should == nil
    end
  end
end