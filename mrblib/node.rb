class PureRegexp
  class Context
    attr_reader :submatch
    attr_reader :cache
    def initialize(input, keys)
      @cache = {}
      @submatch = {}
      keys.each do |k|
        @submatch[k] = nil
      end
      len = input.to_s.length
    end
  end

  class Root
    def initialize(regexp, group, keys)
      @regexp = regexp
      @group = group
      @keys = keys
    end

    def match(input)
      ctx = Context.new(input, @keys)
      range = input.range
      len = input.str.length
      for i in 0..(len == 0 ? 0 : len-1)
        result = @group.match(ctx, {}, input, 0)
        m = result.matches
        if !m.empty?
          @group.submatch(ctx, input, m)
          return PureMatchData.new(@regexp, input.to_s, ctx.submatch)
        end
        input = input.substr(1)
      end
      nil
    end
  end

  module Node
    class Group
      attr_reader :nodes
      attr_reader :tag
      attr_reader :atomic
      def initialize(nodes, tag = nil, atomic=false)
        @nodes = nodes
        @tag = tag
        @atomic = atomic
      end

      def match(ctx, bref, input, index)
        key = [Group, input.range, index, @nodes, @tag]
        if ctx.cache.include?(key)
          m = ctx.cache[key]
          return Result.new(input.range, m)
        end

        return Result.new(input.range, [[]]) if @nodes.empty?
        idx = [0] * @nodes.length
        len = [0] * @nodes.length
        mat = [[]] * @nodes.length
        m = []

        i = 0
        while i <= (@nodes.length-1)
          if idx[i] >= @nodes[i].patterns(input)
            break if i == 0
            idx[i] = 0
            idx[i-1] += 1
            i -= 1
            next
          end
          l = 0
          l = len[0..(i-1)].inject(0) {|sum, n| sum + n} if i > 0
          n = @nodes[i].match(ctx, bref, input.substr(l), idx[i]).matches
          mat[i] = n
          if n.empty?
            idx[i] += 1
            next
          elsif i == @nodes.length - 1
            m = mat
            break
          else
            len[i] = n.flatten.inject(0){|sum, n| sum + n}
            if @nodes[i].is_a? Node::Group
              if !@nodes[i].tag.nil?
                bref[@nodes[i].tag.to_s] = input.substr(l).str[0, len[i]]
              end
            end
          end
          i += 1
        end

        l = m.flatten.inject(0){|sum, n| sum + n}
        if !@tag.nil?
          bref[@tag.to_s] = input.str[0, l]
        end

        ctx.cache[key] = m
        Result.new(input.range, m)
      end

      def submatch(ctx, input, matches)
        matches = [] if matches.nil?
        index = 0
        for i in 0..(@nodes.size-1)
          m = matches[i] || []
          @nodes[i].submatch(ctx, input.substr(index), m)
          index += m.flatten.inject(0) {|sum, n| sum + n}
        end
        len = matches.flatten.inject(0) {|sum, n| sum + n}
        if len > 0 && !@tag.nil?
          ctx.submatch[@tag] = (input.range.first)..(input.range.first+len-1)
        end
      end

      def patterns(input)
        1
      end
    end

    class Repeat
      attr_reader :child
      attr_reader :reluctant
      attr_reader :exactly
      attr_reader :first
      attr_reader :last
      def initialize(child, reluctant, first=0, last=nil, exactly=false)
        @child = child
        @reluctant = reluctant
        @first = first
        @last = last
        @exactly = exactly
      end

      def =~(other)
        reluctant == other.reluctant &&
        exactly == other.exactly &&
        first == other.first &&
        last == other.last
      end

      def match(ctx, bref, input, index)
        key = [Repeat, input.range, index, @child, @reluctant, @first, @last]
        return Result.new(input.range, ctx.cache[key]) if ctx.cache.include?(key)

        last = @last ? @last : input.to_s.length
        renge = (@first..last).to_a
        renge.reverse! unless @reluctant

        m = []
        if index < renge.size
          n = Group.new([@child]*renge[index])
          n.patterns(input).times do |i|
            d = n.match(ctx, bref.clone, input, i).matches
            unless d.empty?
              m = d
              break
            end
          end
        end

        ctx.cache[key] = m
        Result.new(input.range, m)
      end

      def submatch(ctx, input, matches)
        last = @last ? @last : input.to_s.length
        Group.new([@child]*matches.length).submatch(ctx, input, matches)
      end

      def make_reluctant
        Repeat.new(@child, true, @first, @last)
      end

      def patterns(input)
        last = @last ? @last : input.to_s.length
        last - @first + 1
      end
    end

    class Alternation
      attr_reader :first
      attr_reader :second
      def initialize(first=nil, second=nil)
        @first = first
        @second = second
      end

      def match(ctx, bref, input, index)
        if index == 0
          unless @first.nil?
            @first.patterns(input).times do |i|
              m = @first.match(ctx, bref.clone, input, i).matches
              return Result.new(input.range, [m, []]) unless m.empty?
            end
          end
        elsif index == 1
          unless @second.nil?
            @second.patterns(input).times do |i|
              m = @second.match(ctx, bref.clone, input, i).matches
              return Result.new(input.range, [[], m]) unless m.empty?
            end
          end
        end
        Result.new(input.range, [])
      end

      def submatch(ctx, input, matches)
        unless matches.empty?
          @first.submatch(ctx, input, matches[0]) unless @first.nil?
          @second.submatch(ctx, input, matches[1]) unless @second.nil?
        end
      end

      def patterns(input)
        2
      end
    end

    # leaf
    class String
      attr_reader :str
      def initialize(str)
        @str = str
      end

      def match(ctx, bref, input, index)
        m = []
        if input.option & IGNORECASE == IGNORECASE
          m = [[@str.length]] if input.str.downcase.index(@str.downcase) == 0
        else
          m = [[@str.length]] if input.str.index(@str) == 0
        end
        Result.new(input.range, m)
      end

      def submatch(ctx, input, matches)
      end

      def +(other)
        String.new(@str + other.str)
      end

      def patterns(input)
        1
      end
    end

    class BackReference
      attr_reader :str
      def initialize(tag)
        @tag = tag
      end

      def match(ctx, bref, input, index)
        m = []
        if bref.key?(@tag)
          str = bref[@tag]
          if input.option & IGNORECASE == IGNORECASE
            m = [[str.length]] if input.str.downcase.index(str.downcase) == 0
          else
            m = [[str.length]] if input.str.index(str) == 0
          end
        else
          raise SyntaxError.new("invalid backref number/name") if @tag != 0
        end
        Result.new(input.range, m)
      end

      def submatch(ctx, input, matches)
      end

      def patterns(input)
        1
      end
    end

    class Any
      def match(ctx, bref, input, index)
        m = input.str.empty? ? [] : [[1]]
        if input.option & MULTILINE != MULTILINE && input.str[0] == "\n"
          m = []
        end
        Result.new(input.range, m)
      end

      def submatch(ctx, input, matches)
      end

      def patterns(input)
        1
      end
    end

    class CharacterClass
      def initialize(chars, inverse=false)
        h = {}
        for i in 0..(chars.length-1)
          h[chars[i]] = 0
        end
        @chars = h.keys.join
        @inverse = inverse
      end

      def match(ctx, bref, input, index)
        m = false
        unless input.str.empty?
          if input.option & IGNORECASE == IGNORECASE
            m = !@chars.downcase.index(input.str[0].downcase).nil?
          else
            m = !@chars.index(input.str[0]).nil?
          end
        end
        m = !m if @inverse
        Result.new(input.range, m ? [[1]] : [])
      end

      def submatch(ctx, input, matches)
      end

      def patterns(input)
        1
      end
    end

    class Front
      def match(ctx, bref, input, index)
        m = input.range.first == 0 ? [[]] : []
        Result.new(input.range, m)
      end

      def submatch(ctx, input, matches)
      end

      def patterns(input)
        1
      end
    end

    class Back
      def match(ctx, bref, input, index)
        m = input.range.first > input.range.last ? [[]] : []
        Result.new(input.range, m)
      end

      def submatch(ctx, input, matches)
      end

      def patterns(input)
        1
      end
    end
  end

  class Input
    attr_reader :range
    attr_reader :option
    def initialize(string, option, range = nil)
      @string = string
      @option = option
      if range
        @range = range
      else
        @range = 0..(string.length-1)
      end
    end

    def to_s
      @string
    end

    def str
      s = @string[@range]
      s.nil? ? "" : s
    end

    def substr(len)
      Input.new(@string, @option, (@range.begin+len)..(@range.end))
    end
  end

  class Result
    attr_reader :range
    attr_reader :matches
    def initialize(range, matches)
      @range = range
      @matches = _deep_clone(matches)
    end

    def _deep_clone(ary)
      r = []
      ary.each do |a|
        if a.is_a? Array
          r << _deep_clone(a)
        else
          r << a
        end
      end
      r
    end
  end
end

# extension method
# https://github.com/mruby/mruby/blob/master/mrbgems/mruby-array-ext/mrblib/array.rb
unless Array.instance_methods(false).include?(:flatten)
  class Array
    def flatten(depth=nil)
      ar = []
      self.each do |e|
        if e.is_a?(Array) && (depth.nil? || depth > 0)
          ar += e.flatten(depth.nil? ? nil : depth - 1)
        else
          ar << e
        end
      end
      ar
    end
  end
end
