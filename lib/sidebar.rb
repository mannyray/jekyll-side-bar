require 'nokogiri'

module Jekyll
  module TOC
    def toc(text)
        doc = Nokogiri::HTML(text)

        # Find all <h2> headers
        h2_headers = doc.css('h2')

        # Create an array of links to the headers
        header_links = h2_headers.map do |header|
          id = header['id']
          "<li><a href=\"##{id}\">#{header.text}</a></li>"
        end
        
        # Create the final output
        table_of_contents = <<-HTML
        <h2>Table of Contents</h2>
        <ul>
          #{header_links.join("\n  ")}
        </ul>
        HTML

        return table_of_contents
    end
  end
end

# Register the filter
Liquid::Template.register_filter(Jekyll::TOC)
