module Exodus
  module TextFormatter

    # Prints a paragraphes 
    def super_print(paragraphes, space_number = 50, title = true)
      puts format_paragraph(space_number, title, *paragraphes)
    end

    private 

    # Transforms an array of paragraphes to a String using lines and columns
    # Each paragraph is actually an Array of string, where each string is a sentence of a given column
    # if the sentence contains to much caractere the sentence will be splitted (using whitespaces) and written on several lines 
    # e,g considering paragraphes = [["id", "type"]["id_1", "test"]] 
    # format_paragraph will print:
    # id      type
    # id_1    test
    def format_paragraph(space_number, title, *paragraphes)
      column_size = paragraphes.max_by{|paragraph| paragraph.size}.size
      @full_text = Hash[*column_size.times.map {|i| [i,[]]}.flatten(1)]

      paragraphes.each_with_index do |sentences, paragraph_number|
        sentences.each_with_index do |sentence, column|
          words = sentence.gsub('=>', ' => ').split(' ') || ''
          
          if sentence.size > space_number && (words).size > 1
            new_sentence = ""
            words.each_with_index do |word, nb_word| 
              if new_sentence.size + word.size  < space_number
                new_sentence << word << ' '
              else
                insert_line(column, new_sentence) unless new_sentence.empty?
                new_sentence = word << ' '
              end
            end

            insert_line(column, new_sentence) unless new_sentence == @full_text[column].last
          else 
            insert_line(column, sentence) 
          end
        end

        @full_text.each {|column, lines| (@max_lines - lines.size).times { lines << '' }}
        space = paragraph_number == 0 && title ? "/nbspace" : ""
        @full_text.each {|column, lines| lines << space}
      end

      stringify_paragraph
    end

    # Creates a String from a Hash of the following format {column_number => [lines]}
    # "/nbspace" is used to define a border
    def stringify_paragraph
      ordered_lines = {}

      spaces = @full_text.map {|column, lines| lines.max_by {|sentence| sentence.size}.size}
      @full_text.each_with_index do |(column, lines), i| 
        lines.each_with_index do |line, line_number|
          if line == "/nbspace"
            (ordered_lines[line_number] ||= "") << line.gsub("/nbspace", "-" * (spaces[i] + 4))
          else
            (ordered_lines[line_number] ||= "") << line.to_s.ljust(spaces[i] + 4)
          end
        end
      end

      ordered_lines.values.join("\n")
    end

    # Inserts a line at the correcponding column and re-sets the number of maximum line if the maximum has been increased 
    def insert_line(column, line)
      @max_lines ||= 0
      @full_text[column] << line
      @max_lines = @full_text[column].size if @max_lines < @full_text[column].size
    end
  end
end
