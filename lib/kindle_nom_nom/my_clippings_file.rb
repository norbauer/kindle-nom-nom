module KindleNomNom
  
  class MyClippingsFile
      
    @kindle_newline_delimeter = "\r\n"
    @kindle_clipping_delimeter = "==========" + @kindle_newline_delimeter

    class << self
      attr_accessor :kindle_newline_delimeter, :kindle_clipping_delimeter 
    end

    attr_accessor :clippings, :clippings_grouped_by_book
    
    def initialize(my_clippings_file_path=nil)
      @clippings = []
      @my_clippings_file_path = my_clippings_file_path || "/Volumes/Kindle/documents/My\ Clippings.txt"
      separate_clippings(@my_clippings_file_path)
      group_clippings_into_books
    end
  
    def export_notes_and_highlights_to_rtf!(directory_in_which_to_create_the_files=nil)
      
      @clippings_grouped_by_book.keys.each do |book_title|

        book_directory_name = directory_name_for_the_book_associated_with_a_clipping(@clippings_grouped_by_book[book_title].first)
        
        if directory_in_which_to_create_the_files.blank?
          book_directory_path = File.join('clippings',book_directory_name)
        else
          book_directory_path = File.join(directory_in_which_to_create_the_files,book_directory_name)
        end
        
        FileUtils.mkdir_p book_directory_path
        
        @clippings_grouped_by_book[book_title].each do |clipping|
          rtf_to_save = (clipping.class == Note ? NoteRTF.new : HighlightRTF.new)
          rtf_to_save.book_title = clipping.book_title
          rtf_to_save.author = clipping.author
          rtf_to_save.location = clipping.location
          rtf_to_save.timestamp = clipping.timestamp
          rtf_to_save.body_paragraphs = clipping.body_paragraphs
          rtf_to_save.directory = book_directory_path
          rtf_to_save.save!
        end
        
      end
    end
  
    private
  
    def separate_clippings(path)
      clippings_as_a_raw_chunks_of_text = IO.read(path).split(MyClippingsFile.kindle_clipping_delimeter)

      # remove the UTF identifier inserted at the beginning of the file by the Kindle
      clippings_as_a_raw_chunks_of_text.first.gsub!("\357\273\277", "") 
    
      for clipping_as_raw_chunk_of_text in clippings_as_a_raw_chunks_of_text
        lines_from_raw_clipping = clipping_as_raw_chunk_of_text.split(MyClippingsFile.kindle_newline_delimeter)
  
        # 1st line
        book_info_line = lines_from_raw_clipping.shift # 1st line
        author_string = book_info_line.match(/\(([^)]*)\)$/)[1] rescue "" # Get everything in the last "()"
        
        # 2nd line
        kindle_annotation_info_line = lines_from_raw_clipping.shift # 2nd line
        time_string_from_kindle = kindle_annotation_info_line.match(/Added on (.+)/)[1]
        object_type = (kindle_annotation_info_line =~ /Note/ ? Note : Highlight)

        #  3rd line
        lines_from_raw_clipping.shift # remove the blank line between info and clipping text
      
        # 4th (and last) line
        # this line will be the entirety of the body of the clipping text. Clean up double spaces and split into an array along newlines.
        body_paragraphs = lines_from_raw_clipping.shift.gsub("  "," ").split("\n") 
                  
        clipping_object = object_type.new
        clipping_object.book_title = book_info_line.gsub(/\([^)]*\)$/, "").strip # Get everything before the last "()"
        clipping_object.author = (author_string == "Unknown" ? nil : author_string)
        clipping_object.timestamp = DateTime.strptime(time_string_from_kindle,"%A, %B %d, %Y, %I:%M %p")
        clipping_object.location = kindle_annotation_info_line.match(/Loc\.\s([0-9-]+)/).to_s
        clipping_object.body_paragraphs = body_paragraphs
        
        @clippings << clipping_object
      end
    
    end
  
    def group_clippings_into_books
      @clippings_grouped_by_book = @clippings.group_by(&:book_title)
    end
    
    def directory_name_for_the_book_associated_with_a_clipping(clipping)
      if clipping.author.blank?
        sanitized_book_title(clipping.book_title)
      else
        if clipping.author =~ /and/ # multi-author work
          first_author_name = clipping.author.split(',').first
          first_author_name_components = first_author_name.split(" ")
          formatted_author_name = first_author_name_components.pop + ", " + first_author_name_components.join(" ") + ", et al"
        else
          author_name_parts = clipping.author.split(" ") unless clipping.author.blank?
          if author_name_parts.length > 1
            formatted_author_name = author_name_parts.pop + ", " + author_name_parts.join(" ")
          else
            formatted_author_name = author_name_parts.first
          end
        end
        formatted_author_name + ". " + sanitized_book_title(clipping.book_title) + "."
      end
    end
    
    def sanitized_book_title(title)
      # Remove all punctuation except dots and hyphens
      output = title.gsub /[^a-zA-Z0-9\s\.\-\)\(\'\|\,]/, " "
      # Replace any runs of spaces with just one space
      output = output.gsub /\s+/, " "
    end

  end
  
end