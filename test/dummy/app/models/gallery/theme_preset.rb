# frozen_string_literal: true

module Gallery
  class ThemePreset < ::Data.define(:accent, :neutral, :radius, :density, :font, :shell)
    VERSION = 1
    PARAMETER_ORDER = %i[v accent neutral radius density font shell].freeze
    ATTRIBUTES = %i[accent neutral radius density font shell].freeze
    CHOICES = {
      accent: %i[blue indigo violet rose amber emerald neutral].freeze,
      neutral: %i[slate gray zinc neutral stone].freeze,
      radius: %i[none sm md lg].freeze,
      density: %i[compact comfortable].freeze,
      font: %i[system humanist serif mono].freeze,
      shell: %i[sidebar topbar hybrid].freeze
    }.freeze
    DEFAULTS = {
      accent: :blue,
      neutral: :zinc,
      radius: :md,
      density: :comfortable,
      font: :system,
      shell: :sidebar
    }.freeze

    ParseResult = ::Data.define(:preset, :errors)

    class << self
      def parse(parameters)
        values = parameters.respond_to?(:to_h) ? parameters.to_h : {}
        values = values.stringify_keys

        if values.key?("v") && values["v"].to_s != VERSION.to_s
          return ParseResult.new(
            preset: new,
            errors: [ "This preset version is not supported. Version #{VERSION} defaults were restored." ].freeze
          )
        end

        errors = []
        attributes = ATTRIBUTES.to_h do |attribute|
          raw_value = values[attribute.to_s]
          choice = choice_from(raw_value)

          if raw_value.nil? || CHOICES.fetch(attribute).include?(choice)
            [ attribute, choice || DEFAULTS.fetch(attribute) ]
          else
            errors << "#{attribute.to_s.humanize} is not supported. The default was restored."
            [ attribute, DEFAULTS.fetch(attribute) ]
          end
        end

        ParseResult.new(preset: new(**attributes), errors: errors.freeze)
      end

      def schema
        @schema ||= deep_freeze(
          version: VERSION,
          parameterOrder: PARAMETER_ORDER.map(&:to_s),
          attributes: ATTRIBUTES.map(&:to_s),
          defaults: DEFAULTS.transform_values(&:to_s),
          choices: CHOICES.transform_values { |choices| choices.map(&:to_s) },
          baselines: BASELINES,
          tokenMaps: TOKEN_MAPS,
          shellExamples: CHOICES.fetch(:shell).to_h do |shell|
            [ shell.to_s, new(shell:).app_shell_ruby ]
          end
        )
      end

      private

      def choice_from(value)
        value.to_sym if value.is_a?(String) && value.present?
      end

      def deep_freeze(value)
        case value
        when Hash
          value.each { |key, child| deep_freeze(key); deep_freeze(child) }
        when Array
          value.each { |child| deep_freeze(child) }
        end

        value.freeze
      end
    end

    BASELINES = deep_freeze(
      shared: {
        "--nk-control-height-lg" => "2.75rem",
        "--nk-control-height-md" => "2.5rem",
        "--nk-control-height-sm" => "1.75rem",
        "--nk-control-height-xl" => "3.5rem",
        "--nk-control-height-xs" => "1.5rem",
        "--nk-font-sans" => 'ui-sans-serif, system-ui, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji"',
        "--nk-radius-lg" => "0.5rem",
        "--nk-radius-md" => "0.375rem",
        "--nk-radius-sm" => "0.25rem",
        "--nk-radius-xl" => "0.75rem",
        "--nk-radius-xs" => "0.125rem",
        "--nk-space" => "0.25rem"
      },
      light: {
        "--nk-color-border" => "oklch(0.92 0.004 286.32)",
        "--nk-color-canvas" => "oklch(1 0 0)",
        "--nk-color-elevated" => "oklch(0.985 0 0)",
        "--nk-color-focus" => "oklch(0.546 0.245 262.881)",
        "--nk-color-foreground" => "oklch(0.21 0.006 285.885)",
        "--nk-color-muted" => "oklch(0.967 0.001 286.375)",
        "--nk-color-muted-foreground" => "oklch(0.552 0.016 285.938)",
        "--nk-color-neutral" => "oklch(0.552 0.016 285.938)",
        "--nk-color-neutral-content" => "oklch(0.37 0.013 285.805)",
        "--nk-color-primary" => "oklch(0.274 0.006 286.033)",
        "--nk-color-primary-foreground" => "oklch(1 0 0)",
        "--nk-color-surface" => "oklch(1 0 0)"
      },
      dark: {
        "--nk-color-border" => "oklch(0.37 0.013 285.805)",
        "--nk-color-canvas" => "oklch(0.141 0.005 285.823)",
        "--nk-color-elevated" => "oklch(0.21 0.006 285.885)",
        "--nk-color-focus" => "oklch(0.488 0.243 264.376)",
        "--nk-color-foreground" => "oklch(0.967 0.001 286.375)",
        "--nk-color-muted" => "oklch(0.274 0.006 286.033)",
        "--nk-color-muted-foreground" => "oklch(0.705 0.015 286.067)",
        "--nk-color-neutral" => "oklch(0.705 0.015 286.067)",
        "--nk-color-neutral-content" => "oklch(0.92 0.004 286.32)",
        "--nk-color-primary" => "oklch(1 0 0)",
        "--nk-color-primary-foreground" => "oklch(0.274 0.006 286.033)",
        "--nk-color-surface" => "oklch(0.178 0.006 285.885)"
      }
    )

    TOKEN_MAPS = deep_freeze(
      accent: {
        blue: {
          light: {
            "--nk-color-focus" => "oklch(0.546 0.245 262.881)",
            "--nk-color-primary" => "oklch(0.546 0.245 262.881)",
            "--nk-color-primary-foreground" => "oklch(0.985 0 0)"
          },
          dark: {
            "--nk-color-focus" => "oklch(0.64 0.214 259.815)",
            "--nk-color-primary" => "oklch(0.64 0.214 259.815)",
            "--nk-color-primary-foreground" => "oklch(0.141 0.005 285.823)"
          }
        },
        indigo: {
          light: {
            "--nk-color-focus" => "oklch(0.511 0.262 276.966)",
            "--nk-color-primary" => "oklch(0.511 0.262 276.966)",
            "--nk-color-primary-foreground" => "oklch(0.985 0 0)"
          },
          dark: {
            "--nk-color-focus" => "oklch(0.673 0.182 276.935)",
            "--nk-color-primary" => "oklch(0.673 0.182 276.935)",
            "--nk-color-primary-foreground" => "oklch(0.141 0.005 285.823)"
          }
        },
        violet: {
          light: {
            "--nk-color-focus" => "oklch(0.541 0.281 293.009)",
            "--nk-color-primary" => "oklch(0.541 0.281 293.009)",
            "--nk-color-primary-foreground" => "oklch(0.985 0 0)"
          },
          dark: {
            "--nk-color-focus" => "oklch(0.702 0.183 293.541)",
            "--nk-color-primary" => "oklch(0.702 0.183 293.541)",
            "--nk-color-primary-foreground" => "oklch(0.141 0.005 285.823)"
          }
        },
        rose: {
          light: {
            "--nk-color-focus" => "oklch(0.56 0.253 17.585)",
            "--nk-color-primary" => "oklch(0.56 0.253 17.585)",
            "--nk-color-primary-foreground" => "oklch(0.985 0 0)"
          },
          dark: {
            "--nk-color-focus" => "oklch(0.712 0.194 13.428)",
            "--nk-color-primary" => "oklch(0.712 0.194 13.428)",
            "--nk-color-primary-foreground" => "oklch(0.141 0.005 285.823)"
          }
        },
        amber: {
          light: {
            "--nk-color-focus" => "oklch(0.666 0.179 58.318)",
            "--nk-color-primary" => "oklch(0.666 0.179 58.318)",
            "--nk-color-primary-foreground" => "oklch(0.21 0.006 285.885)"
          },
          dark: {
            "--nk-color-focus" => "oklch(0.769 0.188 70.08)",
            "--nk-color-primary" => "oklch(0.769 0.188 70.08)",
            "--nk-color-primary-foreground" => "oklch(0.141 0.005 285.823)"
          }
        },
        emerald: {
          light: {
            "--nk-color-focus" => "oklch(0.527 0.154 150.069)",
            "--nk-color-primary" => "oklch(0.527 0.154 150.069)",
            "--nk-color-primary-foreground" => "oklch(0.985 0 0)"
          },
          dark: {
            "--nk-color-focus" => "oklch(0.696 0.17 162.48)",
            "--nk-color-primary" => "oklch(0.696 0.17 162.48)",
            "--nk-color-primary-foreground" => "oklch(0.141 0.005 285.823)"
          }
        },
        neutral: {
          light: {
            "--nk-color-focus" => "oklch(0.439 0 0)",
            "--nk-color-primary" => "oklch(0.269 0 0)",
            "--nk-color-primary-foreground" => "oklch(0.97 0 0)"
          },
          dark: {
            "--nk-color-focus" => "oklch(0.708 0 0)",
            "--nk-color-primary" => "oklch(0.985 0 0)",
            "--nk-color-primary-foreground" => "oklch(0.205 0 0)"
          }
        }
      },
      neutral: {
        slate: {
          light: {
            "--nk-color-border" => "oklch(0.929 0.013 255.508)",
            "--nk-color-canvas" => "oklch(0.984 0.003 247.858)",
            "--nk-color-elevated" => "oklch(0.968 0.007 247.896)",
            "--nk-color-foreground" => "oklch(0.208 0.042 265.755)",
            "--nk-color-muted" => "oklch(0.968 0.007 247.896)",
            "--nk-color-muted-foreground" => "oklch(0.554 0.046 257.417)",
            "--nk-color-neutral" => "oklch(0.554 0.046 257.417)",
            "--nk-color-neutral-content" => "oklch(0.372 0.044 257.287)",
            "--nk-color-surface" => "oklch(1 0 0)"
          },
          dark: {
            "--nk-color-border" => "oklch(0.372 0.044 257.287)",
            "--nk-color-canvas" => "oklch(0.129 0.042 264.695)",
            "--nk-color-elevated" => "oklch(0.279 0.041 260.031)",
            "--nk-color-foreground" => "oklch(0.968 0.007 247.896)",
            "--nk-color-muted" => "oklch(0.279 0.041 260.031)",
            "--nk-color-muted-foreground" => "oklch(0.704 0.04 256.788)",
            "--nk-color-neutral" => "oklch(0.704 0.04 256.788)",
            "--nk-color-neutral-content" => "oklch(0.929 0.013 255.508)",
            "--nk-color-surface" => "oklch(0.208 0.042 265.755)"
          }
        },
        gray: {
          light: {
            "--nk-color-border" => "oklch(0.928 0.006 264.531)",
            "--nk-color-canvas" => "oklch(0.985 0.002 247.839)",
            "--nk-color-elevated" => "oklch(0.967 0.003 264.542)",
            "--nk-color-foreground" => "oklch(0.21 0.034 264.665)",
            "--nk-color-muted" => "oklch(0.967 0.003 264.542)",
            "--nk-color-muted-foreground" => "oklch(0.551 0.027 264.364)",
            "--nk-color-neutral" => "oklch(0.551 0.027 264.364)",
            "--nk-color-neutral-content" => "oklch(0.373 0.034 259.733)",
            "--nk-color-surface" => "oklch(1 0 0)"
          },
          dark: {
            "--nk-color-border" => "oklch(0.373 0.034 259.733)",
            "--nk-color-canvas" => "oklch(0.13 0.028 261.692)",
            "--nk-color-elevated" => "oklch(0.278 0.033 256.848)",
            "--nk-color-foreground" => "oklch(0.967 0.003 264.542)",
            "--nk-color-muted" => "oklch(0.278 0.033 256.848)",
            "--nk-color-muted-foreground" => "oklch(0.707 0.022 261.325)",
            "--nk-color-neutral" => "oklch(0.707 0.022 261.325)",
            "--nk-color-neutral-content" => "oklch(0.928 0.006 264.531)",
            "--nk-color-surface" => "oklch(0.21 0.034 264.665)"
          }
        },
        zinc: {
          light: BASELINES.fetch(:light).slice(*%w[
            --nk-color-border --nk-color-canvas --nk-color-elevated --nk-color-foreground
            --nk-color-muted --nk-color-muted-foreground --nk-color-neutral
            --nk-color-neutral-content --nk-color-surface
          ]),
          dark: BASELINES.fetch(:dark).slice(*%w[
            --nk-color-border --nk-color-canvas --nk-color-elevated --nk-color-foreground
            --nk-color-muted --nk-color-muted-foreground --nk-color-neutral
            --nk-color-neutral-content --nk-color-surface
          ])
        },
        neutral: {
          light: {
            "--nk-color-border" => "oklch(0.922 0 0)",
            "--nk-color-canvas" => "oklch(0.985 0 0)",
            "--nk-color-elevated" => "oklch(0.97 0 0)",
            "--nk-color-foreground" => "oklch(0.205 0 0)",
            "--nk-color-muted" => "oklch(0.97 0 0)",
            "--nk-color-muted-foreground" => "oklch(0.556 0 0)",
            "--nk-color-neutral" => "oklch(0.556 0 0)",
            "--nk-color-neutral-content" => "oklch(0.371 0 0)",
            "--nk-color-surface" => "oklch(1 0 0)"
          },
          dark: {
            "--nk-color-border" => "oklch(0.371 0 0)",
            "--nk-color-canvas" => "oklch(0.145 0 0)",
            "--nk-color-elevated" => "oklch(0.269 0 0)",
            "--nk-color-foreground" => "oklch(0.97 0 0)",
            "--nk-color-muted" => "oklch(0.269 0 0)",
            "--nk-color-muted-foreground" => "oklch(0.708 0 0)",
            "--nk-color-neutral" => "oklch(0.708 0 0)",
            "--nk-color-neutral-content" => "oklch(0.922 0 0)",
            "--nk-color-surface" => "oklch(0.205 0 0)"
          }
        },
        stone: {
          light: {
            "--nk-color-border" => "oklch(0.923 0.003 48.717)",
            "--nk-color-canvas" => "oklch(0.985 0.001 106.423)",
            "--nk-color-elevated" => "oklch(0.97 0.001 106.424)",
            "--nk-color-foreground" => "oklch(0.216 0.006 56.043)",
            "--nk-color-muted" => "oklch(0.97 0.001 106.424)",
            "--nk-color-muted-foreground" => "oklch(0.553 0.013 58.071)",
            "--nk-color-neutral" => "oklch(0.553 0.013 58.071)",
            "--nk-color-neutral-content" => "oklch(0.374 0.01 67.558)",
            "--nk-color-surface" => "oklch(1 0 0)"
          },
          dark: {
            "--nk-color-border" => "oklch(0.374 0.01 67.558)",
            "--nk-color-canvas" => "oklch(0.147 0.004 49.25)",
            "--nk-color-elevated" => "oklch(0.268 0.007 34.298)",
            "--nk-color-foreground" => "oklch(0.97 0.001 106.424)",
            "--nk-color-muted" => "oklch(0.268 0.007 34.298)",
            "--nk-color-muted-foreground" => "oklch(0.709 0.01 56.259)",
            "--nk-color-neutral" => "oklch(0.709 0.01 56.259)",
            "--nk-color-neutral-content" => "oklch(0.923 0.003 48.717)",
            "--nk-color-surface" => "oklch(0.216 0.006 56.043)"
          }
        }
      },
      radius: {
        none: {
          shared: {
            "--nk-radius-lg" => "0",
            "--nk-radius-md" => "0",
            "--nk-radius-sm" => "0",
            "--nk-radius-xl" => "0",
            "--nk-radius-xs" => "0"
          }
        },
        sm: {
          shared: {
            "--nk-radius-lg" => "0.375rem",
            "--nk-radius-md" => "0.25rem",
            "--nk-radius-sm" => "0.125rem",
            "--nk-radius-xl" => "0.5rem",
            "--nk-radius-xs" => "0.0625rem"
          }
        },
        md: { shared: BASELINES.fetch(:shared).slice(*%w[
          --nk-radius-lg --nk-radius-md --nk-radius-sm --nk-radius-xl --nk-radius-xs
        ]) },
        lg: {
          shared: {
            "--nk-radius-lg" => "0.75rem",
            "--nk-radius-md" => "0.5rem",
            "--nk-radius-sm" => "0.375rem",
            "--nk-radius-xl" => "1rem",
            "--nk-radius-xs" => "0.25rem"
          }
        }
      },
      density: {
        compact: {
          shared: {
            "--nk-control-height-lg" => "2.5rem",
            "--nk-control-height-md" => "2.25rem",
            "--nk-control-height-sm" => "1.625rem",
            "--nk-control-height-xl" => "3rem",
            "--nk-control-height-xs" => "1.375rem",
            "--nk-space" => "0.2rem"
          }
        },
        comfortable: { shared: BASELINES.fetch(:shared).slice(*%w[
          --nk-control-height-lg --nk-control-height-md --nk-control-height-sm
          --nk-control-height-xl --nk-control-height-xs --nk-space
        ]) }
      },
      font: {
        system: { shared: { "--nk-font-sans" => BASELINES.fetch(:shared).fetch("--nk-font-sans") } },
        humanist: { shared: { "--nk-font-sans" => 'Optima, Candara, "Noto Sans", source-sans-pro, sans-serif' } },
        serif: { shared: { "--nk-font-sans" => 'ui-serif, Georgia, Cambria, "Times New Roman", Times, serif' } },
        mono: { shared: { "--nk-font-sans" => "var(--nk-font-mono)" } }
      },
      shell: {
        sidebar: {},
        topbar: {},
        hybrid: {}
      }
    )

    def initialize(
      accent: DEFAULTS.fetch(:accent),
      neutral: DEFAULTS.fetch(:neutral),
      radius: DEFAULTS.fetch(:radius),
      density: DEFAULTS.fetch(:density),
      font: DEFAULTS.fetch(:font),
      shell: DEFAULTS.fetch(:shell)
    )
      values = { accent:, neutral:, radius:, density:, font:, shell: }
      values.each do |attribute, value|
        unless CHOICES.fetch(attribute).include?(value)
          raise ArgumentError, "Unsupported #{attribute}: #{value.inspect}"
        end
      end

      super(**values)
    end

    def query_parameters
      {
        "v" => VERSION.to_s,
        "accent" => accent.to_s,
        "neutral" => neutral.to_s,
        "radius" => radius.to_s,
        "density" => density.to_s,
        "font" => font.to_s,
        "shell" => shell.to_s
      }.freeze
    end

    def query_string
      Rack::Utils.build_query(query_parameters)
    end

    def css
      light_tokens = export_tokens(:light)
      dark_tokens = export_tokens(:dark)

      [
        css_block(':root, [data-theme="light"]', light_tokens),
        system_css_block(dark_tokens),
        css_block('[data-theme="dark"]', dark_tokens)
      ].join("\n\n")
    end

    def preview_css(selector: '[data-gallery="theme-preview"]')
      css_block(selector, preview_tokens(:light)) +
        "\n\n" +
        css_block(%(#{selector}[data-theme="dark"]), preview_tokens(:dark))
    end

    def app_shell_ruby
      <<~RUBY.chomp
        render NitroKit::AppShell.new(id: "workspace", layout: :#{shell}) do |shell|
          shell.brand { strong { "Northstar" } }

          shell.navigation do
            render NitroKit::AppNavigation.new(label: "Primary navigation") do |navigation|
              navigation.body do
                navigation.item("Overview", href: root_path, icon: :house, current: true)
                navigation.item("Projects", href: projects_path, icon: :folder)
                navigation.spacer
                navigation.item("Settings", href: settings_path, icon: :settings)
              end
            end
          end

          shell.topbar do
            render NitroKit::Button.new("New project", href: new_project_path, variant: :primary)
          end

          shell.main { render Workspace::Dashboard.new }
        end
      RUBY
    end

    private

    def export_tokens(appearance)
      if appearance == :light
        tokens = shared_tokens.merge(appearance_tokens(:light))
        baseline = BASELINES.fetch(:shared).merge(BASELINES.fetch(:light))

        return tokens.reject { |name, value| baseline[name] == value }.sort.to_h
      end

      tokens = appearance_tokens(:dark)
      baseline = BASELINES.fetch(:dark)
      light_changes = appearance_tokens(:light).reject do |name, value|
        BASELINES.fetch(:light)[name] == value
      end.keys

      tokens.select { |name, value| baseline[name] != value || light_changes.include?(name) }.sort.to_h
    end

    def preview_tokens(appearance)
      shared_tokens.merge(appearance_tokens(appearance)).sort.to_h
    end

    def shared_tokens
      %i[radius density font].each_with_object({}) do |attribute, tokens|
        tokens.merge!(TOKEN_MAPS.fetch(attribute).fetch(public_send(attribute)).fetch(:shared))
      end
    end

    def appearance_tokens(appearance)
      %i[neutral accent].each_with_object({}) do |attribute, tokens|
        tokens.merge!(TOKEN_MAPS.fetch(attribute).fetch(public_send(attribute)).fetch(appearance))
      end
    end

    def css_block(selector, tokens)
      declarations = tokens.sort.map { |name, value| "  #{name}: #{value};" }
      ([ "#{selector} {" ] + declarations + [ "}" ]).join("\n")
    end

    def system_css_block(tokens)
      declarations = tokens.sort.map { |name, value| "    #{name}: #{value};" }

      ([
        "@media (prefers-color-scheme: dark) {",
        "  :root:not([data-theme]) {"
      ] + declarations + [ "  }", "}" ]).join("\n")
    end
  end
end
