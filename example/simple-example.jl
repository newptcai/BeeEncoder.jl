# A simple example to use `BEE.jl`

using BEE

@beeint x  0 5
@beeint y -4 9
@beeint z -5 10

@constrain x + y == z

@beeint w 0 10

xl = @beebool x[1:4]

@constrain xl[1] == -xl[2]
@constrain xl[2] == true

@constrain sum([-xl[1], xl[2], -xl[3], xl[4]]) == w

BEE.render()
