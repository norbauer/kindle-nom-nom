module KindleNomNom
  
  class Clipping
    attr_accessor :book_title, :location, :author, :body_paragraphs, :timestamp    
  end
  
  class Note < Clipping
  end
  
  class Highlight < Clipping
  end

end