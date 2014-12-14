assert('PureRegexp.compile') do
  assert_false PureRegexp.compile("((a)?(z)?x)") === "ZX"

  assert_true PureRegexp.compile("((a)?(z)?x)",
              PureRegexp::IGNORECASE) === "ZX"

  assert_false PureRegexp.compile("z.z", PureRegexp::IGNORECASE) === "z\nz"
end

assert('PureRegexp#match') do
  assert_nil PureRegexp.compile("z.z").match("zzz", 1)
  PureRegexp.compile("z.z").match("zzz") do |m|
    assert_equal "zzz", m[0]
  end
end

assert('PureRegexp#eql?') do
  assert_true  PureRegexp.compile("z.z") == /z.z/
  assert_true  PureRegexp.compile("z.z").eql? /z.z/
  assert_false PureRegexp.compile("z.z") == /z.z/mi
end

assert('PureRegexp#=~') do
  assert_nil PureRegexp.compile("z.z") =~ "azz"
  assert_nil PureRegexp.compile("z.z") =~ nil
  assert_equal 1, PureRegexp.compile("z.z") =~ "azzz"
  assert_equal 0, PureRegexp.compile("z.z") =~ "zzz"
  assert_equal 0, PureRegexp.compile("y?") =~ "zzz"
end

assert('PureRegexp#casefold?') do
  assert_true PureRegexp.compile("z.z", PureRegexp::IGNORECASE).casefold?
end

assert('PureRegexp#options') do
  assert_equal PureRegexp::IGNORECASE, PureRegexp.compile("z.z", PureRegexp::IGNORECASE).options
end

assert('PureRegexp#source') do
  assert_equal "((a)?(z)?x)", PureRegexp.compile("((a)?(z)?x)").source
end

assert('PureRegexp#===') do
  assert_true  /^$/ === ""
  assert_true  /((a)?(z)?x)/ === "zx"
  assert_false /((a)?(z)?x)/ === "z"
  assert_true  /c?/ === ""
end

assert('PureMatchData#==') do
  m = /((a)?(z)?x)?/.match("zx")
  m2 = /((a)?(z)?x)?/.match("zx")
  assert_true m == m2
end

assert('PureMatchData#[]') do
  m = /((a)?(z)?x)?/.match("zx")
  assert_equal "zx", m[0]
  assert_equal "zx", m[1]
  assert_equal nil,  m[2]
  assert_equal "z",  m[3]

  assert_equal ["zx", nil], m[1..2]
end

assert('PureMatchData#begin') do
  m = /((a)?(z)?x)?/.match("zx")
  assert_equal 0, m.begin(0)
  assert_equal 0, m.begin(1)
  assert_equal nil, m.begin(2)
  assert_equal 0, m.begin(3)
end

assert('PureMatchData#end') do
  m = /((a)?(z)?x)?/.match("zx")
  assert_equal 1, m.end(0)
  assert_equal 1, m.end(1)
  assert_equal nil, m.end(2)
  assert_equal 0, m.end(3)
end

assert('PureMatchData#post_match') do
  m = /c../.match("abcdefg")
  assert_equal "fg", m.post_match

  assert_equal "", /c?/.match("").post_match
end

assert('PureMatchData#pre_match') do
  m = /c../.match("abcdefg")
  assert_equal "ab", m.pre_match

  assert_equal "", /c?/.match("").pre_match
end

assert('PureMatchData#captures') do
  m = /((a)?(z)?x)?/.match("zx")
  assert_equal ["zx", nil, "z"], m.captures
end

assert('PureMatchData#to_a') do
  m = /((a)?(z)?x)?/.match("zx")
  assert_equal ["zx", "zx", nil, "z"], m.to_a

  assert_equal [""], /c?/.match("").to_a
end

assert('PureMatchData#length') do
  m = /((a)?(z)?x)?/.match("zx")
  assert_equal 4, m.length
  assert_equal 4, m.size
end

assert('PureMatchData#offset') do
  m = /((a)?(z)?x)?/.match("zx")
  assert_equal [0, 1],     m.offset(0)
  assert_equal [0, 1],     m.offset(1)
  assert_equal [nil, nil], m.offset(2)
  assert_equal [0, 0],     m.offset(3)
end

assert('PureMatchData#to_s') do
  m = /((a)?(z)?x)?/.match("zx")
  assert_equal "zx", m.to_s
end

assert('PureMatchData#values_at') do
  m = /((a)?(z)?x)?/.match("zx")
  assert_equal ["zx", nil, "z"], m.values_at(0, 2, 3)
end
