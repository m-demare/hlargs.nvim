class Class:
  def __init__(self, arg1, arg2):
    self.arg1 = arg1
    self.arg2 = arg2
    def function2(arg3): # inner function
        return arg2

var = 10
def fn(arg4):
    global var
    Class(arg4, lambda x: x+arg4+var)

