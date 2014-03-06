module Exodus::Testing
  @Migration_test1 = <<CLASS_DEFINITION 
    def up 
      step("Creating new APIUser entity", 1) {UserSupport.create(:name =>'testor')}
    end 

    def down 
      step("Droping APIUser entity", 0) do 
        user = UserSupport.first
        user.destroy if user
      end
    end
CLASS_DEFINITION

  @RerunnableMigrationTest = <<CLASS_DEFINITION
      self.rerunnable_safe = true

      def initialize(args = {})
        super(args)
      end

      def up 
        step("Creating new APIUser entity", 1) {UserSupport.first_or_create(:name =>'testor')}
      end

      def down 
        step("Droping APIUser entity", 0) do 
          user = UserSupport.first
          user.destroy if user
        end
      end
CLASS_DEFINITION

  @Migration_test3 = "@migration_number = 3"
  @Migration_test4 = "@migration_number = 4"
  @Migration_test5 = "@migration_number = 5"

  @Migration_test6 = <<CLASS_DEFINITION
        def up 
          'valid'
        end
CLASS_DEFINITION

  @Migration_test7 = <<CLASS_DEFINITION
        def up 
          raise StandardError, "the current migration failed"
        end
CLASS_DEFINITION

  @Migration_test8 = @Migration_test6

  @Migration_test9 = <<CLASS_DEFINITION
        @migration_number = 9
        def up 
          UserSupport.create!({:name => "Thomas"})
        end
CLASS_DEFINITION

  @Migration_test10 = <<CLASS_DEFINITION
        @migration_number = 10
        def up 
          UserSupport.create!({:name => "Tester"})
        end
CLASS_DEFINITION

  CLASS_CONTENT = instance_variables.each_with_object({}) {|v, hash| hash[v] = instance_variable_get(v)}
end