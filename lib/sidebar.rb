require 'nokogiri'

module Jekyll
  module TOC
    def toc(text)
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
            "<li><a href=\"##{id}\">#{header.text}</a></li>"
          end

          # Create the Table of Contents
          table_of_contents = <<-HTML
          <table>
            <tr>
              <td class="toc">
                <div class="sticky-top">
                    <h2>Table of Contents</h2>
                    <ul>
                      #{header_links.join("\n  ")}
                    </ul>
                </span>
              </td>
              <td class="content">#{
                toc_section.gsub(/(<h2[^>]*>)/, '<hr>\1').gsub(/(<h2[^>]*>.*?<\/h2>)/m) { |h| "<hr>#{h}" }
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
