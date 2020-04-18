# Using `BEE` and `BEE.jl` to solve combinatorial problems

[![Build Status](https://travis-ci.com/newptcai/BEE.jl.svg?branch=master)](https://travis-ci.com/newptcai/BEE.jl)

*This article is about my Julia interface package [`BEE.jl`](https://github.com/newptcai/BEE.jl) for
using [`BEE` (Ben-Gurion University Equi-propagation
Encoder)](http://amit.metodi.me/research/bee/) by [Amit Metodi](http://amit.metodi.me/)*

## The beauty of brute force 🤜️

Modern [SAT](https://en.wikipedia.org/wiki/Boolean_satisfiability_problem) solver are often capable
of handling problems with *HUGE* size. They have been successfully applied to many combinatorics
problems. Communications ACM has an article titled [The Science of Brute
Force](https://cacm.acm.org/magazines/2017/8/219606-the-science-of-brute-force/fulltext) on how the
[Boolean Pythagorean Triples problem](https://www.cs.utexas.edu/~marijn/publications/ptn.pdf) was
solved with an SAT solver.  Another well-known example is [Paul Erdős Discrepancy
Conjecture](https://www.quantamagazine.org/terence-taos-answer-to-the-erdos-discrepancy-problem-20151001/),
which was [initially attacked with the help of computer](https://arxiv.org/pdf/1402.2184.pdf).

<p align="center">
<img src="images/egg-power.jpg" alt="Brute force" width="450" />
</p>


Thus it is perhaps beneficial 🥦️ for anyone who is interested in combinatorics 🀄️ to learn how to
harness the beautiful brute force 🔨 of SAT solvers. Doing experiments with SAT solver can search much
bigger space than pencil and paper.  New patterns can be spotted 👁️. Conjectures can be proved or
disapproved 🎉️.

However, combinatorial problems are often difficult to encode into CNF formulas, which can only
contain boolean variables. So integers must be represented by such boolean variables with some
encoding scheme. Doing so manually can be very tedious 😑️.

Of course you can use solvers which go beyond CNF. For example Microsoft has a
[`Z3`](https://github.com/Z3Prover/z3) theorem proved. You can solve many more types of problems
with it. But if the size of your problem matters, pure CNF solver is still way much faster 🚀️.

## What is `BEE` 🐝️


One project that tries to ease using SAT solvers is [`BEE` (Ben-Gurion
University Equi-propagation Encoder)](http://amit.metodi.me/research/bee/), which

> ... is a
> compiler which enables to encode finite domain constraint problems to CNF. During compilation, `BEE`
> applies optimizations which include equi-propagation (see paper), partial-evaluation, and a careful
> selection of encoding techniques per constraint, depending on various parameters of the constraint.

From my experiments, `BEE` has a good balance of expressive power and performance.

## Many ways to use `BEE` 🤔️

`BEE` is written in `[Prolog](https://en.wikipedia.org/wiki/Prolog)`. So you either have to learn
`Prolog`, or you can
1. encode your problem in a syntax defined by `BEE`,
2. use a program `BumbleBEE` that comes with the package to solve it directly with `BEE`
3. or use `BumbleBEE` to compile your problem to a [DIMACS CNF file](https://people.sc.fsu.edu/~jburkardt/data/cnf/cnf.html), which can be solved by the numerous
   SAT solvers out there.

My choice is to use [Julia](https://julialang.org/) to convert combinatorics problems into
`BumbleBEE` code and this is why I wrote the package [`BEE.jl`](https://github.com/newptcai/BEE.jl).

Here's my workflow for smaller problems

```shell
Julia code --(BEE.jl)--> BEE code --(BumbleBEE)--> solution/unsatisfiable
```

When the problem is getting bigger, I try

```shell
Julia code --(BEE.jl)--> BEE code -- (BumbleBEE)--> CNF --(SAT Solver)
                                                                |
    +-------------------------+--------------------------------+
    |                         |
    v                         v
unsatisfiable          CNF solution --(BumbleSol)--> BEE solution
```

In the rest of this article, I will mostly describe how to use `BEE` 😀️. You do not need to know any
Julia to understand this part. I will only briefly mention what `BEE.jl` does by the
end.

## `BEE` and SAT solver for beginners

### Compiling and running `BEE`

I ran into some difficulties when I tried to compile [2017 version of
`BEE`](http://amit.metodi.me/research/bee/bee20170615.zip). Here is how to do it correctly on
Ubuntu. Other Linux system should work in similar ways.

First install `swi-prolog`. You can do this in a terminal by
```shell
sudo apt install swi-prolog
```
Download `BEE` using the link above and unzip it somewhere on your computer.
In a terminal, change directory to
```shell
cd /path-to-downloaded-file/bee20170615/satsolver_src
```
Compile sat solvers coming with `BEE` by
```shell
env CPATH="/usr/lib/swi-prolog/include/" make satSolvers
```
If compilation is successful, you should be able to excute
```shell
cd ../satsolver && ls
```
and see the following output
```shell
pl-glucose4.so  pl-glucose.so  pl-minisat.so  satsolver.pl
```
Next we compile `BumbleBEE` by
```shell
cd ../beeSolver/ && make
```
If you succeed, you will be able to find `BumbleBEE` and `BumbleSol` one directory above by
```shell
cd .. && ls
```
And you should see these files
```shell
bApplications  beeSolver  BumbleSol        pl-satsolver.so  satsolver
beeCompiler    BumbleBEE  Constraints.pdf  README.txt       satsolver_src
```
### Using `BumbleBEE`

We can now give `BEE` a try 😁️.  You can find examples of `BumbleBEE` problems in the folder
`beeSolver/bExamples`. A very simple one is the following
`ex_sat.bee`.
```shell
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
```shell
./BumbleBEE beeSolver/bExamples/ex_sat.bee
```
And the solution should be
```shell
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

<font size="+2">⚠️ </font> But here is a caveat -- you must run `BumbleBEE` with the current
directory `PWD` set to be where the file
`BumbleBEE` is. You cannot use any other directory 🤦. For example if you try
```shell
cd .. && bee20170615/BumbleBEE bee20170615/beeSolver/bExamples/ex_sat.bee
```
You will only get error messages.

### Convert the problem to CNF

As I mentioned earlier, you can also compile your problem into CNF DIMACS format. For example
```shell
/BumbleBEE beeSolver/bExamples/ex_sat.bee -dimacs ./ex_sat.cnf ./ex_sat.map
```
will create two files `ex_sat.cnf` and `ex_sat.map`. The top few lines of
`ex_sat.cnf` looks like this
```shell
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

1. A line with `c` at the beginning is a comment.
2. The line with `p`  says that this is a CNF formula with `37` variables and `189` clauses.
3. `1 0` is a clause which says that variable `1` must be true. `0` is symbol to end a
  clause.
4. `-6 5` means either the negate of variable `6`  is true or variable `5` is true ...

As you can see, with integers are needed, even a toy problem needs a large numbers of
boolean variables. This is why efficient coding of integers are critical. And this is where `BEE`
helps.

Now you can try your favourite SAT solver on the problem. I often use
[`CryptoMiniSat`](https://www.msoos.org/cryptominisat5/). Assuming that you have it on your `PATH`, you
can now use
```shell
cryptominisat5 ex_sat.cnf > ex_sat.sol
```
to solve the problem and save the solution into a file `ex_sat.sol`. Most of `ex_sat.sol` are
comments except the last 3 lines
```shell
s SATISFIABLE
v 1 -2 -3 -4 -5 -6 -7 -8 -9 -10 -11 -12 -13 -14 -15 -16 -17 -18 -19 -20 -21 -22
v -23 -24 -25 -26 -27 -28 -29 -30 -31 -32 -33 34 -35 -36 -37 0
```
It says the problem is satisfiable and one solution is given. A number in the line starting with an `v`
means a variables. Without a `-` sign in front of it, a variable is assigned the value `true`
otherwise it is assigned `false`.

<font size="+2">⚠️ </font> To get back to a solution to `BEE` variables, we use `BumbleSol`, which is
at the same folder as `BumbleBEE`. But `BumbleSol` needs bit help 😑️. Remove the starting `s` and `v`
in the `ex_sat.sol` to make it like this
```shell
SATISFIABLE
1 -2 -3 -4 -5 -6 -7 -8 -9 -10 -11 -12 -13 -14 -15 -16 -17 -18 -19 -20 -21 -22
-23 -24 -25 -26 -27 -28 -29 -30 -31 -32 -33 34 -35 -36 -37 0
```
Then we can run
```shell
./BumbleSol ex_sat.map ex_sat.sol
```
and get
```shell
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

That's it! Now you know how to use `BEE` 🐝️! Have fan with your problem 🤣️.

### Choice of SAT solver

Some top-level SAT solvers are

* [CaDical](https://github.com/arminbiere/cadical) -- Winner of [2019 SAT
  Race](http://sat-race-2019.ciirc.cvut.cz/). Tends to be
  fastest in dealing with solvable problems.
* [Lingeling, Plingeling and Treengeling](http://fmv.jku.at/lingeling/) -- Good at parallelization.
* [Painless](https://www.lrde.epita.fr/wiki/Painless) -- Uses a divide and conquer strategy for
  parallelization.
* MapleLCMDiscChronoBT-DL --  Winner of 2019 SAT Race for unsatisfiable problem. But I have not
  found any documents of it.

My experience is that all these SAT solvers have similar performance. It is always more important to
try to encode your problem better.

## How to use `BEE.jl`

When your problems becomes bigger, you don't want to write all BEE code manually. Here's what
`BEE.jl` may help. You can write your problem in Julia, and `BEE.jl` will convert it to `BEE` syntax.
Here's how to do the example above with `BEE.jl`

First install `BEE.jl` by typing this in `Julia REPL`.
```Julia
using Pkg; Pkg.add("git@github.com:newptcai/BEE.jl.git")
```
Then run the following code
```Julia
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

print(BEE.render())
```
You will get output like this
```Julia
new_int(w, 0, 10)
new_int(x, 0, 5)
new_int(z, -5, 10)
new_int(y, -4, 9)
new_bool(x1)
new_bool(x4)
new_bool(x2)
new_bool(x3)
int_plus(x, y, z)
bool_eq(x1, -x2)
bool_eq(x2, true)
bool_array_sum_eq(([-x1, x2, -x3, x4], w))
```
Exactly as above.

## Acknowledgement 🙏️

I want to thank all the generous ❤️  people who have spend their time to create these amazing SAT
solvers and made them freely available to everyone.

By writing this module, I have learn quite a great deal of Julia and its convenient meta-programming
features.  I want to thank everyone 💁 on GitHub and [Julia Slack channel](https://slackinvite.julialang.org/) who has helped me, in
particular Alex Arslan, [David Sanders](https://github.com/dpsanders), Syx Pek, and [Jeffrey
Sarnoff](https://github.com/JeffreySarnoff).

