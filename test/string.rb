assert('String#scan') do
  assert_equal ["abcd", "efgh", "ijkl"], "abcdefghijklmn".scan(/..../)

  assert_equal [["b", "cd"], ["f", "gh"], ["j", "kl"]],
  "abcdefghijklmn".scan(/.(.)(..)/)

  "abcde".scan(/.(.)(..)/) do |a, b|
    assert_equal "b", a
    assert_equal "cd", b
  end

  "abcdefg".scan(/..../) do |a|
    assert_equal "abcd", a
  end
end

assert('String#gsub') do
  assert_equal "@-@-ackb@-@-", "acbabackbacbab".gsub(/a.?b/, "@-")
  assert_equal "@-acbcb@-abbackb@-acbcb@-abb", "acbabackbacbab".gsub(/a(.?b)/, '@-\0\1')
  assert_equal "abackbacbabackbacbabackbab", "acbabackbacbab".gsub(/a(.?b)/, '\\\'')
  assert_equal "cbbackbcbb", "acbabackbacbab".gsub(/a(.?b)/, '\+')
  assert_equal "acbackbacbabackbacbabackbacb", "acbabackbacbab".gsub(/a(.?b)/, '\`')
  assert_equal "acbabackbacbab", "acbabackbacbab".gsub(/a(.?b)/, '\&')
  assert_equal "cbbackbcbb", "acbabackbacbab".gsub(/a(?<aaa>.?b)/, '\k<aaa>')
end

assert('String#gsub!') do
  assert_equal "-------------", "@-@-ackb@-@-".gsub!(/.?/, "-")
end

assert('String#sub') do
  assert_equal "@-abackbacbab", "acbabackbacbab".sub(/a.?b/, "@-")
  assert_equal "@-acbcbabackbacbab", "acbabackbacbab".sub(/a(.?b)/, '@-\0\1')
  assert_equal  "abcdefghijklmn0,abcdefghijklmno9,abcdefghijklmn0," +
  "abcdefghijklmno8,abcdefghijklmno7,abcdefghijklmno6,abcdefghijklmno5," +
  "abcdefghijklmno4,abcdefghijklmno3,abcdefghijklmno2,abcdefghijklmno1," +
  "abcdefghijklmno0,abcdefg,abcdefgh,abcdefghi,abcdefghij,abcdefghijk," +
  "abcdefghijkl,abcdefghijklm,abcdefghijklmn,abcdefghijklmno,abcdefghijklmnop,qrs",
  "abcdefghijklmnopqrs".sub(/(((((((((((((((a)b)c)d)e)f)g)h)i)j)k)l)m)n)o)p/,
  '\20,\19,\20,\18,\17,\16,\15,\14,\13,\12,\11,\10,\9,\8,\7,\6,\5,\4,\3,\2,\1,\0,')
end

assert('String#sub!') do
  assert_equal "--abackbacbab", "acbabackbacbab".sub!(/a.?b/, "@-").sub!(/./, "-")
end
