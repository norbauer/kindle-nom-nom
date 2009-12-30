require 'rubygems'
require 'activesupport'

require 'ruby-debug' ########### REMOVE !!!!!

# TODO command line runnable http://www.ruby-doc.org/stdlib/libdoc/optparse/rdoc/classes/OptionParser.html
# MAYBE import files into Devonthink

require 'kindle_nom_nom/my_clippings_file'
require 'kindle_nom_nom/clipping'
require 'kindle_nom_nom/rtf'
require 'rtf_extensions/rtf'

clippings_file = KindleNomNom::MyClippingsFile.new
clippings_file.export_notes_and_highlights_to_rtf! "/Users/ryan/Documents/Archive/Workspace/kindle_notes"

