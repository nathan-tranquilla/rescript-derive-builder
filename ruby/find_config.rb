#!/usr/bin/env ruby

require 'pathname'

class ConfigFinder
  def self.find_file(filename, start_dir: Dir.pwd, max_depth: 10)
    current_path = Pathname.new(start_dir).expand_path
    depth = 0
    
    while depth < max_depth
      config_file = current_path.join(filename)
      
      # Check if the file exists
      if config_file.exist? && config_file.file?
        return config_file.to_s
      end
      
      # Move up one directory
      parent_path = current_path.parent
      
      # Stop if we've reached the root or can't go higher
      break if parent_path == current_path
      
      current_path = parent_path
      depth += 1
    end
    
    nil # File not found within max_depth
  end
  
end

# Example usage and CLI interface
if __FILE__ == $0
  filename = ARGV[0]
  start_dir = ARGV[1] || Dir.pwd
  max_depth = (ARGV[2] || 10).to_i
  
  if filename.nil?
    puts "Usage: #{$0} <filename> [start_directory] [max_depth]"
    puts "Examples:"
    puts "  #{$0} rescript-derive-builder.config.json"
    puts "  #{$0} package.json /path/to/start 5"
    exit 1
  end
  
  
  # Single file search
  result = ConfigFinder.find_file(filename, start_dir: start_dir, max_depth: max_depth)
  
  if result
    puts "#{result}"
  else
    puts "File '#{filename}' not found within #{max_depth} directory levels from #{start_dir}"
    exit 1
  end
end
