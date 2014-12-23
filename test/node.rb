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

assert('PureRegexp : StringClass') do
  assert_true  /[a-e]/     === "hello"
  assert_true  /[a-e]/i    === "HELLO"
  assert_false /[^0-9]/i   === "12345"
  assert_true  /[^0\\-9]/i === "12345"
  assert_false /[1\\-9]/i  === '\\'

  assert_true  /\d\d\s/i === "123 45"
  assert_true  /\d\D\d/i === "123 45"
  assert_true  /\w\W/i === "123_45?"
  assert_true  /\h\H/i === "12f_45"
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

assert('PureRegexp : ReluctantZeroOrOne') do
  assert_equal ["", nil], /(abc)??/.match("abc").to_a
  assert_equal ["abcabc", "abc"], /^(abc)??abc$/.match("abcabc").to_a
end

assert('PureRegexp : PossessiveZeroOrOne') do
  assert_false /.?+foo/ === "foo"
end

assert('PureRegexp : ZeroOrMore') do
  assert_true /a*b*c*/ === ""
  assert_true /a*b*c*/ === "aa"
  assert_true /a*b*c*/ === "bbbbbbbb"
  assert_true /a*b*c*/ === "c"
  assert_true /a*b*c*/ === "aabbbb"
  assert_true /a*b*c*/ === "bbbbccccc"
  assert_true /a*b*c*/ === "aaaacc"
  assert_true /a*b*c*/ === "abcc"
  assert_true /a*****/ === ""
end

assert('PureRegexp : ReluctantZeroOrMore') do
  assert_equal ["", nil], /(abc)*?/.match("abc").to_a
  assert_equal ["abcabc", "abc"], /^(abc)*?abc$/.match("abcabc").to_a
end

assert('PureRegexp : PossessiveZeroOrMore') do
  assert_false /.*+foo/ === "zzzzfoozzfoo"
end

assert('PureRegexp : OneOrMore') do
  assert_false /a+b+c+/ === ""
  assert_true  /a+b+c+/ === "aabbcc"
  assert_false /a+b+c+/ === "bbbbbbbb"
  assert_true  /a+b+c+/ === "abcc"
  assert_true  /a+b+c+/ === "aabbbbc"
  assert_true  /a+b+c+/ === "abbbbccccc"
  assert_false /a+b+c+/ === "aaaacc"
  assert_true  /a+b+c+/ === "abcc"
  assert_true  /a+++/   === "aaaa"
end

assert('PureRegexp : Alternation') do
  assert_true  /(aa|bb|cc|k?)+/ === "kaacck"
  assert_false /^(aa|a+|cc|k)+/ === "jkaacck"
end

assert('PureRegexp : ReluctantOneOrMore') do
  assert_equal ["abc", "abc"], /(abc)+?/.match("abcabc").to_a
  assert_equal ["abcabcabc", "abc"], /^(abc)+?abc$/.match("abcabcabc").to_a
end

assert('PureRegexp : PossessiveOneOrMore') do
  assert_false /.++foo/ === "zzzzfoozzfoo"
end

assert('PureRegexp : Exactly') do
  assert_true  /a{3}b/ === "aaaab"
  assert_false /^a{3}b/ === "aaaab"
  assert_true  /^a{3}?/ === "ab"
end

assert('PureRegexp : MoreOrEqual') do
  assert_true  /a{3,}b/ === "aaaab"
  assert_true /^a{3,}b/ === "aaaab"
end

assert('PureRegexp : ReluctantMoreOrEqual') do
  assert_equal ["abcabcabc", "abc"],    /(abc){3,}?/.match("abcabcabcabc").to_a
  assert_equal ["abcabcabcabc", "abc"], /^(abc){3,}?abc$/.match("abcabcabcabc").to_a
end

assert('PureRegexp : LessOrEqual') do
  assert_true  /a{,3}b/ === "aab"
  assert_false /^a{,3}b/ === "aaaab"
end

assert('PureRegexp : ReluctantLessOrEqual') do
  assert_equal ["", nil],               /(abc){,4}?/.match("abcabcabcabc").to_a
  assert_equal ["abcabcabcabc", "abc"], /^(abc){,4}?abc$/.match("abcabcabcabc").to_a
end

assert('PureRegexp : Between') do
  assert_true  /a{3,5}b/ === "aaaab"
  assert_false /^a{3,5}b/ === "aaaaaab"
end

assert('PureRegexp : ReluctantBetween') do
  assert_equal ["abcabc", "abc"],    /(abc){2,5}?/.match("abcabcabcabc").to_a
  assert_equal ["abcabcabc", "abc"], /(abc){2,5}?abc/.match("abcabcabcabc").to_a
end

assert('PureRegexp : Group') do
  assert_equal ["", nil], /()/.match("").to_a
  assert_equal ["", nil], /()/.match("abc").to_a
  assert_equal ["", nil], /(zzz)?/.match("abc").to_a

  assert_equal ["abc", "abc", "abc", "abc", "abc", "abc"],
  /(((((\h\h\h)))))/.match("abc").to_a

  assert_equal ["abcdefghijklm", "bcdefghijkl", "cdefghijk", "defghij", "efghi", "fgh", "g"],
  /a(b(c(d(e(f(g)h)i)j)k)l)m/.match("abcdefghijklm").to_a

  assert_equal ["abcdefghijklm", "bcdefghijkl", "defghij", "g"],
  /a(b(?:c(d(?:e(?:f(g)h)i)j)k)l)m/.match("abcdefghijklm").to_a

  assert_equal ["zx", "zx", "z"], /((z)?x)?/.match("zx").to_a
end

assert('PureRegexp : AtomicGroup') do
  assert_equal ['"Quote"'], /"(?>\w*)"/.match('"Quote"').to_a
  assert_nil /"(?>.*)"/.match('"Quote"')
  assert_nil /(?>.*)"/.match('"Quote"')
end
