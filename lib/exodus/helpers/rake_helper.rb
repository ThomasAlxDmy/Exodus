module Exodus
  module RakeHelper
  	def time_it(task, &block)
		  puts "#{task} starting..."
		  start = Time.now
		  yield
		  puts "#{task} Done in (#{Time.now-start}s)!!"
		end

		def step
		  ENV['STEP']
		end
  end
end