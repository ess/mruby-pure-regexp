class PureRegexp
  class Parser
    def initialize
      @index = 0
    end

    def parse(regexp)
      group = make_group(regexp)
      keys = (0..(@index-1)).map{|x| x}
      Root.new(regexp, group, keys)
    end

    DIGITS = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']

    def make_group(regexp)
      index = @index
      if regexp.index("?:") == 0
        regexp = regexp[2..(regexp.length-1)]
        index = nil
      else
        @index += 1
      end
      nodes = []
      i = 0
      escape = false
      while i < regexp.length
        c = regexp[i]
        if escape
          case c
          when 'w'
            nodes << CC_WORD
          when 'W'
            nodes << CC_NON_WORD
          when 's'
            nodes << CC_WHITESPACE
          when 'S'
            nodes << CC_NON_WHITESPACE
          when 'd'
            nodes << CC_DIGIT
          when 'D'
            nodes << CC_NON_DIGIT
          when 'h'
            nodes << CC_HEX
          when 'H'
            nodes << CC_NON_HEX
          else
            nodes << Node::String.new(c)
          end
          escape = false
          i += 1
          next
        end
        case c
        when '\\'
          escape = true
        when '?'
          raise SyntaxError.new("target of repeat operator is not specified") if nodes.empty?
          if nodes.last.class == Node::Repeat && !nodes.last.reluctant && !nodes.last.exactly
            nodes << nodes.pop.make_reluctant
          else
            n = Node::Repeat.new(nodes.last, false, 0, 1)
            # ignore duplicated repeat operators for an optimization
            unless nodes.last.class == Node::Repeat && nodes.last =~ n
              nodes.pop
              nodes << n
            end
          end
        when '*'
          raise SyntaxError.new("target of repeat operator is not specified") if nodes.empty?
          n = Node::Repeat.new(nodes.last, false, 0)
          # ignore duplicated repeat operators for an optimization
          unless nodes.last.class == Node::Repeat && nodes.last =~ n
            nodes.pop
            nodes << n
          end
        when '+'
          raise SyntaxError.new("target of repeat operator is not specified") if nodes.empty?
          n = Node::Repeat.new(nodes.last, false, 1)
          # ignore duplicated repeat operators for an optimization
          unless nodes.last.class == Node::Repeat && nodes.last =~ n
            nodes.pop
            nodes << n
          end
        when '{'
          range = ''
          cnt = 0
          for n in (i+1)..(regexp.length-1)
            c = regexp[n]
            case c
            when '}'
              break
            when *DIGITS
              range += c
            when ','
              range += c
              cnt += 1
            else
              break
            end
          end
          if range.empty? || cnt > 1
            nodes << Node::String.new(c)
          elsif cnt == 0
            nodes << Node::Repeat.new(nodes.pop, false, range.to_i, range.to_i, true)
            i += range.length + 1
          elsif cnt == 1
            i += 2
            cin = range.index ','
            b = range[0, cin]
            e = range[(cin+1)..-1]
            bi = 0
            ei = nil
            unless b.empty?
              i += b.length
              bi = b.to_i
            end
            unless e.empty?
              i += e.length
              ei = e.to_i
            end
            nodes << Node::Repeat.new(nodes.pop, false, bi, ei)
          end
        when '.'
          nodes << Node::Any.new()
        when '^'
          nodes << Node::Front.new()
        when '$'
          nodes << Node::Back.new()
        when '('
          i += 1
          group = 1
          exp = ""
          gescape = false
          while i < regexp.length
            c = regexp[i]
            if c == ')' && !gescape
              gescape = false
              group -= 1
              if group == 0
                break
              else
                exp += c
              end
            elsif c == '(' && !gescape
              gescape = false
              group += 1
              exp += c
            else
              gescape = (c == "\\")
              exp += c
            end
            i += 1
          end
          if gescape
            raise RegexpError.new("too short escape sequence")
          end
          raise SyntaxError.new("unmatched close parenthesis") if group != 0
          nodes << make_group(exp)
        when ')'
          raise SyntaxError.new("unmatched close parenthesis") if group != 0
        when '['
          i += 1
          group = 1
          exp = ""
          gescape = false
          while i < regexp.length
            c = regexp[i]
            if c == ']' && !gescape
              gescape = false
              group -= 1
              if group == 0
                break
              else
                exp += c
              end
            elsif c == '[' && !gescape
              gescape = false
              group += 1
              exp += c
            else
              gescape = (c == "\\")
              exp += c
            end
            i += 1
          end
          if gescape
            raise RegexpError.new("premature end of char-class")
          end
          inverse = false
          if exp[0] == '^'
            exp[0] = ''
            inverse = true
          end
          exp = Parser.expand_range(exp)
          nodes << Node::CharacterClass.new(exp, inverse)
        else
          nodes << Node::String.new(c)
        end
        i += 1
      end
      if escape
        raise RegexpError.new("too short escape sequence")
      end
      compact = []
      nodes.each do |n|
        if n.is_a?(Node::String) && compact.last.is_a?(Node::String)
          compact << (compact.pop + n)
        else
          compact << n
        end
      end
      Node::Group.new(compact, index)
    end

    CC_RANGE_STR = "0123456789|abcdefghijklmnopqrstuvwxyz|ABCDEFGHIJKLMNOPQRSTUVWXYZ"

    def self.expand_range(string)
      exp = string
      offset = 0
      while !(i = exp.index('-', offset)).nil?
        if i > 0
          b = exp[i-1]
          e = exp[i+1]
          unless b.nil? || e.nil?
            if b == '\\'
              exp[i-1] = ''
            else
              map = CC_RANGE_STR
              first = map.index(b)
              last = map.index(e)
              if first.nil? || last.nil? || first > last || !map[first..last].index('|').nil?
                raise SyntaxError.new("empty range in char class")
              end
              exp = exp[0, i-1] + map[first..last] + exp[(i+2)..-1]
            end
          end
        end
        offset += 1
      end
      exp
    end

    CC_WORD = Node::CharacterClass.new(expand_range("a-zA-Z0-9_"), false)
    CC_NON_WORD = Node::CharacterClass.new(expand_range("a-zA-Z0-9_"), true)
    CC_WHITESPACE = Node::CharacterClass.new(expand_range(" \t\r\n\f\v"), false)
    CC_NON_WHITESPACE = Node::CharacterClass.new(expand_range(" \t\r\n\f\v"), true)
    CC_DIGIT = Node::CharacterClass.new(expand_range("0-9"), false)
    CC_NON_DIGIT = Node::CharacterClass.new(expand_range("0-9"), true)
    CC_HEX = Node::CharacterClass.new(expand_range("0-9a-fA-F"), false)
    CC_NON_HEX = Node::CharacterClass.new(expand_range("0-9a-fA-F"), true)
  end
end
