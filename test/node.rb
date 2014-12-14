assert('PureRegexp : Empty') do
  assert_true  //  === "hello"
  assert_true  //  === ""
end

assert('PureRegexp : Escape') do
  assert_true  /\(a\)/  === "(a)"
end

assert('PureRegexp : MULTILINE') do
  assert_false /aaa.bbb/  === "aaa\nbbb"
  assert_true  /aaa.bbb/m === "aaa\nbbb"
end

assert('PureRegexp : String') do
  assert_true  /hello/  === "hello"
  assert_true  /hello/  === "@ hello, world"
  assert_true  /hello/i === "HelloWorld"
  assert_false /hello/  === "Hello"
  assert_false /hello/i === "Bye"
end

assert('PureRegexp : Any') do
  assert_true  /...../  === "hello"
  assert_true  /h.l.o/i === "heLoo"
  assert_false /.../i   === "zz"
end

assert('PureRegexp : Front') do
  assert_true  /^he/  === "hello"
  assert_false /^he/  === "hhello"
end

assert('PureRegexp : Back') do
  assert_true  /lo$/ === "hello"
  assert_false /lo$/ === "helloo"
end

assert('PureRegexp : ZeroOrOne') do
  assert_true /a?b?c?/ === ""
  assert_true /a?b?c?/ === "a"
  assert_true /a?b?c?/ === "b"
  assert_true /a?b?c?/ === "c"
  assert_true /a?b?c?/ === "ab"
  assert_true /a?b?c?/ === "bc"
  assert_true /a?b?c?/ === "ac"
  assert_true /a?b?c?/ === "abc"
  assert_true /a?????/ === ""
end

assert('PureRegexp : Group') do
  assert_equal ["", nil], /()/.match("").to_a
  assert_equal ["", nil], /()/.match("abc").to_a
  assert_equal ["", nil], /(zzz)?/.match("abc").to_a

  assert_equal ["abc", "abc", "abc", "abc", "abc", "abc"],
               /(((((abc)))))/.match("abc").to_a

  assert_equal ["abcdefghijklm", "bcdefghijkl", "cdefghijk", "defghij", "efghi", "fgh", "g"],
               /a(b(c(d(e(f(g)h)i)j)k)l)m/.match("abcdefghijklm").to_a

  assert_equal ["zx", "zx", "z"], /((z)?x)?/.match("zx").to_a
end
