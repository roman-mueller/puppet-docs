module Jekyll
  module Tags
    class MarkdownBlock < Liquid::Block
      include Liquid::StandardFilters

      def initialize(tag_name, markup, tokens)
        super
        @prefix = ""
        @suffix = ""
      end

      def render(context)
        md_converter = context.registers[:site].converters.select {|c| c.matches('.md')}.first
          # Found that bit via Jekyll::Renderer's converters method.
        block_contents = super.to_s
          # IDK why you'd need to_s on a string, but the highlight tag does it, so we will too.

        output = md_converter.convert(block_contents)
        @prefix + output + @suffix
      end
    end

    # The collapse tag requires:
    # * A label, as an argument to the opening tag. No quotes needed.
    # * A content body, as a block between the opening and closing tags.
    # e.g.:
    # {% collapse This label will be displayed on the button. %}
    # ...content...
    # {% endcollapse %}
    class CollapseBlock < MarkdownBlock
      def initialize(tag_name, markup, tokens)
        super
        @label = markup.strip
        @id = @label.gsub(/\W/, '') # Remove spaces and punctuation
        @prefix = "<div role='tab' id='heading" + @id + "'><h2 class='collapse-heading'><a class='collapsed' data-toggle='collapse' href='#" + @id + "' aria-expanded='true' aria-controls='" + @id + "'>" + @label + "</a></h2></div><div id='" + @id + "' class='collapse' role='tabpanel' aria-labelledby='heading" + @id + "'>"
        @suffix = "</div>"

      end
    end

  end
end

# This is where we set the UI names for our tags. Setting that first one to 'md' means we'll call it as {% md %} ... {% endmd %}
Liquid::Template.register_tag('md', Jekyll::Tags::MarkdownBlock)
Liquid::Template.register_tag('collapse', Jekyll::Tags::CollapseBlock)
