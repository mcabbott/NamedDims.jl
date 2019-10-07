using NamedDims
using NamedDims:
    names,
    unify_names,
    unify_names_longest,
    order_named_inds,
    permute_dimnames,
    wild_permutation,
    remaining_dimnames_from_indexing,
    remaining_dimnames_after_dropping
using Test


@testset "dim" begin
    @testset "small case" begin
        @test dim((:x, :y), :x) == 1
        @test dim((:x, :y), :y) == 2
        @test_throws ArgumentError dim((:x, :y), :z)  # not found
    end
    @testset "large case" begin
        @test dim((:x, :y, :a, :b, :c, :d), :x) == 1
        @test dim((:x, :y, :a, :b, :c, :d), :a) == 3
        @test dim((:x, :y, :a, :b, :c, :d), :d) == 6
        @test_throws ArgumentError dim((:x, :y, :a, :b, :c, :d), :z) # not found
    end
end

 @testset "unify_names/unify_names_longest" begin
    @test_throws DimensionMismatch unify_names((:a,), (:a, :b,))

    @test unify_names_longest((:a,), (:a, :b,)) == (:a, :b)
    @test unify_names_longest((:a,), (:a, :_)) == (:a, :_)
    @test unify_names_longest((:a, :b), (:a, :_, :c)) == (:a, :b, :c)

    @test_throws DimensionMismatch unify_names_longest((:a, :b, :c), (:b, :a))

    for unify in (unify_names, unify_names_longest)
        @test unify((:a,), (:a,)) == (:a,)
        @test unify((:a, :b), (:a, :b)) == (:a, :b)
        @test unify((:a, :_), (:a, :b)) == (:a, :b)
        @test unify((:a, :_), (:a, :_)) == (:a, :_)

        @test unify((:a, :b, :c), (:_, :_, :_)) == (:a, :b, :c)
        @test unify((:a, :_, :c), (:_, :b, :_)) == (:a, :b, :c)
        @test unify((:_, :_, :_), (:_, :_, :_)) == (:_, :_, :_)

        @test_throws DimensionMismatch unify((:a,), (:b,))
        @test_throws DimensionMismatch unify((:a,:b), (:b, :a))
        @test_throws DimensionMismatch unify((:a, :b, :c), (:_, :_, :d))
    end
end

@testset "order_named_inds" begin
    @test order_named_inds((:x,)) == (:,)
    @test order_named_inds((:x,); x=2) == (2,)

    @test order_named_inds((:x, :y,)) == (:, :)
    @test order_named_inds((:x, :y); x=2) == (2, :)
    @test order_named_inds((:x, :y); y=2, ) == (:, 2)
    @test order_named_inds((:x, :y); y=20, x=30) == (30, 20)
    @test order_named_inds((:x, :y); x=30, y=20) == (30, 20)
end

@testset "remaining_dimnames_from_indexing" begin
    @test remaining_dimnames_from_indexing((:a, :b, :c), (10,20,30)) == tuple()
    @test remaining_dimnames_from_indexing((:a, :b, :c), (10, :,30)) == (:b,)
    @test remaining_dimnames_from_indexing((:a, :b, :c), (1:1, [true], [20])) == (:a, :b, :c)
end


@testset "remaining_dimnames_after_dropping" begin
    @test remaining_dimnames_after_dropping((:a, :b, :c), 1) == (:b, :c)
    @test remaining_dimnames_after_dropping((:a, :b, :c), 3) == (:a, :b)
    @test remaining_dimnames_after_dropping((:a, :b, :c), (1,3)) == (:b,)
    @test remaining_dimnames_after_dropping((:a, :b, :c), (3,1)) == (:b,)
end

@testset "permute_dimnames" begin
    @test permute_dimnames((:a, :b, :c), (1, 2, 3)) == (:a ,:b, :c)
    @test permute_dimnames((:a, :b, :c), (3, 2, 1)) == (:c ,:b, :a)

    # permute_dimnames allows non-bijective "permutations"
    @test permute_dimnames((:a, :b, :c), (3, 3, 1)) == (:c ,:c, :a)
    @test permute_dimnames((:a, :b, :c), (3, 1))== (:c, :a)

    @test_throws BoundsError permute_dimnames((:a, :b, :c), (30, 30, 30))
    @test_throws BoundsError permute_dimnames((:a, :b), (1, 0))
end

@testset "wild_permute" begin
    @test wild_permutation((:a, :b, :c, :d), (:a, :b, :c, :d)) == (1,2,3,4)
    @test wild_permutation((:a, :b, :c, :d), (:d, :c, :a, :b)) == (3,4,2,1)

    # wildcards in destination
    @test wild_permutation((:a, :b, :c, :d), (:_, :_, :_, :_)) == (1,2,3,4)
    @test wild_permutation((:a, :b, :c, :d), (:_, :_, :_, :a)) == (4,1,2,3)
    @test wild_permutation((:a, :b, :c, :d), (:_, :_, :a, :b)) == (3,4,1,2)
    @test wild_permutation((:a, :b, :c, :d), (:b, :_, :a, :_)) == (3,1,2,4)

    # wildcards in source
    @test wild_permutation((:_, :_, :_, :_), (:a, :b, :c, :d)) == (1,2,3,4)
    @test wild_permutation((:_, :_, :_, :a), (:a, :b, :c, :d)) == (2,3,4,1)
    @test wild_permutation((:_, :b, :_, :a), (:a, :b, :c, :d)) == (3,2,4,1)

    # wildcards in both
    @test wild_permutation((:_, :_, :_, :_), (:_, :_, :_, :_)) == (1,2,3,4)
    @test wild_permutation((:a, :_, :c, :_), (:_, :b, :_, :d)) == (1,2,3,4)
    @test wild_permutation((:a, :_, :c, :_), (:_, :c, :_, :d)) == (1,3,2,4)
    @test wild_permutation((:a, :_, :c, :d), (:_, :c, :_, :a)) == (4,1,2,3)

    # destination longer than source
    @test wild_permutation((:a, :b, :c, :d), (:a, :b, :c, :d, :e)) == (1,2,3,4,5)
    @test wild_permutation((:_, :b, :c, :_), (:b, :_, :_, :_, :c)) == (2,1,5,3,4)

    # impossible to solve
    @test_broken wild_permutation((:a, :a, :c, :d), (:a, :x, :y, :z))
    @test_broken wild_permutation((:a, :a, :c, :d), (:a, :b, :c, :d))
    @test_broken wild_permutation((:a, :_, :c, :d), (:a, :x, :y, :_))
end
