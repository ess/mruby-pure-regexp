class PureRegexp
  class Context
    attr_reader :submatch
    def initialize(input, keys)
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
      def initialize(tag, nodes)
        @nodes = nodes
        @tag = tag
      end

      def match(ctx, input)
        m = []
        return Result.new(input.range, [[0]]) if @nodes.empty?
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
            stack.last.shift unless stack.empty?
          else
            l = stack.inject(0) do |sum, n|
              sum + n.first.flatten.inject(0) {|sum, n| sum + n}
            end
            i = input.substr(l)
            stack.push(@nodes[stack.length].match(ctx, i).matches)
          end
        end
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
        if len > 0
          ctx.submatch[@tag] = (input.range.first)..(input.range.first+len-1)
        end
      end
    end

  	class ZeroOrOne
  		def initialize(child)
  			@child = child
  		end

  		def match(ctx, input)
        m = @child.match(ctx, input)
  			Result.new(input.range, (m.matches << [[]]).map {|n| [n]})
  		end

      def submatch(ctx, input, matches)
        @child.submatch(ctx, input, matches[0])
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
      @matches = matches
    end
  end
end

# extension method
# https://github.com/h2so5/mruby/blob/master/mrblib/array.rb
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
