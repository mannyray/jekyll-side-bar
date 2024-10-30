require 'nokogiri'
require_relative 'sidebar_scripts'

module Jekyll
    module TOC
            def toc(text)
                # include all the necessary scripts and styling for the table
                plugin_dir = File.join(Jekyll.configuration({})['plugins_dir'],"jekyll-side-bar")
                styling_html_content_text = File.read( File.join(plugin_dir,"style.html" ))
                header_html_content_text = File.read( File.join(plugin_dir,"header.html" ))
                script_html_content_text = File.read( File.join(plugin_dir,"script.html" ))
                
                text = wrap_each_h2_in_toc_sections(header_html_content_text + styling_html_content_text + script_html_content_text + text)
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
                    <div class="desktop-only">
                    <table class = "toc_and_content_table">
                    <tr>
                    <td class="toc">
                    <div class="sticky-top">
                    <h3><i class="fa fa-list-ol"></i> Contents</h3>
                    <div class="scrollable">
                    <ul id="menu">
                    #{header_links.join("\n  ")}
                    </ul>
                    </div>
                    </div>
                    </td>
                    <td class="content">#{
                    toc_section.gsub(/(<h2[^>]*>)/, '<hr>\1').gsub(/(<h2[^>]*>.*?<\/h2>)/m) { |h| "#{h}" }
                    }</td>
                    </tr>
                    </table>
                    </div>
                    <div class="mobile-only">
                    #{toc_section}
                    </div>
                    HTML
                end
                
                # Output the modified HTML
                return doc.to_html
            end
        end
    end
    
    # Register the filter
    Liquid::Template.register_filter(Jekyll::TOC)
