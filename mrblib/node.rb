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
        result = @group.match(ctx, input)
        m = result.matches
        if !m.empty?
          @group.submatch(ctx, input, m[0])
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

      def match(ctx, input)
        key = [Group, input.range, @nodes, @tag]
        return Result.new(input.range, ctx.cache[key]) if ctx.cache.include?(key)

        m = []
        return Result.new(input.range, [[]]) if @nodes.empty?
        stack = [@nodes[0].match(ctx, input).matches]
        tagstack = []
        while !stack.empty?
          l = stack.inject(0) do |sum, n|
            if n.empty?
              sum
            else
              sum + n.first.flatten.inject(0) {|sum, n| sum + n}
            end
          end
          if stack.last.empty? || stack.length >= @nodes.length
            top = stack.map{|n| n.first}
            top.pop
            stack.last.each do |n|
              t = top + [n]
              m.push(t)
            end
            stack.pop
            unless stack.empty?
              # atomic grouping
              t = @nodes[stack.length-1]
              if t.class == Node::Group && t.atomic
                stack.pop
              end
              stack.last.shift unless stack.empty?
            end
          else
            l = stack.inject(0) do |sum, n|
              sum + n.first.flatten.inject(0) {|sum, n| sum + n}
            end
            i = input.substr(l)
            stack.push(@nodes[stack.length].match(ctx, i).matches)
          end
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

      def match(ctx, input)
        key = [Repeat, input.range, @child, @reluctant, @first, @last]
        return Result.new(input.range, ctx.cache[key]) if ctx.cache.include?(key)

        last = @last ? @last : input.to_s.length
        groups = []
        for i in @first..last
          groups << Group.new([@child]*i)
        end
        groups.reverse! unless @reluctant
        m = []
        groups.each do |g|
          m += g.match(ctx, input).matches
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
    end

    class Alternation
      attr_reader :first
      attr_reader :second
      def initialize(first=nil, second=nil)
        @first = first
        @second = second
      end

      def match(ctx, input)
        unless @first.nil?
          m = @first.match(ctx, input).matches
          return Result.new(input.range, [[m, []]]) unless m.empty?
        end
        unless @second.nil?
           m = @second.match(ctx, input).matches
          return Result.new(input.range, [[[], m]]) unless m.empty?
        end
        Result.new(input.range, [])
      end

      def submatch(ctx, input, matches)
        unless matches.empty?
          @first.submatch(ctx, input, matches[0]) unless @first.nil?
          @second.submatch(ctx, input, matches[1]) unless @second.nil?
        end
      end
    end

    # leaf
    class String
      attr_reader :str
      def initialize(str)
        @str = str
      end

      def match(ctx, input)
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
    end

    class Any
      def match(ctx, input)
        m = input.str.empty? ? [] : [[1]]
        if input.option & MULTILINE != MULTILINE && input.str[0] == "\n"
          m = []
        end
        Result.new(input.range, m)
      end

      def submatch(ctx, input, matches)
      end
    end

    class CharacterClass
      def initialize(chars, inverse=false)
        @chars = chars.split('').uniq.join
        @inverse = inverse
      end

      def match(ctx, input)
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
    end

    class Front
      def match(ctx, input)
        m = input.range.first == 0 ? [[]] : []
        Result.new(input.range, m)
      end

      def submatch(ctx, input, matches)
      end
    end

    class Back
      def match(ctx, input)
        m = input.range.first > input.range.last ? [[]] : []
        Result.new(input.range, m)
      end

      def submatch(ctx, input, matches)
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
