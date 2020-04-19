using BEE
using Suppressor
using Test

function capture_render(c)
    @capture_out render(c)
end

@testset "BEE.jl" begin
    @testset "simple" begin
        BEE.reset()

        example="""new_int(w, 0, 10)
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
        bool_array_sum_eq([-x1, x2, -x3, x4], w)
        """
        ret = @capture_out include("../example/simple-example.jl")
        @test ret == example

        @test "new_int(w, 0, 10)\n" == capture_render(w)

        c = x+y == z
        @test "int_plus(x, y, z)\n" == capture_render(c)

        c = xl[1] == -xl[2]
        @test "bool_eq(x1, -x2)\n" == capture_render(c)
    end

    @testset "Declaring Variable" begin
        BEE.reset()

        @beebool x1
        @test "new_bool(x1)\n" == capture_render(x1)

        @beeint i1 3 55
        @test "new_int(i1, 3, 55)\n" == capture_render(i1)
    end

    @testset "Boolean statements" begin
        BEE.reset()

        @beebool x1
        @beebool x2
        x3 = BeeBool("x3")

        c = x1 == x2
        @test "bool_eq(x1, x2)\n" == capture_render(c)

        c = -x1 == x2
        @test "bool_eq(-x1, x2)\n" == capture_render(c)

        c = true == and([x1, -x2, x3])
        @test "bool_array_and([x1, -x2, x3])\n" == capture_render(c)

        c = and([x1, x2]) == -x3
        @test "bool_array_and_reif([x1, x2], -x3)\n" == capture_render(c)

        c = -x3 == BEE.xor(-x1, x2)
        @test "bool_xor_reif(-x1, x2, -x3)\n" == capture_render(c)
    end

    @testset "Integer statements" begin
        BEE.reset()

        @beeint x1 3 7
        @beeint x2 4 6
        x3 = beeint("x3", 10, 15)

        c = (x1 < x2) == true
        @test "int_lt(x1, x2)\n" == capture_render(c)

        c = true == (x1 < x2)
        @test "int_lt(x1, x2)\n" == capture_render(c)

        c = false == (x1 < x2)
        @test "int_lt_reif(x1, x2, false)\n" == capture_render(c)

        c = (x1 < x2) == false 
        @test "int_lt_reif(x1, x2, false)\n" == capture_render(c)

        c = alldiff([x1, x2, x3]) == true
        @test "int_array_allDiff([x1, x2, x3])\n" == capture_render(c)

        c = true == alldiff([x1, x2, x3])
        @test "int_array_allDiff([x1, x2, x3])\n" == capture_render(c)

        c = alldiff([x1, x2]) == x3
        @test "int_array_allDiff_reif([x1, x2], x3)\n" == capture_render(c)

        c = x3 == alldiff([x1, x2])
        @test "int_array_allDiff_reif([x1, x2], x3)\n" == capture_render(c)

        #c = x1 * x2 == x3
        #@test "int_times(x1, x2, x3)\n" == capture_render(c)

        #c = x3 == x1 * x2
        #@test "int_times(x1, x2, x3)\n" == capture_render(c)

        #c = max([x1, x2]) == x3
        #@test "int_array_max([x1, x2], x3)\n" == capture_render(c)

        #c = x3 == max([x1, x2])
        #@test "int_array_max([x1, x2], x3)\n" == capture_render(c)

    end
end
