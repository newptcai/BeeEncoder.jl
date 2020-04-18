module BEE

import Base: -, +, *, sum, max, min, ==, <, <=, !=, >, >=

export BeeInt, BeeBool, BeeModel, @beeint, @beebool, beeint, beebool, render

# Abstract types
#
abstract type BeeObject end
abstract type BeeVariable <: BeeObject end
abstract type BeeBoolean <: BeeVariable end
abstract type BeeInteger <: BeeVariable end

const Boolean = Union{Bool, BeeBoolean}
const ZZ = Union{Int, BeeInteger}
const Literal = Union{Boolean, ZZ}

abstract type BeeExpression end

# How to render in final output
render(obj::BeeObject) = render(Base.stdout, obj)

Base.show(io::IO, v::BeeVariable) = print(io, v.name)

function Base.show(io::IO, arr::Array{T, 1}) where T <: BeeObject
    print(io, "[", join(arr, ", "), "]")
end

function Base.show(io::IO, 
                   tuple::NTuple{N, Literal} where {N, T <: Literal})
    print(io, join(tuple, ", "))
end

# Arithmetic Expressions
for (ET, EF) in [(:BeeSum, :sum)]
    @eval BEE begin
    struct $ET{T <: BeeVariable} <: BeeExpression
        varlist::Array{T, 1}
    end

    $EF(varlist::Array{T,1}) where T <:BeeVariable = $ET{T}(varlist)
    end
end

for (ET, EF) in [(:BeeLeq, :leq), (:BeeGeq, :geq), (:BeeEq, :eq), (:BeeLt, :lt), (:BeeGt, :gt), (:BeeNeq, :neq)]
    @eval BEE begin
    struct $ET <: BeeExpression
        lhs::ZZ
        rhs::ZZ
    end

    $EF(lhs::ZZ, rhs::ZZ) = $ET(lhs, rhs)

    function (==)(lhs::$ET, rhs::BeeBoolean)
        $(Symbol(:int_, EF, :_reif))(lhs.lhs, lhs.rhs, rhs)
    end

    function (==)(lhs::$ET, rhs::Bool)
        if rhs
            $(Symbol(:int_, EF))(lhs.lhs, lhs.rhs)
        else
            $(Symbol(:int_, EF, :_reif))(lhs.lhs, lhs.rhs, rhs)
        end
    end
    end
end

for (ET, EF) in [(:BeePlus, :plus), (:BeeTimes, :times), (:BeeMax, :max), (:BeeMin, :min)]
    @eval BEE begin
    struct $ET <: BeeExpression
        lhs::ZZ
        rhs::ZZ
    end

    $EF(lhs::Int, rhs::BeeInteger) = $ET(lhs, rhs)
    $EF(lhs::BeeInteger, rhs::Int) = $ET(lhs, rhs)
    $EF(lhs::BeeInteger, rhs::BeeInteger) = $ET(lhs, rhs)

    function (==)(lhs::$ET, rhs::ZZ)
        $(Symbol(:int_, EF))(lhs.lhs, lhs.rhs, rhs)
    end
    end
end

# Logic Expressions
for (ET, EF) in [(:BeeAnd, :and), (:BeeOr, :or), (:BeeXor, :xor)]
    @eval BEE begin
    struct $ET <: BeeExpression
        varlist::Array{T, 1} where T <: Boolean
    end

    $EF(varlist::Array{T, 1} where T <: Boolean) = $ET(varlist)

    function (==)(lhs::$ET, rhs::BeeBoolean)
        $(Symbol(:bool_array_, EF, :_reif))(lhs.varlist, rhs)
    end

    function (==)(lhs::$ET, rhs::Bool)
        if rhs
            $(Symbol(:bool_array_, EF))(lhs.varlist)
        else
            $(Symbol(:bool_array_, EF, :_reif))(lhs.varlist, rhs)
        end
    end
    end
end

# Logic Expressions
for (ET, EF) in [(:BeeArrayEq, :eq), (:BeeArrayNeq, :neq), (:BeeLex, :lex), (:BeelexLt, :lexLt)]
    @eval BEE begin
    struct $ET <: BeeExpression
        lhs::Array{T, 1} where T <: Boolean
        rhs::Array{T, 1} where T <: Boolean
    end

    $EF(lhs::Array{T1,1}, rhs::Array{T2,1}) where {T1 <:Boolean, T2 <: Boolean} = $ET(lhs, rhs)

    function (==)(lhs::$ET, rhs::BeeBoolean)
        $(Symbol(:bool_arrays_, EF, :_reif))(lhs.lhs, lhs.rhs, rhs)
    end

    function (==)(lhs::$ET, rhs::Bool)
        if rhs
            $(Symbol(:bool_arrays_, EF))(lhs.lhs, lhs.rhs)
        else
            $(Symbol(:bool_arrays_, EF, :_reif))(lhs.lhs, lhs.rhs, rhs)
        end
    end
    end
end

# Integer variable

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

render(io::IO, var::BeeInt) = print(io, "new_int($var, $(var.lo), $(var.hi))\n")

alldiff(arr::Array{BeeInt, 1}) = int_array_allDiff(arr)

for (OP, F) in [(:(<=), :leq), (:(>=), :geq), (:(==), :eq), (:(<), :lt), (:(>), :gt), (:(!=), :neq), 
                (:(+), :plus), (:(*), :times)]
    @eval BEE begin
        $OP(lhs::BeeInt, rhs::BeeInt) = $F(lhs, rhs)
        $OP(lhs::Int, rhs::BeeInt) = $F(lhs, rhs)
        $OP(lhs::BeeInt, rhs::Int) = $F(lhs, rhs)
    end
end

# Boolean variable

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
render(io::IO, var::BeeBool) = print(io, "new_bool($var)\n")

# Negate of boolean variable

struct BeeNegateBool <:BeeBoolean
    boolvar::BeeBool
end

BeeBool(name::String) = BeeBool(gblmodel, name)
Base.show(io::IO, v::BeeNegateBool) = print(io, "-", v.boolvar)


(-)(var::BeeBool) = BeeNegateBool(var)

(-)(var::BeeNegateBool) = var.boolvar

(==)(lhs::BeeBoolean, rhs::BeeBoolean) = bool_eq(lhs, rhs)
(==)(lhs::Bool, rhs::BeeBoolean) = bool_eq(lhs, rhs)
(==)(lhs::BeeBoolean, rhs::Bool) = bool_eq(lhs, rhs)
(==)(lhs::BeeSum{BeeBoolean}, rhs::Boolean) = bool_array_sum_eq(lhs.varlist, rhs)

for (OP, F) in [(:(==), :eq), (:(!=), :neq), (:(<=), :lex), (:(<), :lexLt)]
    @eval BEE begin
        $OP(lhs::Array{T1,1}, rhs::Array{T2,1}) where {T1 <: BeeBoolean, T2 <:BeeBoolean} = $F(lhs, rhs) == true
        $OP(lhs::Array{T1,1}, rhs::Array{T2,1}) where {T1 <: Bool, T2 <:BeeBoolean} = $F(lhs, rhs) == true
        $OP(lhs::Array{T1,1}, rhs::Array{T2,1}) where {T1 <: BeeBoolean, T2 <:Bool} = $F(lhs, rhs) == true
    end
end

for (ET, EF) in [(:BeeSum, :sum)], 
    (OP, F) in [(:(<=), :leq), (:(>=), :geq), (:(==), :eq), (:(<), :lt), (:(>), :gt), (:(!=), :neq)]
    @eval BEE begin
        $OP(lhs::$ET{T}, rhs::ZZ) where {T<:Boolean} = $(Symbol(:bool_array_, EF, :_, F))(lhs.varlist, rhs)
        $OP(lhs::$ET{T}, rhs::ZZ) where {T<:ZZ} = $(Symbol(:int_array_, EF, :_, F))(lhs.varlist, rhs)
    end
end

# Constrains

struct BeeConstraint <: BeeObject
    name::String
    varlist::NTuple{N, Union{Literal, Array{T, 1}}} where {N, T <: Literal}
    function BeeConstraint(model::BeeObject, name, var...)
        constraint = new(name, var)
        push!(model.conslist, constraint)
        constraint
    end
end
BeeConstraint(name::String, var...) = BeeConstraint(gblmodel, name, var...)

# For constraints, there's is no difference between how they are rendered an printed
render(io::IO, constraint::BeeConstraint) = print(io, constraint, "\n")

function Base.show(io::IO, constraint::BeeConstraint) 
    print(io, constraint.name, "(", constraint.varlist, ")")
end

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
    @eval BEE $F(var...) = BeeConstraint($SF, var...)
end

# BEE model
struct BeeModel <: BeeObject
    name::String
    intdict::Dict{String, BeeInt}
    booldict::Dict{String, BeeBool}
    conslist::Array{BeeConstraint, 1}
end
BeeModel(name::String) = BeeModel(name, Dict{String, BeeInt}(), Dict{String, BeeBool}(), Array{BeeConstraint,1}())

Base.show(io::IO, m::BeeModel) = print(io, "BEE model [$(m.name)]")
Base.show(io::IO, ::MIME"text/plain", m::BeeModel) = print(io, 
"""BEE model [$(m.name)]:
* Integer variables: $(collect(values(m.intdict)))
* Boolean variables: $(collect(values(m.booldict)))
* Constraint: $(m.conslist)""")

hasvar(model::BeeModel, name::String) = haskey(model.intdict, name) || haskey(model.booldict, name)

# Default model
const gblmodel = BeeModel("defaul model")

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

macro beeint(name, lo, hi) 
    return quote
        $(esc(name)) = BeeInt($(String(name)), $lo, $hi)
    end
end
beeint(name, lo, hi) = BeeInt(name, lo, hi)

macro beebool(name)
    return quote
        $(esc(name)) = BeeBool($(String(name)))
    end
end
beebool(name) = BeeBool(name)

end
