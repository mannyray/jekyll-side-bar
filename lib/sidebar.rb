require 'nokogiri'

module Jekyll
  module TOC
    def toc(text)
        doc = Nokogiri::HTML(text)

        # Find the content between the TOC comments
        toc_section = doc.inner_html[/<!--toc_start-->(.*?)<!--toc_end-->/m, 1]

        # Parse the TOC section to find <h2> headers
        toc_doc = Nokogiri::HTML(toc_section)
        h2_headers = toc_doc.css('h2')

        # Create an array of links to the headers
        header_links = h2_headers.map do |header|
          id = header['id']
          "<li><a href=\"##{id}\">#{header.text}</a></li>"
        end

        # Create the Table of Contents
        table_of_contents = <<-HTML
        <h2>Table of Contents</h2>
        <ul>
          #{header_links.join("\n  ")}
        </ul>
        HTML

        # Insert the TOC into the original HTML
        doc.inner_html = doc.inner_html.sub(/(<!--toc_start-->)(.*?)(<!--toc_end-->)/m) do |match|
          "#{$1}\n#{table_of_contents}#{$2}\n#{$3}"
        end

        # Output the modified HTML
        return doc.to_html

    end
  end
end

# Register the filter
Liquid::Template.register_filter(Jekyll::TOC)
