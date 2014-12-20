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
            nodes << Node::CharacterClass.new(expand_range("a-zA-Z0-9_"), false)
          when 'W'
            nodes << Node::CharacterClass.new(expand_range("a-zA-Z0-9_"), true)
          when 's'
            nodes << Node::CharacterClass.new(expand_range(" \t\r\n\f\v"), false)
          when 'S'
            nodes << Node::CharacterClass.new(expand_range(" \t\r\n\f\v"), true)
          when 'd'
            nodes << Node::CharacterClass.new(expand_range("0-9"), false)
          when 'D'
            nodes << Node::CharacterClass.new(expand_range("0-9"), true)
          when 'h'
            nodes << Node::CharacterClass.new(expand_range("0-9a-fA-F"), false)
          when 'H'
            nodes << Node::CharacterClass.new(expand_range("0-9a-fA-F"), true)
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
            nodes << Node::Repeat.new(nodes.pop, false, 0, 1)
          end
        when '*'
          raise SyntaxError.new("target of repeat operator is not specified") if nodes.empty?
          nodes << Node::Repeat.new(nodes.pop, false, 0)
        when '+'
          raise SyntaxError.new("target of repeat operator is not specified") if nodes.empty?
          nodes << Node::Repeat.new(nodes.pop, false, 1)
        when '{'
          range = regexp[i..(regexp).length-1].scan(/\{(\d*)(,?)(\d*)\}/)
          if range.empty? || (range[0][0].nil? && range[0][2].nil?)
            nodes << Node::String.new(c)
          else
            r = range[0]
            if r[1].nil?
              nodes << Node::Repeat.new(nodes.pop, false, r[0].to_i, r[0].to_i, true)
              i += r[0].length + 1
            else
              i += 2
              if r[0].nil?
                r[0] = 0
              else
                i += r[0].length
                r[0] = r[0].to_i
              end
              if r[2].nil?
                r[2] = nil
              else
                i += r[2].length
                r[2] = r[2].to_i
              end
              nodes << Node::Repeat.new(nodes.pop, false, r[0], r[2])
            end
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
          exp = expand_range(exp)
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

    def expand_range(string)
      exp = string
      exp.scan(/(.)-(.)/).each do |b, e|
        next if b == '\\'
        map = "0123456789|abcdefghijklmnopqrstuvwxyz|ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        first = map.index(b)
        last = map.index(e)
        if first.nil? || last.nil? || first > last || !map[first..last].index('|').nil?
          raise SyntaxError.new("empty range in char class")
        end
        exp.gsub!("#{b}-#{e}", map[first..last])
      end
      exp.gsub '\-', '-'
    end
  end
end
