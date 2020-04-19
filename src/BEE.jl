module BEE

import Base: -, +, *, /, mod, max, min, ==, <, <=, !=, >, >=, sum, show, convert

export BeeInt, BeeBool, BeeModel, 
    @beeint, @beebool, beeint, beebool, render, reset, and, or, iff, alldiff

# -------------------------------------------------------------
# abstract types
# -------------------------------------------------------------

"An object that can be rendered to BEE syntax"
abstract type BeeObject end
"A symbol in BEE sytanx. Can be either a variable or a value."
abstract type BeeSymbol <: BeeObject end
abstract type BeeBoolean <: BeeSymbol end
abstract type BeeInteger <: BeeSymbol end

BB = Union{BeeBoolean, Bool}
ZZ = Union{BeeInteger, Int}

# -------------------------------------------------------------
# BEE integer variable
# -------------------------------------------------------------

"An integer variable in BEE syntax"
struct BeeInt <: BeeInteger
    name::String
    lo::Int
    hi::Int
    function BeeInt(model, name, lo, hi)
        if lo > hi
            error("$lo > $hi")
        end
        if hasvar(model, name)
            error("Variable $name has already been defined in $model")
        end
        var = new(name, lo, hi)
        model.intdict[name] = var
    end
end

BeeInt(name::String, lo::Int, hi::Int) = BeeInt(gblmodel, name, lo, hi)

macro beeint(name, lo, hi) 
    return quote
        $(esc(name)) = BeeInt($(String(name)), $lo, $hi)
    end
end
beeint(name, lo, hi) = BeeInt(name, lo, hi)

render(io::IO, var::BeeInt) = print(io, "new_int($var, $(var.lo), $(var.hi))\n")

# -------------------------------------------------------------
# BEE boolean variable
# -------------------------------------------------------------

"A boolean variable in BEE syntax"
struct BeeBool <: BeeBoolean
    name::String
    function BeeBool(model, name)
        if hasvar(model, name)
            error("Variable $name has already been defined in $model")
        end
        var = new(name)
        model.booldict[name] = var
    end
end

BeeBool(name::String) = BeeBool(gblmodel, name)

macro beebool(name)
    return quote
        $(esc(name)) = BeeBool($(String(name)))
    end
end
beebool(name) = BeeBool(name)


render(io::IO, var::BeeBool) = print(io, "new_bool($var)\n")

"The negate of a boolean variable in BEE syntax"
struct BeeNegateBool <:BeeBoolean
    boolvar::BeeBool
end

show(io::IO, v::BeeNegateBool) = print(io, "-", v.boolvar)


(-)(var::BeeBool) = BeeNegateBool(var)
(-)(var::BeeNegateBool) = var.boolvar

# -------------------------------------------------------------
# BEE literals
# -------------------------------------------------------------

"An integer value like `1`"
struct BeeIntLiteral <: BeeInteger
    val::Int
end
show(io::IO, v::BeeIntLiteral) = print(io, v.val)
convert(::Type{BeeInteger}, v::Int) = BeeIntLiteral(v)
convert(::Type{BeeSymbol}, v::Int) = BeeIntLiteral(v)

"A boolean value, i.e., `true` or `false`"
struct BeeBoolLiteral <: BeeBoolean
    val::Bool
end
show(io::IO, v::BeeBoolLiteral) = print(io, v.val)
convert(::Type{BeeBoolean}, v::Bool) = BeeBoolLiteral(v)
convert(::Type{BeeSymbol}, v::Bool) = BeeBoolLiteral(v)

"""
    render(obj::BeeObject)

Render `obj` to BEE syntax and print it to `stdout`.
"""
render(obj::BeeObject) = render(Base.stdout, obj)

show(io::IO, v::BeeSymbol) = print(io, v.name)

function show(io::IO, arr::Array{T, 1}) where T <: BeeObject
    print(io, "[", join(arr, ", "), "]")
end

# -------------------------------------------------------------
# BEE expressions
# -------------------------------------------------------------

"""
An expression can be made part of a `BeeObject`, but they themselves cannot be rendered.
"""
abstract type BeeExpression end

function show(io::IO, 
                   tuple::NTuple{N, T} where {N, T <: BeeSymbol})
    print(io, join(tuple, ", "))
end

# -------------------------------------------------------------
# BEE Constrains
# -------------------------------------------------------------

struct BeeConstraint <: BeeObject
    name::String
    # Don't check the type of the array
    varlist::Array{T, 1} where T
    function BeeConstraint(model::BeeObject, name, var)
        constraint = new(name, var)
        push!(model.conslist, constraint)
        constraint
    end
end
BeeConstraint(name::String, var...) = BeeConstraint(gblmodel, name, var...)

# For constraints, there's is no difference between how they are rendered an printed
render(io::IO, constraint::BeeConstraint) = print(io, constraint, "\n")

function show(io::IO, constraint::BeeConstraint) 
    varstr = join(constraint.varlist, ", ")
    print(io, constraint.name, "(", varstr, ")")
end


# -------------------------------------------------------------
# BEE model
# -------------------------------------------------------------
struct BeeModel <: BeeObject
    name::String
    intdict::Dict{String, BeeInt}
    booldict::Dict{String, BeeBool}
    conslist::Array{BeeConstraint, 1}
end
BeeModel(name::String) = BeeModel(name, Dict{String, BeeInt}(), Dict{String, BeeBool}(), Array{BeeConstraint,1}())

show(io::IO, m::BeeModel) = print(io, "BEE model [$(m.name)]")
show(io::IO, ::MIME"text/plain", m::BeeModel) = print(io, 
"""BEE model [$(m.name)]:
* Integer variables: $(collect(values(m.intdict)))
* Boolean variables: $(collect(values(m.booldict)))
* Constraint: $(m.conslist)""")

hasvar(model::BeeModel, name::String) = haskey(model.intdict, name) || haskey(model.booldict, name)

"""
    render()

Render the global model `gblmodel` to BEE syntax and print it to `stdout`.
"""
render() = render(gblmodel)

function render(io::IO, model::BeeModel)
    for intv in values(model.intdict)
        render(io, intv)
    end
    for boolv in values(model.booldict)
        render(io, boolv)
    end
    for cons in model.conslist
        render(cons)
    end
end

"Delete all variables and constraints from the default model."
function reset()
    global gblmodel = BeeModel("defaul model")
end

# -------------------------------------------------------------
# BEE operator for both integer and boolean
# -------------------------------------------------------------

# Create BEE summation expression, which applies to list of symbols
struct BeeSum{T <: BeeSymbol} <: BeeExpression
    varlist::Array{BeeSymbol, 1}
end

sum(varlist::Array{T, 1})  where T <: BeeBoolean = BeeSum{T}(varlist)
sum(varlist::Array{T, 1})  where T <: BeeInteger = BeeSum{T}(varlist)

# Create BEE operator on summation.
for (VT, VF) in [(:BeeBoolean, :bool), (:BeeInteger, :int)],
    (OP, EF) in [(:(<=), :leq), (:(>=), :geq), (:(==), :eq), (:(<), :lt), (:(>), :gt), (:(!=), :neq)]
    @eval BEE begin
        # Some of these are not symmetirc. Let's don't switch order
        # $OP(lhs::ZZ, rhs::BeeSum{T} where T <: $VT)  = $OP(rhs, lhs)
        $OP(lhs::BeeSum{T} where T <: $VT, rhs::ZZ) = $(Symbol(VF, :_array_sum_, EF))(lhs.varlist, rhs)
    end
end

# -------------------------------------------------------------
# BEE operator for integers
# -------------------------------------------------------------

# Boolean operator on two integers
intBOP = [(:BeeLeq, :leq, :(<=)), (:BeeGeq, :geq, :(>=)), (:BeeEq, :eq, :(==)), 
          (:BeeLt, :lt, :(<)), (:BeeGt, :gt, :(>)), (:BeeNeq, :neq, :(!=))]
# Arithmetic operator on two integers
intAOP = [(:BeePlus, :plus, :+), (:BeeTimes, :times, :*), (:BeeMax, :max, :max), 
          (:BeeMin, :min, :min), (:BeeDiv, :div, :/), (:BeeMod, :mod, :mod)]

# Define function for integer $OP integer. Avoid matching `Int` $OP `Int`
for (ET, EF, OP) in [intBOP; intAOP]
    @eval BEE begin
    $OP(lhs::Int, rhs::BeeInteger) = $ET(BeeIntLiteral(lhs), rhs)
    $OP(lhs::BeeInteger, rhs::Int) = $ET(lhs, BeeIntLiteral(rhs))
    $OP(lhs::BeeInteger, rhs::BeeInteger) = $ET(lhs, rhs)
    end
end

# Create BEE boolean expression for two integers, which applies to two `BeeInteger`.
for (ET, EF, OP) in intBOP
    @eval BEE begin
    struct $ET <: BeeExpression
        lhs::BeeInteger
        rhs::BeeInteger
    end

    # `lhs` is true `iff` rhs is true
    (==)(lhs::BeeBoolean, rhs::$ET) = rhs == lhs
    function (==)(lhs::$ET, rhs::BeeBoolean)
        $(Symbol(:int_, EF, :_reif))(lhs.lhs, lhs.rhs, rhs)
    end

    # `lhs` is true `iff` rhs is true
    (==)(lhs::Bool, rhs::$ET) = rhs == lhs
    function (==)(lhs::$ET, rhs::Bool)
        if rhs
            $(Symbol(:int_, EF))(lhs.lhs, lhs.rhs)
        else
            $(Symbol(:int_, EF, :_reif))(lhs.lhs, lhs.rhs, rhs)
        end
    end
    end
end

# Create BEE arithmetic expression for two integers, which applies to two `BeeInteger`.
for (ET, EF, OP) in  intAOP
    @eval BEE begin
    struct $ET <: BeeExpression
        lhs::BeeInteger
        rhs::BeeInteger
    end

    # `lhs` == `rhs` is true
    (==)(lhs::BeeInteger, rhs::$ET) = rhs == lhs
    function (==)(lhs::$ET, rhs::BeeInteger)
        $(Symbol(:int_, EF))(lhs.lhs, lhs.rhs, rhs)
    end
    end
end

# Create BEE allDiff operations on one integer array
intarrayOP = [(:BeeArrayAllDiff, :allDiff, :alldiff, :_reif)]
for (ET, EF, OP, TAIL) in intarrayOP
    @eval BEE begin
    struct $ET <: BeeExpression
        varlist::Array{BeeInteger, 1}
    end

    # No need to check type here
    $OP(varlist::Array{T, 1} where T <: ZZ) = $ET(varlist)

    (==)(lhs::BeeInteger, rhs::$ET) = rhs == lhs
    function (==)(lhs::$ET, rhs::BeeInteger)
        $(Symbol(:int_array_, EF, TAIL))(lhs.varlist, rhs)
    end

    (==)(lhs::Bool, rhs::$ET) = rhs == lhs
    function (==)(lhs::$ET, rhs::Bool)
        if rhs
            $(Symbol(:int_array_, EF))(lhs.varlist)
        else
            $(Symbol(:int_array_, EF, TAIL))(lhs.varlist, rhs)
        end
    end
    end
end

# Create BEE operations on one integer array
intarrayOP = [(:BeeArrayPlus, :plus, :plus),
              (:BeeArrayTimes, :times, :times), 
              (:BeeArrayMax, :max, :max), 
              (:BeeArrayMin, :min, :min)]
for (ET, EF, OP) in intarrayOP
    @eval BEE begin
    struct $ET <: BeeExpression
        varlist::Array{BeeInteger, 1}
    end

    # No need to check type here
    $OP(varlist::Array{T, 1} where T <: ZZ) = $ET(varlist)

    (==)(lhs::BeeInteger, rhs::$ET) = rhs == lhs
    function (==)(lhs::$ET, rhs::BeeInteger)
        $(Symbol(:int_array_, EF))(lhs.varlist, rhs)
    end
    end
end

# -------------------------------------------------------------
# BEE operator for boolean
# -------------------------------------------------------------

# hard code this bit since it's just one function
(==)(lhs::Bool, rhs::BeeBoolean) = bool_eq(lhs, rhs)
(==)(lhs::BeeBoolean, rhs::Bool) = bool_eq(lhs, rhs)
(==)(lhs::BeeBoolean, rhs::BeeBoolean) = bool_eq(lhs, rhs)

# Logic Expressions on two boolean.
boolOP = [(:BeeAnd, :and, :and), (:BeeOr, :or, :or), (:BeeXor, :xor, :xor), (:BeeIff, :iff, :iff)]
for (ET, EF, OP) in boolOP
    @eval BEE begin
    struct $ET <: BeeExpression
        lhs::BeeSymbol
        rhs::BeeSymbol
    end

    # No need to check type here
    $OP(lhs, rhs) = $ET(lhs, rhs)

    (==)(lhs::BeeBoolean, rhs::$ET) = rhs == lhs
    function (==)(lhs::$ET, rhs::BeeBoolean)
        $(Symbol(:bool_, EF, :_reif))(lhs.lhs, lhs.rhs, rhs)
    end

    (==)(lhs::Bool, rhs::$ET) = rhs == lhs
    function (==)(lhs::$ET, rhs::Bool)
        if rhs
            $(Symbol(:bool_, EF))(lhs.lhs, lhs.rhs)
        else
            $(Symbol(:bool_, EF, :_reif))(lhs.lhs, lhs.rhs, rhs)
        end
    end
    end
end

# Create BEE operators on boolean arrays. Note that 
boolarrayOP = [(:BeeArrayAnd, :and, :and), (:BeeArrayOr, :or, :or), (:BeeArrayXor, :xor, :xor), (:BeeArrayIff, :iff, :iff)]
for (ET, EF, OP) in boolarrayOP
    @eval BEE begin
    struct $ET <: BeeExpression
        varlist::Array{BeeBoolean, 1}
    end

    # No need to check type here
    $OP(varlist) = $ET(varlist)

    (==)(lhs::BeeBoolean, rhs::$ET) = rhs == lhs
    function (==)(lhs::$ET, rhs::BeeBoolean)
        $(Symbol(:bool_array_, EF, :_reif))(lhs.varlist, rhs)
    end

    (==)(lhs::Bool, rhs::$ET) = rhs == lhs
    function (==)(lhs::$ET, rhs::Bool)
        if rhs
            $(Symbol(:bool_array_, EF))(lhs.varlist)
        else
            $(Symbol(:bool_array_, EF, :_reif))(lhs.varlist, rhs)
        end
    end
    end
end

# Create BEE operators on two boolean arrays
bool2arrayOP = [(:BeeArrayEq, :eq, :(==)), (:BeeArrayNeq, :neq, :(!=)), 
                     (:BeeLex, :lex, :(<=)), (:BeelexLt, :lexLt, :(<))]
for (ET, EF, OP) in bool2arrayOP
    @eval BEE begin
    struct $ET <: BeeExpression
        lhs::Array{BeeBoolean, 1}
        rhs::Array{BeeBoolean, 1}
    end

    $OP(lhs::Array{T, 1} where T <: BB, rhs::Array{T, 1} where T <: BB) = $ET(lhs, rhs)

    (==)(lhs::BeeBoolean, rhs::$ET) = rhs == lhs
    function (==)(lhs::$ET, rhs::BeeBoolean)
        $(Symbol(:bool_arrays_, EF, :_reif))(lhs.lhs, lhs.rhs, rhs)
    end

    (==)(lhs::Bool, rhs::$ET) = rhs == lhs
    function (==)(lhs::$ET, rhs::Bool)
        if rhs
            $(Symbol(:bool_arrays_, EF))(lhs.lhs, lhs.rhs)
        else
            $(Symbol(:bool_arrays_, EF, :_reif))(lhs.lhs, lhs.rhs, rhs)
        end
    end
    end
end


# -------------------------------------------------------------
# BEE functions
# -------------------------------------------------------------

# Adding constraint function. Do not do any check. Let BEE to report errors.
for F in (:int_order2bool_array,
          :bool2int,
          :bool_eq,
          :bool_array_eq_reif,
          :bool_array_or, :bool_array_and, :bool_array_xor, :bool_array_iff,
          :bool_array_or_reif, :bool_array_and_reif, :bool_array_xor_reif, :bool_array_iff_reif,
          :bool_or_reif, :bool_and_reif, :bool_xor_reif, :bool_iff_reif,
          :bool_ite,
          :bool_ite_reif,
          :int_leq, :int_geq, :int_eq, :int_lt, :int_gt, :int_neq,
          :int_leq_reif, :int_geq_reif, :int_eq_reif, :int_lt_reif, :int_gt_reif, :int_neq_reif,
          :int_array_allDiff,
          :int_array_allDiff_reif,
          :int_array_allDiffCond,
          :int_abs,
          :int_plus, :int_times, :int_div, :int_mod, :int_max, :int_min,
          :int_array_plus, :int_array_times, :int_array_max, :int_array_min,
          :bool_array_sum_leq, :bool_array_sum_geq, :bool_array_sum_eq, :bool_array_sum_lt, :bool_array_sum_gt,
          :bool_array_pb_leq, :bool_array_pb_geq, :bool_array_pb_eq, :bool_array_pb_lt, :bool_array_pb_gt,
          :int_array_sum_leq, :int_array_sum_geq, :int_array_sum_eq, :int_array_sum_lt, :int_array_sum_gt,
          :int_array_lin_leq, :int_array_lin_geq, :int_array_lin_eq, :int_array_lin_lt, :int_array_lin_gt,
          :int_array_sumCond_leq, :int_array_sumCond_geq, :int_array_sumCond_eq, :int_array_sumCond_lt, :int_array_sumCond_gt,
          :bool_array_sum_modK,
          :bool_array_sum_divK,
          :bool_array_sum_divModK,
          :int_array_sum_modK,
          :int_array_sum_divK,
          :int_array_sum_divModK,
          :bool_arrays_eq, :bool_arrays_neq,
          :bool_arrays_eq_reif, :bool_arrays_neq_reif,
          :bool_arrays_lex,
          :bool_arrays_lexLt,
          :bool_arrays_lex_reif,
          :bool_arrays_lexLt_reif,
          :int_arrays_eq, :int_arrays_neq,
          :int_arrays_eq_reif, :int_arrays_neq_reif,
          :int_arrays_lex,
          :int_arrays_lexLt,
          :int_arrays_lex_implied,
          :int_arrays_lexLt_implied,
          :int_arrays_lex_reif,
          :int_arrays_lexLt_reif)
    SF = String(F)
    @eval BEE $F(var...) = BeeConstraint($SF, [var...])
end

# -------------------------------------------------------------
# Initialize module
# -------------------------------------------------------------

reset()

end
