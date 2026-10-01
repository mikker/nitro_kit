module Gallery
  module Components
    class CardPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/card.rb"
      end

      def api_note
        "NitroKit::Card.new(size: :md, variant: :default) { |card| card.header { card.title; card.description; card.actions }; card.body; card.footer }"
      end

      def component_template
        example_section(
          "Overview",
          slug: "card-overview",
          description: "A card groups related content on one surface. Title, description, body, and footer are all optional; use the ones the content needs."
        ) do
          example("Simple", slug: "card-simple") do
            render NitroKit::Card.new(id: "gallery-card-simple") do |card|
              card.title("Delete this project?", level: 3)
              card.description("Its exports and activity history are removed permanently. This can’t be undone.")
              card.footer do
                render NitroKit::Button.new("Delete project", variant: :destructive, size: :sm)
                render NitroKit::Button.new("Cancel", size: :sm)
              end
            end
          end

          example("Header, body, and footer", slug: "card-complete-structure") do
            render NitroKit::Card.new(id: "gallery-card-profile") do |card|
              card.header do
                card.title("Profile", level: 3)
                card.description("This is how others see you around the workspace.")
                card.actions do
                  render NitroKit::Dropdown.new(id: "gallery-card-profile-menu", placement: :bottom_end) do |menu|
                    menu.trigger(icon: :ellipsis, label: "Profile actions", size: :sm)
                    menu.item("Copy profile link", icon: :link)
                    menu.item("Reset to defaults", icon: :rotate_ccw)
                  end
                end
              end
              card.divider
              card.body do
                form(id: "gallery-card-profile-form", action: "#profile", method: "post") do
                  render NitroKit::FieldGroup.new do
                    render NitroKit::Field.new(
                      nil,
                      :name,
                      id: "gallery-card-profile-name",
                      name: "profile[name]",
                      value: "Ada Lovelace",
                      label: "Name",
                      autocomplete: "name",
                      required: true,
                      html: { id: "gallery-card-profile-name-field" }
                    )
                    render NitroKit::Field.new(
                      nil,
                      :bio,
                      as: :textarea,
                      id: "gallery-card-profile-bio",
                      name: "profile[bio]",
                      label: "Bio",
                      placeholder: "A few words about yourself",
                      rows: 3,
                      html: { id: "gallery-card-profile-bio-field" }
                    )
                  end
                end
              end
              card.divider
              card.footer do
                plain "Last saved 2 minutes ago"
                card.actions do
                  render NitroKit::Button.new("Cancel", type: :reset, form: "gallery-card-profile-form", size: :sm)
                  render NitroKit::Button.new(
                    "Save",
                    id: "gallery-card-profile-save",
                    type: :submit,
                    form: "gallery-card-profile-form",
                    variant: :primary,
                    size: :sm
                  )
                end
              end
            end
          end
        end

        example_section(
          "Sizes",
          slug: "card-sizes",
          description: "Size coordinates padding, spacing, corner radius, and title size. Small suits dense widgets, medium most records, and large roomy forms."
        ) do
          example("Every size", slug: "card-size-matrix", layout: :matrix, mode: :full_width) do
            {
              sm: "Tight, for small widgets and stats.",
              md: "The default, for most content.",
              lg: "Roomy, for forms and settings."
            }.each do |size, text|
              sample(size.to_s, slug: "size-#{size}") do
                render NitroKit::Card.new(size:) do |card|
                  card.header do
                    card.title("Weekly report", level: 3)
                    card.actions { render NitroKit::Button.new("Edit", size: :sm) }
                  end
                  card.divider
                  card.body(text)
                end
              end
            end
          end
        end

        example_section(
          "Surfaces",
          slug: "card-surfaces",
          description: "Default is raised for primary content. Muted is a quiet tint for secondary panels, and outline keeps only the edge over whatever is behind it."
        ) do
          example("Every surface", slug: "card-surface-matrix", layout: :matrix, mode: :full_width) do
            {
              default: "Raised, for primary content.",
              muted: "A quieter tint for secondary panels.",
              outline: "Just an edge over the surrounding surface."
            }.each do |variant, text|
              sample(variant.to_s, slug: "surface-#{variant}") do
                render NitroKit::Card.new(size: :sm, variant:) do |card|
                  card.title(variant.to_s.capitalize, level: 3)
                  card.description(text)
                end
              end
            end
          end

          example("Sizes on every surface", slug: "card-size-surface-matrix", layout: :matrix, mode: :full_width) do
            NitroKit::Card::SIZES.product(NitroKit::Card::VARIANTS).each do |size, variant|
              sample("#{size} · #{variant}", slug: "#{size}-#{variant}") do
                render NitroKit::Card.new(size:, variant:) do |card|
                  card.header do
                    card.title("Workspace", level: 3)
                    card.description("12 active members · Team plan")
                  end
                  card.divider
                  card.footer do
                    plain "Renews August 1"
                    card.actions { render NitroKit::Button.new("Manage", size: :sm) }
                  end
                end
              end
            end
          end
        end

        example_section(
          "Sections",
          slug: "card-sections",
          description: "Dividers split a card into sections. A header or footer set apart by a divider becomes a band with even spacing above and below its content."
        ) do
          example("Settings list", slug: "card-settings-list") do
            render NitroKit::Card.new(id: "gallery-card-security") do |card|
              card.header do
                card.title("Security", level: 3)
                card.description("Keep your account protected.")
              end
              card.divider
              card.header do
                card.title("Password", level: 4)
                card.description("Last changed 3 months ago")
                card.actions { render NitroKit::Button.new("Change", size: :sm) }
              end
              card.divider
              card.header do
                card.title("Two-factor authentication", level: 4)
                card.description("A code from your authenticator app at sign in")
                card.actions { render NitroKit::Badge.new("On", color: :success, size: :sm) }
              end
            end
          end

          example("Notifications form", slug: "card-form-configurations", layout: :matrix, mode: :full_width) do
            NitroKit::Card::SIZES.each do |size|
              sample(size.to_s, slug: "form-#{size}") do
                form_id = "gallery-card-preferences-#{size}"
                render NitroKit::Card.new(size:) do |card|
                  card.header do
                    card.title("Notifications", level: 3)
                    card.description("Choose what you hear about.")
                  end
                  card.body do
                    form(id: form_id, action: "#preferences", method: "get") do
                      render NitroKit::FieldGroup.new do
                        render NitroKit::Switch.new(label: "Product updates", name: "updates", checked: true)
                        render NitroKit::Switch.new(label: "Weekly digest", name: "digest")
                        render NitroKit::Switch.new(label: "Security alerts", name: "security", checked: true)
                      end
                    end
                  end
                  card.divider
                  card.footer do
                    card.actions do
                      render NitroKit::Button.new("Reset", type: :reset, form: form_id, size: :sm)
                      render NitroKit::Button.new("Save", variant: :primary, type: :submit, form: form_id, size: :sm)
                    end
                  end
                end
              end
            end
          end
        end

        example_section(
          "Full-width content",
          slug: "card-full-width",
          description: "Full regions bleed to the card's edges and take its corner radius where they touch one. Only the region clips, so menus and tooltips can still escape the card."
        ) do
          example("Media", slug: "card-media-configurations", layout: :matrix, mode: :full_width) do
            NitroKit::Card::SIZES.each do |size|
              sample(size.to_s, slug: "media-#{size}") do
                render NitroKit::Card.new(size:) do |card|
                  card.full do
                    img(src: "/gallery/card-landscape.svg", alt: "Layered green hills beneath a warm sun", width: 800, height: 360)
                  end
                  card.header do
                    card.title("Morning hike", level: 3)
                    card.description("September 12 · 8.4 km")
                    card.actions { render NitroKit::Button.new(icon: :heart, label: "Save hike", size: :sm) }
                  end
                end
              end
            end
          end

          example("Table", slug: "card-table") do
            render NitroKit::Card.new(id: "gallery-card-transactions") do |card|
              card.header do
                card.title("Past transactions", level: 3)
                card.actions { render NitroKit::Button.new("Export", icon: :download, size: :sm) }
              end
              card.full do
                render NitroKit::Table.new do |table|
                  table.caption("Transactions this week")
                  table.thead do
                    table.tr do
                      table.th("Merchant")
                      table.th("Category")
                      table.th("Amount", align: :right)
                    end
                  end
                  table.tbody do
                    [
                      [ "Blue Bottle Coffee", "Dining", "−$6.50" ],
                      [ "Figma", "Software", "−$15.00" ],
                      [ "Client payment", "Income", "+$2,400.00" ]
                    ].each do |merchant, category, amount|
                      table.tr do
                        table.th(merchant, scope: :row)
                        table.td(category)
                        table.td(amount, align: :right)
                      end
                    end
                  end
                end
              end
              card.footer("Showing the last 7 days")
            end
          end

          example("Media only", slug: "card-media-only") do
            render NitroKit::Container.new(size: :sm) do
              render NitroKit::Card.new(id: "gallery-card-media-only") do |card|
                card.full do
                  img(src: "/gallery/card-landscape.svg", alt: "Layered green hills beneath a warm sun", width: 800, height: 360)
                end
              end
            end
          end
        end

        example_section(
          "Composition",
          slug: "card-composition",
          description: "Cards hold ordinary Nitro components. Parents own the width and the layout of a collection."
        ) do
          example("Related resources", slug: "card-responsive-collection", mode: :full_width) do
            render NitroKit::Grid.new(cols: "1 sm:2 lg:3", gap: 4) do
              [
                [ "Heading", "Create hierarchical section headings for pages and panels." ],
                [ "Table", "Display structured data with sorting and row actions." ],
                [ "Field", "Pair inputs with labels, descriptions, and errors." ]
              ].each do |title, text|
                render NitroKit::Card.new(size: :sm) do |card|
                  card.header do
                    card.title(title, level: 3)
                    card.description(text)
                    card.actions { render NitroKit::Button.new(icon: :arrow_up_right, label: "Open #{title}", href: "#", size: :sm) }
                  end
                end
              end
            end
          end

          example("Integration detail", slug: "card-integration-detail") do
            integration = Gallery::Data.integrations.fetch(1)

            render NitroKit::Card.new(id: "gallery-card-integration") do |card|
              card.header do
                card.title(integration.name, level: 3)
                card.description(integration.description)
                card.actions do
                  render NitroKit::Badge.new(
                    "Action required",
                    id: "gallery-card-integration-status",
                    color: :warning,
                    size: :sm
                  )
                end
              end
              card.body do
                render NitroKit::DetailsTable.new(
                  integration,
                  id: "gallery-card-integration-details",
                  label: "Slack integration details"
                ) do |details|
                  details.field(:connected_at, label: "Connected")
                  details.field(:delivery_target, label: "Delivery target", value: "Team operations channel")
                end
              end
              card.divider
              card.footer do
                render NitroKit::ButtonGroup.new(
                  id: "gallery-card-integration-actions",
                  label: "Slack integration actions"
                ) do |group|
                  group.button(
                    "Reconnect",
                    id: "gallery-card-integration-reconnect",
                    variant: :primary,
                    size: :sm,
                    icon: :refresh_cw
                  )
                  group.button(
                    "Disconnect",
                    id: "gallery-card-integration-disconnect",
                    variant: :destructive,
                    size: :sm
                  )
                end
              end
            end
          end

          example("Footer action states", slug: "card-footer-states", layout: :matrix, mode: :full_width) do
            [ :ready, :saving, :read_only ].each do |state|
              sample(state.to_s.tr("_", " "), slug: "footer-#{state}") do
                render NitroKit::Card.new(size: :sm, variant: :outline) do |card|
                  card.title("Workspace access", level: 3)
                  card.description("Changes apply to all workspace members.")
                  card.divider
                  card.footer do
                    card.actions do
                      render NitroKit::Button.new("Cancel", size: :sm, disabled: state == :saving)
                      render NitroKit::Button.new("Save", variant: :primary, size: :sm, loading: state == :saving, disabled: state == :read_only)
                    end
                  end
                end
              end
            end
          end
        end

        example_section(
          "Heading levels",
          slug: "card-heading-levels",
          description: "The title slot emits the requested semantic heading level from one through six without changing its size."
        ) do
          example("Complete title scale", slug: "card-title-scale", layout: :matrix, density: :compact) do
            (1..6).each do |level|
              sample("Heading level #{level}", slug: "heading-#{level}") do
                render NitroKit::Card.new(id: "gallery-card-heading-#{level}", size: :sm) do |card|
                  card.title("Level #{level} title", level:)
                  card.description("Card titles follow the surrounding document hierarchy.")
                end
              end
            end
          end
        end

        example_section(
          "Slot boundaries",
          slug: "card-slot-boundaries",
          description: "Individual slots and useful partial structures remain valid without placeholder content."
        ) do
          example("Partial structures", slug: "card-partial-structures", layout: :matrix) do
            sample("Empty surface", slug: "empty") do
              render NitroKit::Card.new(id: "gallery-card-empty") { nil }
            end
            sample("Title only", slug: "title-only") do
              render NitroKit::Card.new(id: "gallery-card-title-only") do |card|
                card.title("A title without supporting content", level: 3)
              end
            end
            sample("Footer only", slug: "footer-only") do
              render NitroKit::Card.new(id: "gallery-card-footer-only") do |card|
                card.footer("Last synchronized July 13, 2026")
              end
            end
            sample("Body and footer", slug: "body-footer") do
              render NitroKit::Card.new(id: "gallery-card-body-footer") do |card|
                card.body("Three pending invitations")
                card.footer("Review access before the next billing cycle")
              end
            end
            sample("Header with actions only", slug: "header-actions") do
              render NitroKit::Card.new(id: "gallery-card-header-actions") do |card|
                card.header do
                  card.title("Invitations", level: 3)
                  card.actions { render NitroKit::Button.new("Invite", size: :sm) }
                end
              end
            end
            sample("Full-width only", slug: "full-only") do
              render NitroKit::Card.new(id: "gallery-card-full-only") do |card|
                card.full { card.body("A full-width region can be the only declared slot.") }
              end
            end
          end
        end

        example_section(
          "Under pressure",
          slug: "card-stress",
          description: "A card titled with a hundred-character name, carrying an unbroken-word badge, four paragraphs of pasted prose, a webhook URL and a 130-character email as links, and all twelve hostile actions in its footer; then an unbroken title in a small container."
        ) do
          example("Hostile size and surface matrix", slug: "card-hostile-sizes", layout: :matrix, stress: true) do
            NitroKit::Card::SIZES.product(NitroKit::Card::VARIANTS).each do |size, variant|
              sample("#{size} · #{variant}", slug: "hostile-#{size}-#{variant}") do
                render NitroKit::Card.new(size:, variant:) do |card|
                  card.full { Gallery::Hostile::LONG_WORD }
                  card.header do
                    card.title(Gallery::Hostile::LONG_NAME, level: 3)
                    card.description(Gallery::Hostile::LONG_WORD)
                    card.actions { render NitroKit::Button.new(Gallery::Hostile::ACTION_LABELS.first, size: :sm) }
                  end
                  card.body(Gallery::Hostile::LONG_EMAIL)
                  card.divider
                  card.footer do
                    plain Gallery::Hostile::LONG_URL
                    card.actions { render NitroKit::Button.new(Gallery::Hostile::ACTION_LABELS.last, size: :sm) }
                  end
                end
              end
            end
          end

          example("Hostile record card", slug: "card-hostile", stress: true) do
            render NitroKit::Card.new(id: "gallery-card-hostile") do |card|
              card.title(Gallery::Hostile::LONG_NAME, level: 3)
              card.body do
                render NitroKit::Badge.new(
                  Gallery::Hostile::LONG_WORD,
                  id: "gallery-card-hostile-status",
                  color: :warning,
                  size: :sm
                )
                p { Gallery::Hostile::LONG_PARAGRAPH }
                p { a(href: Gallery::Hostile::LONG_URL) { Gallery::Hostile::LONG_URL } }
                p { a(href: "mailto:#{Gallery::Hostile::LONG_EMAIL}") { Gallery::Hostile::LONG_EMAIL } }
              end
              card.divider
              card.footer do
                render NitroKit::ButtonGroup.new(id: "gallery-card-hostile-actions", label: "Hostile record actions") do |group|
                  Gallery::Hostile::ACTION_LABELS.each_with_index do |label, index|
                    group.button(label, id: "gallery-card-hostile-action-#{index + 1}", size: :sm)
                  end
                end
              end
            end
          end

          example("Hostile title in a small container", slug: "card-hostile-narrow", stress: true) do
            render NitroKit::Container.new(size: :sm, id: "gallery-card-hostile-narrow-container") do
              render NitroKit::Card.new(id: "gallery-card-hostile-narrow") do |card|
                card.title(Gallery::Hostile::LONG_WORD, level: 3)
                card.body(Gallery::Hostile::LONG_EMAIL)
                card.footer(Gallery::Hostile::HUGE_MONEY)
              end
            end
          end
        end
      end
    end
  end
end
