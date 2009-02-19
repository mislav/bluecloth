module SampleLoader
  protected
  
  def sample_file(name)
    File.dirname(__FILE__) + '/samples/' + name
  end
  
  def load_samples(*names, &block)
    @sections ||= Hash.new { |h, k| h[k] = [] }
    loaded_samples = []
    
    for name in names
      unless File.exists?(file = sample_file(name))
        $stderr.puts %[WARNING: no samples file for "#{name}"] 
        next
      end
      
      meta_space = true
      section = section_name = sample = nil
      linenum = 0

      begin
        File.foreach(file) do |line|
          linenum += 1

          # Start off in the meta section, which has sections and
          # descriptions.
          if meta_space
            case line
            # Left angles switch into data section for the current section
            # and description.
            when /^<<</
              meta_space = false
              unless sample
                sample = Sample.new(nil, section_name, linenum)
              end
            # Section headings look like:
            # ### [Code blocks]
            when /^### \[([^\]]+)\]/
              section_name = $1.chomp
              section = @sections[section_name]
            # Descriptions look like:
            # # Para plus code block
            when /^# (.*)/
              description = $1.chomp
              
              unless sample
                sample = Sample.new(description, section_name, linenum)
              else
                sample.comment << $1.chomp
              end
            end
          # Data section has input and expected output parts
          else
            case line
            # Right angles terminate a data section, at which point we
            # should have enough data to add a test.
            when /^>>>/
              section = @sections['[no name]'] unless section
              section << sample
              loaded_samples << sample
              sample = nil
              meta_space = true
            # 3-Dashed divider with text divides input from output
            when /^--- (.+)/
              sample.end_input
            # Anything else adds to either input or output
            else
              sample << line
            end
          end
        end
      rescue
        $stderr.puts "error while processing line #{linenum}"
        raise $!
      end
    end

    loaded_samples.each(&block) if block_given?
  end

  class Sample
    attr_reader :comment, :section, :line
    
    def initialize(comment, section_name, line_number)
      @comment = comment
      @section = section_name
      @line = line_number
      
      @input_state = true
      @input = []
      @output = []
    end

    def end_input
      @input_state = false
    end

    def <<(line)
      ( @input_state ? @input : @output ) << line
    end

    def input
      @in_string ||= @input.join('').chomp
    end

    def output
      @out_string ||= @output.join('').chomp
    end
  end
end
