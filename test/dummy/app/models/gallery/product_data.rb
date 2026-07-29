module Gallery
  module ProductData
    Product = ::Data.define(
      :id,
      :name,
      :sku,
      :status,
      :price_cents,
      :inventory_count,
      :description,
      :created_on,
      :updated_at
    )
    LifecycleEvent = ::Data.define(:id, :product_id, :action, :actor, :occurred_at, :detail)

    PRODUCTS = [
      Product.new(
        id: "product_telemetry_hub",
        name: "Telemetry Hub",
        sku: "TEL-001",
        status: :active,
        price_cents: 12_900,
        inventory_count: 84,
        description: "Collects fleet telemetry and turns operational signals into reviewable incidents.",
        created_on: Date.new(2025, 2, 14),
        updated_at: Time.zone.parse("2026-07-28 14:32:00")
      ),
      Product.new(
        id: "product_release_console",
        name: "Release Console",
        sku: "REL-042",
        status: :active,
        price_cents: 8_900,
        inventory_count: 156,
        description: "Coordinates release approvals, production windows, and rollback ownership.",
        created_on: Date.new(2025, 5, 9),
        updated_at: Time.zone.parse("2026-07-27 09:18:00")
      ),
      Product.new(
        id: "product_incident_replay",
        name: "Incident Replay",
        sku: "INC-017",
        status: :archived,
        price_cents: 6_900,
        inventory_count: 0,
        description: "Preserves synchronized incident timelines for audits and response reviews.",
        created_on: Date.new(2024, 11, 3),
        updated_at: Time.zone.parse("2026-06-30 16:45:00")
      ),
      Product.new(
        id: "product_audit_exporter",
        name: "Audit Exporter",
        sku: "AUD-203",
        status: :active,
        price_cents: 4_900,
        inventory_count: 208,
        description: "Packages signed access and configuration history for compliance teams.",
        created_on: Date.new(2025, 8, 22),
        updated_at: Time.zone.parse("2026-07-25 11:06:00")
      ),
      Product.new(
        id: "product_sensor_gateway",
        name: "Sensor Gateway",
        sku: "SEN-108",
        status: :active,
        price_cents: 15_900,
        inventory_count: 39,
        description: "Normalizes field sensor traffic before it enters the production event stream.",
        created_on: Date.new(2026, 1, 19),
        updated_at: Time.zone.parse("2026-07-24 08:52:00")
      ),
      Product.new(
        id: "product_archive_reader",
        name: "Archive Reader",
        sku: "ARC-310",
        status: :archived,
        price_cents: 2_900,
        inventory_count: 0,
        description: "Reads legacy research exports retained under long-term legal holds.",
        created_on: Date.new(2024, 6, 11),
        updated_at: Time.zone.parse("2026-05-18 13:10:00")
      )
    ].freeze
    PRODUCTS_BY_ID = PRODUCTS.index_by(&:id).freeze

    LIFECYCLE_EVENTS = [
      LifecycleEvent.new(
        id: "product_event_activated",
        product_id: "product_telemetry_hub",
        action: :activated,
        actor: "Ada Lovelace",
        occurred_at: Time.zone.parse("2026-07-28 14:32:00"),
        detail: "Published the current pricing and inventory policy."
      ),
      LifecycleEvent.new(
        id: "product_event_price",
        product_id: "product_telemetry_hub",
        action: :price_changed,
        actor: "Grace Hopper",
        occurred_at: Time.zone.parse("2026-07-21 09:17:00"),
        detail: "Changed the monthly price from $119 to $129."
      ),
      LifecycleEvent.new(
        id: "product_event_inventory",
        product_id: "product_telemetry_hub",
        action: :inventory_reconciled,
        actor: "Inventory automation",
        occurred_at: Time.zone.parse("2026-07-18 02:05:00"),
        detail: "Reconciled 84 available licenses across two regions."
      ),
      LifecycleEvent.new(
        id: "product_event_created",
        product_id: "product_telemetry_hub",
        action: :created,
        actor: "Ada Lovelace",
        occurred_at: Time.zone.parse("2025-02-14 10:40:00"),
        detail: "Created the draft product in Analytical Engines."
      ),
      LifecycleEvent.new(
        id: "archived_product_event",
        product_id: "product_incident_replay",
        action: :archived,
        actor: "Ada Lovelace",
        occurred_at: Time.zone.parse("2026-06-30 16:45:00"),
        detail: "Stopped new sales while preserving customer access and history."
      )
    ].freeze

    module_function

    def products = PRODUCTS

    def fetch_product(id) = PRODUCTS_BY_ID.fetch(id)

    def active_product = fetch_product("product_telemetry_hub")

    def archived_product = fetch_product("product_incident_replay")

    def events_for(product)
      LIFECYCLE_EVENTS.select { |event| event.product_id == product.id }
    end
  end
end
