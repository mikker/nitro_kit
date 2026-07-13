require "prism"
require "pathname"

module Gallery
  class SourceCode
    ParsedFile = ::Data.define(:signature, :path, :blocks, :methods)

    CACHE = {}
    CACHE_LOCK = Mutex.new

    def self.from_block(block)
      path, line = block.source_location
      parsed_file = parsed_file(path)
      bodies = parsed_file.blocks.fetch(line) do
        raise ArgumentError, "Could not find the gallery example block at #{parsed_file.path}:#{line}"
      end
      if bodies.many?
        raise ArgumentError, "Gallery source at #{parsed_file.path}:#{line} has multiple blocks on one line"
      end

      new(content: bodies.first, path: parsed_file.path)
    end

    def self.from_method(method)
      path, line = method.source_location
      parsed_file = parsed_file(path)
      content = parsed_file.methods.fetch([ line, method.name ]) do
        raise ArgumentError, "Could not find #{method.name} at #{parsed_file.path}:#{line}"
      end

      new(content:, path: parsed_file.path)
    end

    def self.parsed_file(path)
      raise ArgumentError, "Gallery source has no readable file" unless path && File.file?(path)

      absolute_path = Pathname(path).realpath
      root = NitroKit::Engine.root.realpath
      unless absolute_path.to_s.start_with?("#{root}/")
        raise ArgumentError, "Gallery source must live inside #{root}"
      end

      stat = absolute_path.stat
      signature = [ stat.mtime.to_i, stat.mtime.nsec, stat.ctime.to_i, stat.ctime.nsec, stat.size ]

      CACHE_LOCK.synchronize do
        cached = CACHE[absolute_path.to_s]
        return cached if cached&.signature == signature

        CACHE[absolute_path.to_s] = parse(absolute_path, signature:, root:)
      end
    end

    def self.parse(path, signature:, root:)
      result = Prism.parse_file(path.to_s)
      unless result.success?
        message = result.errors.map(&:message).join(", ")
        raise SyntaxError, "Could not parse #{path}: #{message}"
      end

      blocks = Hash.new { |hash, line| hash[line] = [] }
      methods = {}
      nodes = [ result.value ]

      until nodes.empty?
        node = nodes.shift

        case node
        when Prism::BlockNode
          blocks[node.opening_loc.start_line] << normalized_body(node.body)
        when Prism::DefNode
          methods[[ node.location.start_line, node.name ]] = normalized_body(node.body)
        end

        nodes.concat(node.compact_child_nodes)
      end

      ParsedFile.new(
        signature:,
        path: path.relative_path_from(root).to_s,
        blocks:,
        methods:
      )
    end

    def self.normalized_body(body)
      return "" unless body

      lines = body.location.slice.lines
      indentation = body.location.start_column

      lines.each_with_index.map do |line, index|
        index.zero? ? line : line.sub(/\A[ \t]{0,#{indentation}}/, "")
      end.join.strip
    end

    private_class_method :parsed_file, :parse, :normalized_body

    def initialize(content:, path:)
      @content = validate_text!(:content, content)
      @path = validate_text!(:path, path)
    end

    attr_reader :content, :path

    private

    def validate_text!(name, value)
      return value if value.is_a?(String) && value.present?

      raise ArgumentError, "Gallery source #{name} must be a non-blank String"
    end
  end
end
