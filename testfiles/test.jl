function standard(x)
  print(x)
end

function default(a,b="test")
  print(b)
end

function keyword(a,b="test";c)
  print(c)
end

function default_kw(a,b="test";c="keyword")
  print(c)
end

function nested1(x)
  function nested2(x)
    print(x)
  end
  return nested2(x)
end

function dispatch(x::Int,y::Any)
  println(typeof(x))
  println(typeof(y.x))
  return x
end

function typed_output(x::Int,y::Float64)::Int
  println(typeof(x))
  println(typeof(y))
  return x
end

function parametric(x::T) where {T<:Real}
  print(x)
end

inline(x) = print(x)

struct StructConstructor
   x::Real
   y::Real
   StructConstructor(x,y) = x > y ? error("out of order") : new(x,y)
end

x = my_call()

# Overload operator
# import Base.+
(+)(x::Int,y::Float64) = x*y
Base.:+(x::Int,y::Float64) = x*y

# Anonymous functions
x -> 3*x
(x::Int) -> 3*x
z = (x,y) -> 3*x*y
# Can be defined anywhere
map(x->x*2 + 1, [1,2,3])
# Equivalent to do-block
map([1,2,3]) do x, y
  x*2 + 1
end

map([1,2,3]) do x::Int
  x*2 + 1
end

slurp(x...) = print(x)

function standard(x)
  print(x)
  x += 11
  x /= 11
  x *= 11
  x -= 11
end

