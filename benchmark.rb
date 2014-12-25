def benchmark(name, t=100, &blk)
  def round(f, n)
    f.to_s[0, n]
  end
  if block_given?
    start = Time.now.to_f
    t.times(&blk)
    diff = Time.now.to_f - start
    puts " === #{name}\n#{t}\t#{round(diff,5)}s\t#{round(diff/t,7)}s/op\n\n"
  end
end

################################################################################

benchmark("/a*a/") do
  /a*a/.match("a" * 100)
end

benchmark("/(aa|bb|cc|k?)+/") do
  /(aa|bb|cc|k?)+/.match("kaacck" * 10)
end

benchmark("/a(b(c(d(e(f(g)h)i)j)k)l)m/") do
  /a(b(c(d(e(f(g)h)i)j)k)l)m/.match("abcdefghijklm" * 10)
end
