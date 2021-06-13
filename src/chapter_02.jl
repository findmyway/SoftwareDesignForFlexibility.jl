compose(f, g) = (args...) -> f(g(args...))

iterate(n, f) = iszero(n) ? identity : compose(f, iterate(n - 1, f))

parallel_combine(h, f, g) = (args...) -> h(f(args...), g(args...))

# Here we assume each function only has one method and its arity is finite
const ARITY_TABLE = IdDict()

get_arity(f) = get!(ARITY_TABLE, f, first(methods(f)).nargs - 1)

function restrict_arity(f, nargs)
    ARITY_TABLE[f] = nargs
    return f
end

function spread_combine(h, f, g)
    n = get_arity(f)
    m = get_arity(g)
    t = n + m
    function the_combination(args...)
        @assert length(args) == t
        return h(f(args[1:n]...), g(args[(n + 1):end]...))
    end
    return restrict_arity(the_combination, t)
end

#####
# Exercise 2.1: Arity repair
#####
function compose′(f, g)
    @assert get_arity(f) == 1
    return function (args...)
        @assert length(args) == get_arity(g)
        return f(g(args...))
    end
end

function parallel_combine′(h, f, g)
    @assert get_arity(f) == get_arity(g)
    @assert get_arity(h) == 2
    return function (args...)
        @assert length(args) == get_arity(f)
        return h(f(args...), g(args...))
    end
end

#####
# Exercise 2.2: Arity extension
#####

# This is a bit more challenging in Julia since each function may have multiple
# implementations with variable number of arguments.

function get_arity′(f)
    get!(ARITY_TABLE, f) do
        arities = []
        for m in methods(f)
            ps = m.sig.parameters
            if ps[end] <: Vararg
                push!(arities, (length(ps) - 2, Inf))
            else
                push!(arities, (length(ps) - 1, length(ps) - 1))
            end
        end
        sort(arities)
        # TODO: merge overlaps
    end
end

is_arity_match(f, n) = any(l <= n <= r for (l, r) in get_arity′(f))

function compose′′(f, g)
    @assert get_arity(f) == 1
    return function (args...)
        @assert is_arity_match(g, length(args))
        # @assert applicable(g, args)  # this also checks types
        return f(g(args...))
    end
end

function spread_combine′(h, f, g)
    n = get_arity(f)
    m = get_arity(g)
    t = n + m
    function the_combination(args...)
        @assert length(args) == t
        return h((f(args[1:n]...)..., g(args[(n + 1):end]...)...)...)
    end
    return restrict_arity(the_combination, t)
end

#####
# Exercise 2.3: A quickie
#####

parallel_combine′′(h, f, g) = (args...) -> h((f(args...)..., g(args...)...)...)

#####

function discard_argument(i)
    return f -> begin
        (args...) -> begin
            new_args = (args[1:(i - 1)]..., args[(i + 1):end]...)
            f(new_args...)
        end
    end
end

function curry_argument(i)
    return f -> begin
        x -> begin
            (args...) -> begin
                new_args = (args[1:(i - 1)]..., x, args[i:end]...)
                f(new_args...)
            end
        end
    end
end

#####

function permute_arguments(spec...)
    return f -> begin
        (args...) -> f(args[collect(spec)]...)
    end
end

#####

module Regex

export DOT, BOL, EOL, seq, quo, alt, rep, rep′, char_from, char_not_from, plus, star

const DOT = "."
const BOL = "^"
const EOL = raw"$"  # $ means interpolation in Julia

seq(exprs...) = "($(join(exprs)))"

const CHARS_NEEDING_QUOTING = raw".[\^*$"

quo(s) = "(" * join(x ∈ CHARS_NEEDING_QUOTING ? "\\$x" : x for x in s) * ")"

alt(exprs...) = seq(join(map(quo, exprs), "|"))

function rep(expr, n_min, n_max=Inf)
    return seq(
        (expr for _ in 1:n_min)...,
        (n_max == Inf ? ("*",) : (alt(expr, "") for _ in 1:(n_max - n_min)))...,
    )
end

quote_bracketed_contents(s) = filter(==(']'), s) * filter(!∈(raw"]^-"), s) * filter(∈(('-', '^')), s)

function char_from(s)
    if length(s) == 0
        seq(s)
    elseif length(s) == 1
        quo(s)
    else
        "[$(quote_bracketed_contents(s))]"
    end
end

char_not_from(s) = "[^$(quote_bracketed_contents(s))]"

plus(s) = alt(s, "")
star(s) = seq(s, "*")

"improved version"
function rep′(s, n_min, n_max=Inf)
    if n_max == Inf
        rep′(s, n_min, n_min) * star(s)
    else
        "$s{$n_min,$n_max}"
    end
end

end
