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
        f = @group.fiber
        result = f.resume(ctx, {}, input)
        m = result ? result.matches : []
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
        return Result.new(input.range, [[]]) if @nodes.empty?
        idx = [0] * @nodes.length
        len = [0] * @nodes.length
        mat = [[]] * @nodes.length
        m = []

        if index > 0
          @nodes.length.times do |i|
            rid = @nodes.length-i-1
            pat = @nodes[rid].patterns(input)
            idx[rid] = index % pat
            index /= pat
          end
        end

        i = 0
        while i <= (@nodes.length-1)
          if idx[i] >= @nodes[i].patterns(input)
            break if i == 0
            idx[i] = 0
            idx[i-1] += 1
            i -= 1

            #atomic grouping
            t = @nodes[i]
            if t.class == Node::Group && t.atomic
              break if i == 0
              idx[i] = 0
              idx[i-1] += 1
              i -= 1
            end

            next
          end
          l = 0
          l = len[0..(i-1)].inject(0) {|sum, n| sum + n} if i > 0
          n = @nodes[i].match(ctx, bref, input.substr(l), idx[i]).matches
          mat[i] = n
          if n.empty?
            idx[i] += 1
            if index >= 0
              break
            else
              next
            end
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
        @nodes.inject(1){|sum, n| sum * n.patterns(input)}
      end

      def fiber
        Fiber.new do |ctx, bref, input|
          fmap = @nodes.map {|n| n.fiber}
          mat = [[]] * @nodes.length

          e = !@nodes.empty?
          unless e
            if !@tag.nil?
              bref[@tag.to_s] = ""
            end
            Fiber.yield(Result.new(input.range, [[]]))
          end

          while e
            l = 0
            fmap.size.times do |i|
              if mat[i].empty?
                r = fmap[i].resume(ctx, bref, input.substr(l))
                if r.nil?
                  if i == 0
                    e = false
                  else
                    fmap[i] = @nodes[i].fiber
                    mat[i-1] = []

                    #atomic grouping
                    t = @nodes[i-1]
                    if t.class == Node::Group && t.atomic
                      if i <= 1
                        e = false
                      else
                        fmap[i-1] = @nodes[i-1].fiber
                        mat[i-2] = []
                      end
                    end
                  end
                  break
                elsif r.matches.empty?
                  break
                else
                  mat[i] = r.matches
                end
              end
              if i == fmap.size - 1
                unless mat[i].empty?
                  l = mat.flatten.inject(0){|sum, n| sum + n}
                  if !@tag.nil?
                    bref[@tag.to_s] = bref[@tag.to_s] = input.str[0, l]
                  end
                  Fiber.yield(Result.new(input.range, mat))
                  mat[i] = []
                end
              else
                l += mat[i].flatten.inject(0) {|sum, n| sum + n}
              end
            end
          end
          nil
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

      def match(ctx, bref, input, index)
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

      def fiber
        Fiber.new do |ctx, bref, input|
          last = @last ? @last : input.to_s.length
          range = (@first..last).to_a
          range.reverse! unless @reluctant

          range.each do |i|
            if i == 0
              Fiber.yield(Result.new(input.range, [[]]))
            else
              matches = []
              offset = 0
              i.times do
                m = @child.fiber.resume(ctx, bref, input.substr(offset))
                matches << m.matches unless m.nil? || m.matches.empty?
              end
              Fiber.yield(Result.new(input.range, matches)) if matches.length == i
            end
          end

          nil
        end
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

      def fiber
        Fiber.new do |ctx, bref, input|
          if @first.nil?
            Fiber.yield(Result.new(input.range, [[], []]))
          else
            f = @first.fiber
            while !(m = f.resume(ctx, bref, input)).nil?
              Fiber.yield(Result.new(input.range, [m.matches, []])) unless m.matches.empty?
            end
          end
          if @second.nil?
            Fiber.yield(Result.new(input.range, [[], []]))
          else
            f = @second.fiber
            while !(m = f.resume(ctx, bref, input)).nil?
              Fiber.yield(Result.new(input.range, [[], m.matches])) unless m.matches.empty?
            end
          end
          Fiber.yield(Result.new(input.range, []))
          nil
        end
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

      def fiber
        Fiber.new do |ctx, bref, input|
          m = []
          if input.option & IGNORECASE == IGNORECASE
            m = [[@str.length]] if input.str.downcase.index(@str.downcase) == 0
          else
            m = [[@str.length]] if input.str.index(@str) == 0
          end
          Fiber.yield(Result.new(input.range, m))
          nil
        end
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

      def fiber
        Fiber.new do |ctx, bref, input|
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
          Fiber.yield(Result.new(input.range, m))
          nil
        end
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

      def fiber
        Fiber.new do |ctx, bref, input|
          m = input.str.empty? ? [] : [[1]]
          if input.option & MULTILINE != MULTILINE && input.str[0] == "\n"
            m = []
          end
          Fiber.yield(Result.new(input.range, m))
          nil
        end
      end
    end

    class CharacterClass
      def initialize(chars, inverse=false)
        @chars = chars.split('').uniq.join
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

      def fiber
        Fiber.new do |ctx, bref, input|
          m = false
          unless input.str.empty?
            if input.option & IGNORECASE == IGNORECASE
              m = !@chars.downcase.index(input.str[0].downcase).nil?
            else
              m = !@chars.index(input.str[0]).nil?
            end
          end
          m = !m if @inverse
          Fiber.yield(Result.new(input.range, m ? [[1]] : []))
          nil
        end
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

      def fiber
        Fiber.new do |ctx, bref, input|
          m = input.range.first == 0 ? [[]] : []
          Fiber.yield(Result.new(input.range, m))
          nil
        end
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

      def fiber
        Fiber.new do |ctx, bref, input|
          m = input.range.first > input.range.last ? [[]] : []
          Fiber.yield(Result.new(input.range, m))
          nil
        end
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
