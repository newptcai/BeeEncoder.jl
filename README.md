# BEE

[![Build Status](https://travis-ci.com/newptcai/BEE.jl.svg?branch=master)](https://travis-ci.com/newptcai/BEE.jl)

# Using `BEE` and `BEE.jl` to solve combinatorial problems

## What is `BEE` 🐝️

Modern [SAT](https://en.wikipedia.org/wiki/Boolean_satisfiability_problem) solver are often capable
of handling problem with huge size. They have been successfully applied to investigate combinatorics
problem with finite search space.  Communications ACM has an article [The Science
of Brute Force](https://cacm.acm.org/magazines/2017/8/219606-the-science-of-brute-force/fulltext)
about how the [Boolean Pythagorean Triples
problem](https://www.cs.utexas.edu/~marijn/publications/ptn.pdf) was solved with SAT solver, and Quanta
magazine tells the
[story](https://www.quantamagazine.org/terence-taos-answer-to-the-erdos-discrepancy-problem-20151001/)
of [Paul Erdős Discrepancy Conjecture](https://arxiv.org/abs/1402.2184), in which SAT solver also played a
part.
Thus it is perhaps beneficial 🥦️ for anyone who is interested in combinatorics 🀄️ to learn how to
use SAT solvers. Doing experiments with SAT solver can help to spot patterns, make or disprove
conjectures.


However, many problems are difficult to encode into CNF formulas, which can only contain boolean
variables. So integers must be resented by such variables with some encoding scheme. Doing so
manually can be very tedious 😑️.  One project that tries to address this problem is [`BEE` (Ben-Gurion
University Equi-propagation Encoder)](http://amit.metodi.me/research/bee/)

> ... a
> compiler which enables to encode finite domain constraint problems to CNF. During compilation, `BEE`
> applies optimizations which include equi-propagation (see paper), partial-evaluation, and a careful
> selection of encoding techniques per constraint, depending on various parameters of the constraint.

From my experiments, `BEE` has a good balance of expressive power and performance. It also comes with
a solver, but you can combine with any solver that supports CNF, which means most of them. Thus you
can experiment with different solvers to see which deals with your problem.

## How I use `BEE`

`BEE` is written in `[Prolog](https://en.wikipedia.org/wiki/Prolog)`. So you either have to learn
`Prolog`, or you can 
1. write your problem in a format defined by `BEE`, 
2. use a program `BumbleBEE` that comes with the package to solve it directly with `BEE`
3. use `BumbleBEE` to compile your problem to [DIMACS CNF file](https://people.sc.fsu.edu/~jburkardt/data/cnf/cnf.html), which can be solved by the numerous
   SAT solvers out there.
My choice is the second approach (since I have learned probably way too many programming languages
now 😥️). But I use [Julia](https://julialang.org/) to facilitate generating `BumbleBEE` code. Thus
comes my Julia package [`BEE.jl`](https://github.com/newptcai/BEE.jl).

Here's my workflow for smaller problems

    Julia code --(BEE.jl)--> BEE code --(BumbleBEE)--> solution/unsatisfiable

When the problem is getting bigger, 

    Julia code --(BEE.jl)--> BEE code -- (BumbleBEE)--+ 
                                                      |
        +---------------------------------------------+
        |
        v
    DIMACS CNF --(SAT Solver)-+-> unsatisfiable
                              |
                              +-> CNF solution --(BumbleSol)--> BEE solution
                              
In rest of this article, I will mostly describe how to use `BEE` 😀️. You do not need to know any
`Julia` to understand this part. I will only briefly mention what my package `BEE.jl` does by the
end.

## `BEE` and SAT solver for beginners

### Compiling and running `BEE`

I ran into some difficulties when I tried to compile [2017 version of
`BEE`](http://amit.metodi.me/research/bee/bee20170615.zip). Here is how to do it correctly on
*`Ubuntu`*. Other `Linux` system should work in similar ways.

First install `swi-rpolog`. You can do this in a terminal by
```
sudo apt install swi-prolog
```
Download `BEE` using the link above and unzip it somewhere on your computer.
In a terminal, change directory to
```
cd /path-to-downloaded-file/bee20170615/satsolver_src
```
Compile sat solvers coming with `BEE` by
```
env CPATH="/usr/lib/swi-prolog/include/" make satSolvers
```
If compilation is successful, you should be able to excute
```
cd ../satsolver && ls
```
and see the following output
```
pl-glucose4.so  pl-glucose.so  pl-minisat.so  satsolver.pl
```
Next we compile `BumbleBEE` by
```
cd ../beeSolver/ && make
```
If you succeed, you will be able to find `BumbleBEE` and `BumbleSol` one directory above by
```
cd .. ; ls
```
And you should see these files
```
bApplications  beeSolver  BumbleSol        pl-satsolver.so  satsolver
beeCompiler    BumbleBEE  Constraints.pdf  README.txt       satsolver_src
```

### Using `BumbleBEE`

Assuming that you are still in the folder where `BumbleBEE` is, you can find examples of `BumbleBEE`
problems in the folder `beeSolver/bExamples`. A very simple example is the following `ex_sat.bee`.
```
new_int(x,0,5)
new_int(y,-4,9)
new_int(z,-5,10)
int_plus(x,y,z)
new_int(w,0,10)
new_bool(x1)
new_bool(x2)
new_bool(x3)
new_bool(x4)
bool_eq(x1,-x2)
bool_eq(x2,true)
bool_array_sum_eq([-x1,x2,-x3,x4],w)
solve satisfy
```
It defines 4 integer variables `x, y, z, w` in various range and 4 boolean variables `x1, x2, x3, x4`.
Then it adds various constraints on these variables, for example, `x+y==z` and `x1==x2`. For the
syntax, check the [document](http://amit.metodi.me/research/bee/Constraints.pdf).

### Solving problem directly

We can solve problem directly with `BumbleBEE` by
```
./BumbleBEE beeSolver/bExamples/ex_sat.bee
```
And the solution should be
```
(base) xing@MAT-WL-xinca341:bee20170615$ ./BumbleBEE beeSolver/bExamples/ex_sat.bee
%  \'''/ //      BumbleBEE       / \_/ \_/ \
% -(|||)(')     (15/06/2017)     \_/ \_/ \_/
%   ^^^        by Amit Metodi    / \_/ \_/ \
%
%  reading BEE file ... done
%  load pl-satSolver ... % SWI-Prolog interface to Glucose v4.0 ... OK
%  encoding BEE model ... done
%  solving CNF (satisfy) ...
x = 0
y = -4
z = -4
w = 3
x1 = false
x2 = true
x3 = false
x4 = false
----------
```
You can check that all the constraints are satisfied.

<font size="+2">⚠️ </font> But here is a caveat -- you must run `BumbleBEE` with the current directory set at where the file
`BumbleBEE` is. You cannot use any other directory. For example if you try
```
&& bee20170615/BumbleBEE bee20170615/beeSolver/bExamples/ex_sat.bee
```
You will only get error messages.

### Convert the problem to CNF

As I mentioned above, you can also compile your problem into CNF DIMACS format. For example
```
/BumbleBEE beeSolver/bExamples/ex_sat.bee -dimacs ./ex_sat.cnf ./ex_sat.map
```
will create two files `ex_sat.cnf` and `ex_sat.map` in the current folder. The top few lines of
`ex_sat.cnf` looks like this.
```
c DIMACS File generated by BumbleBEE
p cnf 37 189
1 0
-6 5 0
-5 4 0
-4 3 0
-3 2 0
-19 18 0
-18 17 0
-17 16 0
```
A little bit explanation for the first 4 lines

1. A with `c` at the beginning is a comment. 
2. The line with `p`  says that this is a CNF formula with `37` variables and `189` clauses. 
3. `1 0` is a clause which says that variable `1` must be true. `0` is symbol to end a
  clause.
4. `-6 5` means either the negate of variable `6`  is true or variable `5` is true ...

As you can see, with integers in the problem, even our modest toy example needs a large numbers of
boolean variables. Thus most of the time it is not really feasible to write such CNF files manually.

Now you can try your favourite SAT solver on the problem. I often choose
[`CryptoMiniSat`](https://www.msoos.org/cryptominisat5/). Assuming that you have it installed, you
can now use
```
cryptominisat5 ex_sat.cnf > ex_sa.sol
```
to solve the problem and save the solution into a file `ex_sat.sol`. Most of `ex_sat.sol` are
comments except the last 3 lines
```
s SATISFIABLE
v 1 -2 -3 -4 -5 -6 -7 -8 -9 -10 -11 -12 -13 -14 -15 -16 -17 -18 -19 -20 -21 -22 
v -23 -24 -25 -26 -27 -28 -29 -30 -31 -32 -33 34 -35 -36 -37 0
```
It says the problem is satisfiable and one solution is given. A number in the line starting with an `v` 
means a variables, without a `-` sign in front of it, it has value `true` otherwise it is `false`.

<font size="+2">⚠️ </font> To get back to a solution to `BEE` variables, we use `BumbleSol`, which is
at the same folder as `BumbleBEE`. But `BumbleSol` needs bit help. Remove the starting `s` and `v`
in the `ex_sat.sol`. So the last 3 lines should look like this
```
SATISFIABLE
1 -2 -3 -4 -5 -6 -7 -8 -9 -10 -11 -12 -13 -14 -15 -16 -17 -18 -19 -20 -21 -22 
-23 -24 -25 -26 -27 -28 -29 -30 -31 -32 -33 34 -35 -36 -37 0
```
Then we can run
```
./BumbleSol ex_sat.map ex_sat.sol
```
and get
```
%  \'''/ //  BumbleBEE Solution Reader  / \_/ \_/ \
% -(|||)(')         (04/06/2016)        \_/ \_/ \_/
%   ^^^            by Amit Metodi       / \_/ \_/ \
%
%  reading Dimacs solution file ... done
%  reading and decoding BEE map file ... 
x = 0
y = -4
z = -4
w = 2
x1 = false
x2 = true
x3 = false
x4 = false
----------
==========
```

That's it! Now you know how to use `BEE`! 🐝️

### Choice of SAT solver

Some top-level SAT solvers are

* [CaDical](https://github.com/arminbiere/cadical) -- Winner of [2019 SAT Race](http://sat-race-2019.ciirc.cvut.cz/). Tend to be
  fastest in dealing with solvable problems.
* [Lingeling, Plingeling and Treengeling](http://fmv.jku.at/lingeling/) -- Good at parallelization.
* [Painless](https://www.lrde.epita.fr/wiki/Painless) -- Uses a divide and conquer strategy for
  parallelization.
* MapleLCMDiscChronoBT-DL --  Winner of 2019 SAT Race for unsatisfiable problem. But I have not
  found any documents of it.

My experience is that all these SAT solvers have similar performance. It is always more important to
try to encode your problem better than picking an SAT solver.

## How to use `BEE.jl`

When your problems becomes bigger, you don't want to write all BEE code manually. Here's what
`BEE.jl` may help. You can code your problem in `Julia`, and `BEE.jl` will convert it to `BEE`.
Here's how to do the example above with `BEE.jl`

First install `BEE.jl` by typing this in `Julia REPL`.
```Julia
using Pkg; Pkg.add("git@github.com:newptcai/BEE.jl.git")
```
Then run the following code
```
```

## Acknowledgement

By writing this module, I have learn quite a great deal of Julia and its convenient meta-programming
features.  I want to thank everyone on GitHub and [Julia Slack channel](https://slackinvite.julialang.org/) who has helped me, in
particular Alex Arslan, [David Sanders](https://github.com/dpsanders), Syx Pek, and [Jeffrey
Sarnoff](https://github.com/JeffreySarnoff)
