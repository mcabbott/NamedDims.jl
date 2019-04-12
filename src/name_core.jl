
"""
    name2dim(dimnames, [name])

For `dimnames` being a tuple of dimnames (symbols) for dimenensions.
If called with just the tuple,
returns a named tuple, with each name maps to a dimension.
e.g `name2dim((:a, :b)) == (a=1, b=2)`.

If the second `name` argument is given, them the dimension corresponding to that `name`,
is returned.
e.g. `name2dim((:a, :b), :b) == 2`
If that `name` is not found then `0` is returned.
"""
function name2dim(dimnames::Tuple)
    # Note: This code is runnable at compile time if input is a constant
    # If modified, make sure to recheck that it still can run at compile time
    # e.g. via `@code_llvm (()->name2dim((:a, :b)))()` which should be very short
    ndims = length(dimnames)
    return NamedTuple{dimnames, NTuple{ndims, Int}}(1:ndims)
end

function name2dim(dimnames::Tuple, name::Symbol)
    # Note: This code is runnable at compile time if inputs are constants
    # If modified, make sure to recheck that it still can run at compile time
    # e.g. via `@code_llvm (()->name2dim((:a, :b), :a))()` which should just say `return 1`
    this_namemap = NamedTuple{(name,), Tuple{Int}}((0,))  # 0 is default we will overwrite
    full_namemap = name2dim(dimnames)
    dim = first(merge(this_namemap, full_namemap))
    return dim
end

function name2dim(dimnames::Tuple, names)
    # This handles things like `(:x, :y)` or `[:x, :y]`
    # or via the fallbacks `(1,2)`, or `1:5`
    return map(name->name2dim(dimnames, name), names)
end

function name2dim(dimnames::Tuple, dim::Union{Integer, Colon})
    # This is the fallback that allows `NamedDimsArray`'s to be have dimenstions
    # referred to by number. This is required to allow functions on `AbstractArray`s
    # and that use function like `sum(xs; dims=2)` to continue to work without changes
    # `:` is the default for most methods that take `dims`
    return dim
end


"""
    default_inds(dimnames::Tuple)
This is the defult value for all indexing expressions using the given dimnames.
Which is to say: take a full slice on everything
"""
function default_inds(dimnames::Tuple)
    # Note: This code is runnable at compile time if input is a constant
    # If modified, make sure to recheck that it still can run at compile time
    ndims = length(dimnames)
    values = ntuple(_->Colon(), ndims)
    return NamedTuple{dimnames, NTuple{ndims, Colon}}(values)
end


"""
    order_named_inds(dimnames::Tuple; named_inds...)

Returns the values of the `named_inds`, sorted as per the order they appear in `dimnames`,
with any missing dimnames, having there value set to `:`.
An error is thrown if any dimnames are given in `named_inds` that do not occur in `dimnames`.
"""
function order_named_inds(dimnames::Tuple; named_inds...)
    # Note: This code is runnable at compile time if input is a constant
    # If modified, make sure to recheck that it still can run at compile time
    keys(named_inds) ⊆ dimnames || throw(
        DimensionMismatch("Expected $(dimnames), got $(keys(named_inds))")
    )

    slice_everything = default_inds(dimnames)
    full_named_inds = merge(slice_everything, named_inds)
    inds = Tuple(full_named_inds)
end