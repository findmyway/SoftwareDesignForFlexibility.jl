@test SDF.compose(x -> (:foo, x), x -> (:bar, x))(:z) == (:foo, (:bar, :z))

@test SDF.iterate(3, x -> x^2)(5) == 390625

@test SDF.parallel_combine(
    (a, b) -> (a, b),
    (x, y, z) -> (:foo, x, y, z),
    (u, v, w) -> (:bar, u, v, w)
)(:a, :b, :c) == ((:foo, :a, :b, :c), (:bar, :a, :b, :c))

@test SDF.spread_combine(
    (a, b) -> (a, b),
    (x,y) -> tuple(:foo, x, y),
    (u,v,w) -> tuple(:bar, u, v, w)
)(:a, :b, :c, :d, :e) == ((:foo, :a, :b), (:bar, :c, :d, :e))

@test SDF.compose′(x -> (:foo, x), x -> (:bar, x))(:z) == (:foo, (:bar, :z))

@test_throws AssertionError SDF.compose′(x -> (:foo, x), x -> (:bar, x))(:z, :zz) == (:foo, (:bar, :z))

@test SDF.parallel_combine′(
    (a, b) -> (a, b),
    (x, y, z) -> (:foo, x, y, z),
    (u, v, w) -> (:bar, u, v, w)
)(:a, :b, :c) == ((:foo, :a, :b, :c), (:bar, :a, :b, :c))

@test_throws AssertionError SDF.parallel_combine′(
    (a, b) -> (a, b),
    (x, y, z) -> (:foo, x, y, z),
    (u, v) -> (:bar, u, v)
)(:a, :b, :c)


function test_get_arity′(a) end
function test_get_arity′(a, b, c) end
function test_get_arity′(a, b, c, d, e, args...) end

@test SDF.get_arity′(test_get_arity′) == [(1,1), (3,3), (5, Inf)]

@test_throws AssertionError SDF.compose′′(identity, test_get_arity′)(:a, :b)

@test SDF.spread_combine′(
    tuple,
    (x,y) -> (:foo, x,y),
    (x,y,z) -> (:bar, x,y,z)
)(:a,:b,:c,:d,:e) == (:foo, :a, :b, :bar, :c, :d, :e)

@test SDF.parallel_combine′′(
    tuple,
    (x,y)->(:a, x,y),
    (x,y) -> (:b, x,y)
)(:x,:y) == (:a, :x, :y, :b, :x, :y)

@test SDF.discard_argument(3)(tuple)(1,2,3,4) == (1,2,4)
@test SDF.curry_argument(3)(tuple)(3)(1,2,4) == (1,2,3,4)

@testset "regex" begin
    grep(pattern, f=joinpath(@__DIR__, "test_regex.txt")) = [
        line
        for line in readlines(f)
        if !isnothing(match(Base.Regex(pattern), line))
    ]

    @test grep(seq(quo("a"), DOT, quo("c"))) == [
        "[00]. abc",
        "[01]. aac",
        "[02]. acc",
        "[03]. zzzaxcqqq",
        "[10]. catcatdogdog",
        "[12]. catcatcatdogdogdog",
    ]

    @test grep(alt(quo("foo"), quo("bar"), quo("baz"))) == [
        "[05]. foo",
        "[06]. bar",
        "[07]. foo bar baz quux",
    ]

    @test grep(rep(alt(quo("cat"), quo("dog")), 3, 5)) == [
        "[09]. catdogcat",
        "[10]. catcatdogdog",
        "[11]. dogdogcatdogdog",
        "[12]. catcatcatdogdogdog",
        "[13]. acatdogdogcats",
        "[14]. ifacatdogdogs",
        "[15]. acatdogdogsme",
    ]

    @test grep(seq(" ", rep(alt(quo("cat"), quo("dog")), 3, 5), EOL)) == [
        "[09]. catdogcat",
        "[10]. catcatdogdog",
        "[11]. dogdogcatdogdog",
    ]

    digit = char_from("0123456789")
    @test grep(
        seq(
            BOL,
            quo("["),
            digit,
            digit,
            quo("]"),
            quo("."),
            quo(" "),
            char_from("ab"),
            rep(alt("cat", "dog"), 3, 5),
            char_not_from("def"),
            EOL
        )
    ) == ["[13]. acatdogdogcats"]

    @test grep(
        seq(
            " ",
            plus(quo("cat")),
            quo("dog")
        )
    ) == ["[09]. catdogcat", "[11]. dogdogcatdogdog"]

    @test grep(
        seq(
            " ",
            star(quo("cat")),
            quo("dog")
        )
    ) == [
        "[09]. catdogcat",
        "[10]. catcatdogdog",
        "[11]. dogdogcatdogdog",
        "[12]. catcatcatdogdogdog"
    ]
end