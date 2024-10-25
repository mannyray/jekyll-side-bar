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
        

        def split_html_with_toc(html)
            # Regex to match the <!--toc_start--> and <!--toc_end--> comments
            toc_pattern = /<!--toc_start-->(.*?)<!--toc_end-->/m
            
            # Array to hold the resulting chunks
            chunks = []
            # Array to hold whether each chunk is within TOC or not
            within_toc = []
            
            # Start position for tracking the last end
            last_end = 0
            
            # Scan through the HTML content
            html.scan(toc_pattern) do |match|
                toc_content = match[0]
                start_index = html.index(match[0], last_end) # Find the starting index
                end_index = start_index + match[0].length # Calculate end index
                
                # Add the content before the TOC section if any
                if last_end < start_index
                    chunks << html[last_end...start_index]
                    within_toc << false
                end
                
                # Add the TOC content
                chunks << toc_content
                within_toc << true
                
                # Update the last end position
                last_end = end_index
            end
            
            # Add any remaining content after the last TOC section
            if last_end < html.length
                chunks << html[last_end...html.length]
                within_toc << false
            end
            
            # Return chunks and their TOC status
            [chunks, within_toc]
        end
        
        def wrap_each_h2_in_toc_sections(html_text)
            output_arr = split_html_with_toc(html_text)
            chunks = output_arr[0]
            within_toc = output_arr[1]
            
            html_text_output = ''
            for array_index in 0..(chunks.length()-1) do
                if within_toc[array_index]
                    html_text_output<<"<!--toc_start-->"
                    html_text_output<<wrap_each_h2(chunks[array_index])
                    html_text_output<<"<!--toc_end-->"
                else
                    html_text_output<<chunks[array_index]
                end
            end
                return html_text_output
            end
            
            # write a test for this
            # TODO - > move this to another file
            def wrap_each_h2(text)
                
                new_html = ''
                in_div = false
                
                # Split the HTML content by the <h2> tag
                sections = text.split(/(<h2 [^>]*>|<\/h2>)/)
                if sections.length() > 0
                    new_html << sections[0]
                end
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
                text = wrap_each_h2_in_toc_sections(text)
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
                    <table style="border: none;">
                    <tr>
                    <td style="padding:0px;" class="toc">
                    <div class="sticky-top">
                    <h3><i class="fa fa-list-ol"></i> Contents</h3>
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
