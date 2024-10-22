require 'nokogiri'

module Jekyll
  module TOC
      
    def extract_id(text)
        extracted_id = ""
        # Use regex to extract the id attribute
        if match = text.match(/id=["']([^"']+)["']/)
          extracted_id = match[1] # The first capturing group contains the id value
        end
        return extracted_id
    end
      
    def wrap_each_h2(text)
        new_html = ''
        in_div = false

        # Split the HTML content by the <h2> tag
        sections = text.split(/(<h2 [^>]*>|<\/h2>)/)

        sections.each_with_index do |section, index|
          # Check for opening <h2> tag
          if section.start_with?('<h2 ')
            h2_id =  extract_id(section)
            # If we were already in a div, close it
            new_html << '</div>' if in_div
            # Start a new div
            new_html << '<div id="section-'+h2_id+'" class="section">'
            # Add the <h2> tag
            new_html << section
            in_div = true
          else
            # If we are in a div, just add the content
            new_html << section if in_div
          end
        end
        # Close the last div if it was opened
        new_html << '</div>' if in_div
        return new_html
    end
      
    def toc(text)
        text = wrap_each_h2(text)
        doc = Nokogiri::HTML(text)

        # Process each TOC section
        doc.inner_html = doc.inner_html.gsub(/(<!--toc_start-->)(.*?)(<!--toc_end-->)/m) do |match|
          toc_section = $2

          # Parse the TOC section to find <h2> headers
          toc_doc = Nokogiri::HTML(toc_section)
          h2_headers = toc_doc.css('h2')

          # Create an array of links to the headers
          header_links = h2_headers.map do |header|
            id = header['id']
            "<li><a href=\"#section-#{id}\">#{header.text}</a></li>"
          end

          # Create the Table of Contents
          table_of_contents = <<-HTML
          <table style="border: none;">
            <tr>
              <td class="toc">
                <div class="sticky-top">
                    <h2>Table of Contents</h2>
                    <ul id="menu">
                      #{header_links.join("\n  ")}
                    </ul>
                </span>
              </td>
              <td class="content">#{
                toc_section.gsub(/(<h2[^>]*>)/, '<hr>\1').gsub(/(<h2[^>]*>.*?<\/h2>)/m) { |h| "#{h}" }
              }</td>
            </tr>
          </table>
          HTML
        end

        # Output the modified HTML
        return doc.to_html

    end
  end
end

# Register the filter
Liquid::Template.register_filter(Jekyll::TOC)
