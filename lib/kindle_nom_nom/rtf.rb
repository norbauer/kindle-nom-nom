require 'rtf'
require 'fileutils'

module KindleNomNom
  
  module SaveableAsRTF
    include RTF
    attr_accessor :book_title, :location, :body_paragraphs, :timestamp, :author, :directory
    
    def save!
      document = Document.new(default_font)

      for paragraph in @body_paragraphs do
        paragraph = "\t" + paragraph if @body_paragraphs.length > 1
        document.paragraph.apply(default_font) << paragraph
      end
    
      document.paragraph.apply(default_font) << " "
      
      if self.class == NoteRTF
        document.paragraph.apply(default_font) << "My note on:" 
      
        document.paragraph.apply(default_font) do |citation|
          citation.apply(italics_font) << @book_title
          citation << " by " + @author unless @author.blank?
        end
      end
            
      document.paragraph.apply(default_font) << @location
      
      if self.class == KindleNomNom::NoteRTF
        FileUtils.mkdir_p File.join(@directory,"my notes")
        filepath = File.join("my notes","#{filename}.rtf")
      else  
        filepath = "#{filename}.rtf"
      end

      filepath = File.join(@directory,filepath)

      File.open(filepath,'w') { |file| file.write(document.to_rtf) } unless File.exist?(filepath)
      FileUtils.touch(filepath, :mtime => @timestamp.to_time)
      
    end
    
    private
    
    def times_new_roman
      Font.new(Font::ROMAN, 'Times New Roman')
    end

    def default_font
      style = CharacterStyle.new
      style.font = times_new_roman
      style.font_size = 36 # in half-points
      style.italic = false
      style
    end

    def italics_font
      style = default_font
      style.italic = true
      style
    end
    
    def filename
      first_paragraph = self.body_paragraphs.first
      sanitize_filename(first_paragraph)
    end
    
    def sanitize_filename(string)
      string = string.gsub(/[^a-zA-Z0-9\s\.\-\,]/, "")[0,251] # safe characters and truncate to 251 characters (255 - ".rtf")
      trim_right_punctuation(string)
    end
    
    def trim_right_punctuation(string)
      while [',','.',' '].include?(string[-1,1]) do
        string = string[0,string.length-1]
      end
      string
    end
    
  end

  class HighlightRTF
    include SaveableAsRTF
    attr_accessor :author # this won't go in the mixin
  end

  class NoteRTF
    include SaveableAsRTF
  end
  
end