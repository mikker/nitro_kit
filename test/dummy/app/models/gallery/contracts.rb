module Gallery
  # The shipped component contract table, read straight from
  # `docs/component_contracts.md` so a gallery page can render a component's own
  # contract without a hand-written copy that drifts from the document.
  module Contracts
    PATH = NitroKit::Engine.root.join("docs/component_contracts.md")
    KEY_CELL = /\A`([A-Za-z:]+)`\z/
    SEPARATOR_CELL = /\A:?-{2,}:?\z/

    Field = ::Data.define(:label, :value)
    Row = ::Data.define(:component, :path, :fields)

    class ContractNotFound < KeyError
    end

    module_function

    def rows
      @rows ||= parse
    end

    def fetch!(component)
      rows[component.to_s] ||
        raise(ContractNotFound, "No component contract row for #{component.inspect} in #{relative_path}")
    end

    # Gallery slugs are the dasherized component names, so the contract key is
    # derivable and never has to be repeated in the catalog.
    def component_name_for(entry)
      entry.slug.tr("-", "_").camelize
    end

    def for_entry(entry)
      fetch!(component_name_for(entry))
    end

    def relative_path
      "docs/component_contracts.md"
    end

    def parse
      lines = PATH.readlines(chomp: true)
      columns = nil
      result = {}

      lines.each_with_index do |line, index|
        next unless table_row?(line)
        next if separator_row?(line)

        cells = split_row(line)

        if separator_row?(lines[index + 1])
          columns = cells
          next
        end

        key = cells.first[KEY_CELL, 1]
        next unless key && columns

        result[key] = Row.new(
          component: key,
          path: relative_path,
          fields: fields_for(columns, cells)
        )
      end

      result.freeze
    end

    def fields_for(columns, cells)
      columns.drop(1).zip(cells.drop(1)).filter_map do |label, value|
        Field.new(label:, value:) if value.present?
      end
    end

    def table_row?(line)
      line.to_s.start_with?("|")
    end

    def separator_row?(line)
      return false unless table_row?(line)

      split_row(line).all? { |cell| cell.match?(SEPARATOR_CELL) }
    end

    def split_row(line)
      line.delete_prefix("|").delete_suffix("|").split("|").map(&:strip)
    end

    private_class_method :parse, :fields_for, :table_row?, :separator_row?, :split_row
  end
end
