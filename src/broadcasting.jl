"""
    NamedDimsStyle{S}

This is a `BroadcastStyle` for `NamedDimsArray`s,
which now tries to auto-permute dimensions to make things match.
`S` should be the `BroadcastStyle` of the wrapped type.
"""
struct NamedDimsStyle{S <: BroadcastStyle, L} <: AbstractArrayStyle{Any} end

NamedDimsStyle(::S, L::Tuple) where {S} = NamedDimsStyle{S,L}()

NamedDimsStyle(::S, ::Val{N}) where {S,N} = NamedDimsStyle(S(Val(N)), ntuple(_->:_, N))

NamedDimsStyle(::Val{N}) where N = NamedDimsStyle{DefaultArrayStyle{N}, ntuple(_->:_, N)}()

function NamedDimsStyle(a::BroadcastStyle, b::BroadcastStyle, L)
    inner_style = BroadcastStyle(a, b)
    @info "NamedDimsStyle" a b inner_style L

    # if the inner_style is Unknown then so is the outer-style
    if inner_style isa Unknown
        return Unknown()
    else
        return NamedDimsStyle(inner_style, L)
    end
end

function Base.BroadcastStyle(::Type{<:NamedDimsArray{L, T, N, A}}) where {L, T, N, A}
    inner_style = typeof(BroadcastStyle(A))
    return NamedDimsStyle{inner_style, L}()
end

function Base.BroadcastStyle(::NamedDimsStyle{A, LA}, ::NamedDimsStyle{B, LB}) where {A, B, LA, LB}
    if length(LA) < length(LB) || hash(LA) < hash(LB)
        @info "BroadcastStyle -> Unknown" LA LB
        Unknown()
    else
        @info "BroadcastStyle" LA LB
        NamedDimsStyle(A(), B(), unify_names_permuted(LA, LB))
    end
end

Base.BroadcastStyle(::NamedDimsStyle{A, L}, b::B) where {A, B, L} = NamedDimsStyle(A(), b, L)

Base.BroadcastStyle(a::A, ::NamedDimsStyle{B,L}) where {A, B, L} = NamedDimsStyle(a, B(), L)

Base.BroadcastStyle(::NamedDimsStyle{A,L}, b::DefaultArrayStyle) where {A,L} = NamedDimsStyle(A(), b, L)

Base.BroadcastStyle(a::AbstractArrayStyle{M}, ::NamedDimsStyle{B,L}) where {B,M,L} = NamedDimsStyle(a, B(), L)


"""
    unwrap_broadcasted

Recursively unwraps `NamedDimsArray`s and `NamedDimsStyle`s.
replacing the `NamedDimsArray`s with the wrapped array,
and `NamedDimsStyle` with the wrapped `BroadcastStyle`.
"""
function unwrap_broadcasted(bc::Broadcasted{NamedDimsStyle{S,L}}) where {S,L}
    @info "unwrap_broadcasted 1" L
    inner_args = map(arg -> unwrap_broadcasted(arg, L), bc.args)
    return Broadcasted{S}(bc.f, inner_args)
end
function unwrap_broadcasted(x, L)
    @info "unwrap_broadcasted 2" typeof(x) L
    x
end
function unwrap_broadcasted(nda::NamedDimsArray, L)
    @info "unwrap_broadcasted 3 -> permute" names(nda) L
    parent(permutedims(nda, L))
end


# We need to implement copy because if the wrapper array type does not support setindex
# then the `similar` based default method will not work
function Broadcast.copy(bc::Broadcasted{NamedDimsStyle{S, L}}) where {S,L}
    @info "copy" S L
    inner_bc = unwrap_broadcasted(bc) # method 1, this gets L
    data = copy(inner_bc)

    newL = broadcasted_names(bc)
    @info "copy..." newL typeof(data)
    return NamedDimsArray{newL}(data)
end

function Base.copyto!(dest::AbstractArray, bc::Broadcasted{NamedDimsStyle{S}}) where S
    inner_bc = unwrap_broadcasted(bc)
    copyto!(dest, inner_bc)
    L = unify_names(names(dest), broadcasted_names(bc))
    return NamedDimsArray{L}(dest)
end

broadcasted_names(bc::Broadcasted) = broadcasted_names(bc.args...)
function broadcasted_names(a, bs...)
    a_name = broadcasted_names(a)
    b_name = broadcasted_names(bs...)
    @info "broadcasted_names" a_name b_name
    # unify_names_longest(a_name, b_name)
    unify_names_permuted(a_name, b_name)
end
broadcasted_names(a::AbstractArray) = names(a)
broadcasted_names(a) = tuple()
