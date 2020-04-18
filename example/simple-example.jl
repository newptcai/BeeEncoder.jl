# A simple example to use `BEE.jl`

using BEE

x = BeeInt("x", 0, 5)
y = BeeInt("y", -4, 9)
z = BeeInt("z",-5, 10)

x + y == z

w = BeeInt("w", 0, 10)

xl = [BeeBool("x$i") for i=1:4]

xl[1] == -xl[2]
xl[2] == true

sum([-xl[1],xl[2],-xl[3],xl[4]]) == w

BEE.render()
