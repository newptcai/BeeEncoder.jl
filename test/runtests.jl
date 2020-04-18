using BEE
using Suppressor
using Test

@testset "BEE.jl" begin
    @testset "simple" begin
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
        bool_array_sum_eq(([-x1, x2, -x3, x4], w))
        """
        ret = @capture_out include("../example/simple-example.jl")
        @test ret == example

        @test "new_bool(x1)\n" == @capture_out render(xl[1])

        @test "new_int(w, 0, 10)\n" == @capture_out render(w)

        c = x+y == z
        @test "int_plus(x, y, z)\n" == @capture_out render(c)

        c = xl[1] == -xl[2]
        @test "bool_eq(x1, -x2)\n" == @capture_out render(c)
    end
end
