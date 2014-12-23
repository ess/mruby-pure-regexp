class String
  alias_method :orig_gsub,  :gsub
  alias_method :orig_gsub!, :gsub!
  alias_method :orig_sub,   :sub
  alias_method :orig_sub!,  :sub!

  def scan(reg, &block)
    a = []
    offset = 0
    while !(m = reg.match(self, offset)).nil?
      c = m.captures
      if c.empty?
        if block_given?
          yield(m.to_s)
        else
          a << m.to_s
        end
      else
        if block_given?
          yield(*c)
        else
          a << c
        end
      end
      offset += m.to_s.length
    end
    if block_given?
      self
    else
      a
    end
  end

  def gsub(*args, &block)
    if args[0].is_a? Regexp
      raise ArgumentError.new("wrong number of arguments") unless args.size == 2
      ref = PureRegexp::ReplaceCapture.new(args[1])
      str = ""
      index = 0
      while !(m = args[0].match(self, index)).nil?
        str += (m.pre_match[index..-1] || "") + ref.to_s(m)
        len = m.begin(0) - index + m.to_s.length
        if len == 0
          len = 1
          n = self[(index+len+1)]
          str += n unless n.nil?
        end
        break if m.begin(0) - index < 0
        index += len
      end
      str
    else
      orig_gsub(*args, &block)
    end
  end

  def gsub!(*args, &block)
    if args[0].is_a? Regexp
      self.replace(gsub(*args, &block))
      self
    else
      orig_gsub!(*args, &block)
    end
  end

  def sub(*args, &block)
    if args[0].is_a? Regexp
      raise ArgumentError.new("wrong number of arguments") unless args.size == 2
      ref = PureRegexp::ReplaceCapture.new(args[1])
      m = args[0].match(self)
      return self if m.nil?
      m.pre_match + ref.to_s(m) + m.post_match
    else
      orig_sub(*args, &block)
    end
  end

  def sub!(*args, &block)
    if args[0].is_a? Regexp
      self.replace(sub(*args, &block))
      self
    else
      orig_sub!(*args, &block)
    end
  end
end

class PureRegexp
  class ReplaceCapture
    DIGITS = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
    META = ['`', '\'', '+', '&']

    def initialize(string)
      raise TypeError.new("can't convert #{string.class.name} into String") unless string.is_a? String
      @template = []

      meta = false

      i = 0
      while i < string.length
        c = string[i]
        case c
        when '\\'
          if meta
            @template << c
          end
          meta = !meta
        when *DIGITS
          if meta
            @template << c.to_sym
          else
            @template << c
          end
          meta = false
        when *META
          if meta
            @template << c.to_sym
          else
            @template << c
          end
        else
          if meta
            @template << c
          end
          @template << c
          meta = false
        end
        i += 1
      end
    end

    def to_s(matches)
      str = ""
      @template.each do |c|
        if c.is_a? Symbol
          c = c.to_s
          case c
          when *DIGITS
            s = matches[c.to_s.to_i]
            s = "" if s.nil?
            str += s
          when '`'
            str += matches.pre_match
          when '\''
            str += matches.post_match
          when '+'
            unless matches.captures.empty?
              str += matches.captures.last
            end
          when '&'
            str += matches[0]
          end
        else
          str += c
        end
      end
      str
    end
  end
end
