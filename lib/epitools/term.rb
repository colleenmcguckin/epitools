#require 'epitools'

require 'epitools/minimal'
require 'epitools/core_ext/string'
require 'io/console'

#
# Example usage:
#   puts Term::Table[ (1..100).to_a ].horizontally #=> prints all the numbers, ordered across rows
#   puts Term::Table[ (1..100).to_a ].vertically #=> prints all the numbers, ordered across columns
#   puts Term::Table[ [[1,2], [3,4]] ] #=> prints the table that was supplied
#
#   Term::Table.new do |t|
#     t.row [...]
#     t.rows[5] = [...]
#     t.rows << [...]
#     t.col []
#   end.to_s
#
#   table.compact.to_s #=> minimize the table's columns
#
module Term

  extend self

  attr_accessor :wrap, :x, :y

  #
  # Return the [width,height] of the terminal.
  #
  def size
    STDIN.winsize.reverse
  end

  def width;  size[0]; end
  def height; size[1]; end
  def goto(x,y); @x, @y = x, y; end
  def pos; [@x, @y]; end

  def clear
    print "\e[H\e[J"
  end

  def color(fore, back=nil)
    @fore = fore
    @back = back if back
  end

  def puts(s)
    # some curses shit
  end

  class Window
    def initialize
    end

    def scroll(dx, dy)
    end
  end

  class Table

    # TODO:
    #
    # * make Table's configuration eaiser to remember by putting the formatting parameters in initialize
    #   eg: Table.new(elements, :sort=>:vertical).to_s
    #

    attr_accessor :border, :columns, :padding, :strip_color, :indent, :width, :height

    def self.[](data)
      self.new(data)
    end

    def initialize(data, options={})
      @data         = data.map(&:to_s)
      @strip_color = options[:ansi] || options[:colorized] || options[:colored] || options[:strip_color] || options[:strip_ansi]

      if strip_color
        @max_size = @data.map { |e| e.strip_color.size }.max
      else
        @max_size = @data.map(&:size).max
      end

      @indent   = options[:indent]  || 0
      @border   = options[:border]
      @columns  = options[:columns]
      @padding  = options[:padding] || 1

      if (options.keys & [:horiz, :horizontal, :horizontally]).any?
        @direction = :horizontal
      else
        @direction = :vertical
      end

      # Update the terminal size
      @width, @height = Term.size
    end

    def num_columns
      return @columns if @columns
      w = @width
      w -= indent
      (w-2) / (@max_size + @padding)
    end

    def num_rows
      (@data.size / num_columns.to_f).ceil
    end

    def column_order
      cols = []
      @data.each_slice(num_rows) { |col| cols << col }
      if (diff = cols.first.size - cols.last.size) > 0
        cols.last.concat [''] * diff
      end
      cols.transpose
    end

    def row_order
      rows = []
      @data.each_slice(num_columns) { |row| rows << row }
      if (diff = rows.first.size - rows.last.size) > 0
        rows.last.concat [''] * diff
      end
      rows
    end

    def sliced_into(n)
      elems = []
      @data.each_slice(n) { |e| elems << e }
      if (diff = elems.first.size - elems.last.size) > 0
        elems.last.concat [''] * diff
      end
      elems
    end

    def in_columns
      return '' if @data.empty?
      render sliced_into(num_rows).transpose
    end
    alias_method :by_columns, :in_columns

    def in_rows
      return '' if @data.empty?
      render sliced_into(num_columns)
    end
    alias_method :by_rows, :in_rows

    def display #(opts={})
      case @direction
      when :horizontal
        puts in_rows
      when :vertical
        puts in_columns
      end
    end

    def to_s
      by_rows
    end

    def render(rows, options={})
      num_cols  = rows.first.size
      result    = []

      if @border
        separator = "+#{(["-" * @max_size] * num_cols).join('+')}+"
        result << separator
      end

      for row in rows

        justified = row.map do |e|
          if (diff = @max_size - e.strip_color.size) > 0
            e = e + (" " * diff)
          end
          e
        end

        if @border
          line = "|#{justified.join('|')}|"
        else
          line = justified.join(' '*@padding)
        end

        result << (" "*indent) + line
      end

      result << separator if @border

      result.join("\n")
    end

  end

end
