require 'nokogiri'

def extract_id(text)
    extracted_id = ""
    # Use regex to extract the id attribute
    if match = text.match(/id=["']([^"']+)["']/)
        extracted_id = match[1] # The first capturing group contains the id value
    end
    return extracted_id
end

# Given an html text output an array with two elements: [chunks, within_toc]
# Where chunks and within_toc are both array. The input 'html' is such that
#'text' == 'html' is true where 'text' is defined:
#text = ''
#for array_index in 0..(chunks.length()-1) do
#    if within_toc[array_index]
#        text<<"<!--toc_start-->"
#        text<<chunks[array_index]
#        text<<"<!--toc_end-->"
#    else
#        text<<chunks[array_index]
#end
def split_html_with_toc(html)
    # duct tape quick bug fix where if the first part of page was a toc then it wasn't rendering
    html = '<p style="height:0px;width:0px"></p>'+html

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


# Given an html, find each <h2> and wrap
# it in a div including the content following it
# up until the next h2. Give the wrapping div
# an id and class of section.
def wrap_each_h2(text,identifier) # identifier if there are multiple same titles on the page
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
            h2_id = extract_id(section)
            # If we were already in a div, close it
            new_html << '</div>' if in_div
            new_html << '</div>' if in_div
            # Start a new div
            new_html << '<div id="section-'+h2_id+'-'+identifier+'" class="section">'
            new_html << '<div id="mobile-section-'+h2_id+'-'+identifier+'" class="section">'
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
    new_html << '</div>' if in_div
    
    
    new_html = new_html.gsub(/<h2 id="([^"]+)">/) do |match|
      "<h2 id=\"#{$1}-#{identifier}\">"
    end
    
    return new_html
end

# similar to wrap_each_h2 but we only wraps those h2s
# between <!--toc_start--> and <!--toc_end-->
def wrap_each_h2_in_toc_sections(html_text)
    output_arr = split_html_with_toc(html_text)
    chunks = output_arr[0]
    within_toc = output_arr[1]
    
    html_text_output = ''
    for array_index in 0..(chunks.length()-1) do
        if within_toc[array_index]
            html_text_output<<"<!--toc_start-->"
            html_text_output<<wrap_each_h2(chunks[array_index],array_index.to_s)
            html_text_output<<"<!--toc_end-->"
        else
            html_text_output<<chunks[array_index]
        end
    end
        return html_text_output
    end

def remove_mobile_sections(text)
    # Regular expression to match the <div> tags with the specified format
    regex = /<div id="mobile-section[0-9a-zA-Z-]*" class="section">/m
    # Use gsub to replace matched patterns with a simple <div>
    modified_text = text.gsub(regex, '<div>')
    
    modified_text
end
