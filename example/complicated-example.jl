# A very complicated example to use `BEE.jl`
#
# We will *prove* the following fact

using BEE

@beeint x  0 5
@beeint y -4 9
@beeint z -5 10

x + y == z

@beeint w 0 10

xl = [beebool("x$i") for i=1:4]

xl[1] == -xl[2]
xl[2] == true

sum([-xl[1], xl[2], -xl[3], xl[4]]) == w

BEE.render()
