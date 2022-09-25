# Function
def fn(arg0, arg1='asd', arg2: 123, &blk)
    puts arg0
end
fn("Function: hlargs is great", arg2: 321)

# Method
class Example
    def initialize(arg0, arg1, &blk)
        @arg0 = arg0
        @arg1 = arg1
    end

    def output
        puts "Method: " + @arg0 + @arg1
end
Example.new("hlargs", " is great").output

# Lambda
lambda = ->(arg0, arg1="isn't that bad", arg2: false) { puts "Lambda: #{arg0} #{arg1}" }
lambda.call("hlargs", "is great")
end

# Blocks
print "Blocks: "
["hlargs", "is", "great"].each do |arg0, &blk|
    print arg0 + " "
end

# Example of destructuring
students = [
  ['A', 99],
  ['B', 77],
]
students.each do |(student, grade)|
  p student
  p grade
end

begin
  raise ArgumentError.new("Some error")
rescue ArgumentError => e
  puts e.message
end

