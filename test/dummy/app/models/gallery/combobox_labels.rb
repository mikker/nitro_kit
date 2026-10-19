module Gallery
  # An in-memory label table for the remote Combobox examples. Created labels
  # live for the life of the process, which is enough for the gallery and its
  # system tests without adding a table to the dummy schema.
  module ComboboxLabels
    Label = ::Data.define(:id, :name, :description)

    SEEDED = [
      Label.new(id: 1, name: "Bug", description: "Something is not working"),
      Label.new(id: 2, name: "Billing", description: "Plans, invoices, and payment methods"),
      Label.new(id: 3, name: "Customer report", description: "Raised through support"),
      Label.new(id: 4, name: "Design", description: "Needs a design decision"),
      Label.new(id: 5, name: "Documentation", description: nil),
      Label.new(id: 6, name: "Good first issue", description: "Small and well scoped"),
      Label.new(id: 7, name: "Performance", description: "Latency, memory, or throughput"),
      Label.new(id: 8, name: "Regression", description: "Worked in a previous release"),
      Label.new(id: 9, name: "Security", description: "Handle through the private disclosure process"),
      Label.new(id: 10, name: "Accessibility", description: "Keyboard, screen reader, or contrast")
    ].freeze
    SEARCH_LIMIT = 8
    CREATED_LIMIT = 200

    @created = []
    @lock = Mutex.new

    class << self
      def all
        SEEDED + @lock.synchronize { @created.dup }
      end

      def search(query)
        normalized = query.to_s.strip.downcase
        labels = all
        labels = labels.select { |label| label.name.downcase.include?(normalized) } if normalized.present?
        labels.first(SEARCH_LIMIT)
      end

      def exact(name)
        all.find { |label| label.name.casecmp?(name.to_s.strip) }
      end

      # Unknown ids are dropped: a label deleted between render and submit
      # simply disappears from the re-rendered selection.
      def find_all(ids)
        index = all.index_by { |label| label.id.to_s }
        Array(ids).filter_map { |id| index[id.to_s] }
      end

      def create(name)
        name = name.to_s.strip
        return if name.empty? || name.length > 64

        @lock.synchronize do
          existing = (SEEDED + @created).find { |label| label.name.casecmp?(name) }
          next existing if existing

          @created.shift if @created.size >= CREATED_LIMIT
          id = (SEEDED + @created).map(&:id).max + 1
          Label.new(id:, name:, description: nil).tap { |label| @created << label }
        end
      end
    end
  end
end
