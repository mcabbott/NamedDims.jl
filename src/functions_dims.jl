# This file is for functions that explictly mess with the dimensions of a NameDimsArray

"""
    rename(nda::NamedDimsArray, names)

Returns a new `NameDimsArray` with the given dimension `names`.
`rename` outright replaces the names; while still wrapping the same backing array.
Unlike the constructor, it does not require that new names are compatible
with the old names (though you do still need to match the number of dimensions).
"""
rename(nda::NamedDimsArray, names) = NamedDimsArray(parent(nda), names)

function Base.dropdims(nda::NamedDimsArray; dims)
    numerical_dims = dim(nda, dims)
    data = dropdims(parent(nda); dims=numerical_dims)
    L = remaining_dimnames_after_dropping(names(nda), numerical_dims)
    return NamedDimsArray{L}(data)
end


function Base.permutedims(nda::NamedDimsArray{L}, perm) where {L}
    numerical_perm = dim(nda, perm)
    new_names = permute_dimnames(L, numerical_perm)

    return NamedDimsArray{new_names}(permutedims(parent(nda), numerical_perm))
end

for f in (
    :(Base.transpose),
    :(Base.adjoint),
    :(Base.permutedims),
    :(LinearAlgebra.pinv)
)
    # Vector
    @eval function $f(nda::NamedDimsArray{L,T,1}) where {L,T}
        new_names = (:_, first(L))
        return NamedDimsArray{new_names}($f(parent(nda)))
    end


    # Vector Double Transpose
    if f !== :permutedims
        @eval function $f(nda::NamedDimsArray{L,T,2,A}) where {L,T,A<:CoVector}
            new_names = (last(L),)  # drop the name of the first dimensions
            return NamedDimsArray{new_names}($f(parent(nda)))
        end
    end

    # Matrix
    @eval function $f(nda::NamedDimsArray{L,T,2}) where {L,T}
        new_names = (last(L), first(L))
        return NamedDimsArray{new_names}($f(parent(nda)))
    end
end


# reshape
Base.reshape(nda::NamedDimsArray, dims::Tuple{Vararg{Union{Colon, Int}}}) =
    reshape(parent(nda), dims)
Base.reshape(nda::NamedDimsArray, dims::Tuple{Vararg{Int}}) =
    reshape(parent(nda), dims)
Base.reshape(nda::NamedDimsArray{<:Any,<:Any,1}, dims::Tuple{Vararg{Int}}) =
    reshape(parent(nda), dims)
# special case reshape(vector, 1,1,:,1) gets names (_,_,name,_)
function Base.reshape(nda::NamedDimsArray{L,T,1}, dims::Tuple{Vararg{Union{Colon, Int}}}) where {L,T}
    if sum(map(d -> d===1 ? 0 : d===Colon() ? 1 : 99, dims)) == 1
        new_names = map(d -> d==1 ? :_ : L[1], dims)
        return NamedDimsArray{new_names}(reshape(parent(nda), dims))
    else
        return reshape(parent(nda), dims...)
    end
end

# @generated vector_reshape_names(Val{L}, Val{dims})
