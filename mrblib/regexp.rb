class PureRegexp
  attr_reader :source

  def self.compile(string, option = nil)
    self.new(string, option)
  end

  def self.escape(string)
    string
  end

  def initialize(string, option = nil)
    @source = string
    @root = Parser.new().parse(string)
    @option = 0
    if option.is_a? String
      @option |= IGNORECASE if option.include? 'i'
      @option |= MULTILINE  if option.include? 'm'
    elsif option.is_a? Fixnum
      @option = option
    end
  end

  def eql?(other)
    [source, options] == [other.source, other.options]
  end

  def ==(other)
    eql?(other)
  end

  def ===(string)
    !match(string).nil?
  end

  def =~(string)
    return nil if string.nil?
    m = match(string)
    m ? m.begin(0) : nil
  end

  def casefold?
    @option & IGNORECASE == IGNORECASE
  end

  def match(str, pos = 0)
    input = Input.new(str, @option).substr(pos)
    m = @root.match(input)
    if block_given?
      yield(m)
    end
    m
  end

  def options
    @option
  end

  IGNORECASE = 1
  EXTENDED   = 2
  MULTILINE  = 4
end

class PureMatchData
  attr_reader :string
  attr_reader :regexp
  def initialize(regexp, string, submatches)
    @regexp = regexp
    @string = string
    keys = submatches.keys.select {|k| k.is_a? Numeric }.sort
    @submatches = keys.map {|k| submatches[k]}

    keys = submatches.keys.select {|k| k.is_a? String }.sort
    @namedsubmatches ={}
    keys.each do |k|
      @namedsubmatches[k] = submatches[k]
    end
  end

  def inspect
    m = [to_s.inspect]
    i = 1
    captures.each do |c|
      m << "#{i}:#{c.inspect}"
      i += 1
    end
    names.each do |k|
      m << "#{k}:#{self[k].inspect}"
    end
    "#<PureMatchData #{m.join(' ')}>"
  end

  def [](*args)
    if args.size == 1 && (args[0].is_a? String)
      string[@namedsubmatches[args[0]]]
    else
      to_a[*args]
    end
  end

  def ==(other)
    [regexp, string, to_a] == [other.regexp, other.string, other.to_a]
  end

  def captures
    a = to_a; a.shift; a
  end

  def hash
    [@regexp, @string, @submatches, @namedsubmatches].hash
  end

  def begin(n)
    m = @submatches[n]
    if m.nil?
      if n == 0
        0
      else
        nil
      end
    else
      (m.first > 0) ? m.first : 0
    end
  end

  def end(n)
    m = @submatches[n]
    if m.nil?
      if n == 0
        0
      else
        nil
      end
    else
      m.last
    end
  end

  def post_match
    e = self.end(0)
    return "" if e.nil? || e >= string.length
    string[e+1, string.length - e - 1]
  end

  def pre_match
    string[0, self.begin(0)]
  end

  def length
    size
  end

  def size
    to_a.size
  end

  def names
    @namedsubmatches.keys
  end

  def offset(n)
    [self.begin(n), self.end(n)]
  end

  def to_a
    m = @submatches.map do |k|
      if k.nil?
        nil
      else
        @string[k]
      end
    end
    m[0] = "" if m[0].nil?
    m
  end

  def to_s
    to_a[0]
  end

  def values_at(*args)
    a = to_a
    args.map {|i| a[i]}
  end
end

Regexp = PureRegexp unless Object.const_defined? :Regexp
MatchData = PureMatchData unless Object.const_defined? :MatchData
