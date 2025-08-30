# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Nitro Kit is a Ruby gem providing generic UI components for Ruby on Rails applications. It uses Phlex for component rendering, Tailwind CSS for styling, and Stimulus.js for JavaScript behaviors.

## Common Development Commands

### Development Server

- `bin/dev` - Start development server on port 3031
- Visit http://localhost:3031/tests to see all component examples

### Testing

- `bin/rails test` - Run the test suite
- `rake app:test:db` - Run tests with database reset
- `rake app:test` - Run all tests

### Building & Releasing

- `rake build` - Build the gem
- `rake install:local` - Install gem locally
- `rake release` - Release to RubyGems

### Tailwind CSS

- `rake app:tailwindcss:build` - Build CSS
- `rake app:tailwindcss:watch` - Watch for CSS changes

### View All Tasks

- `rake -T` - List all available rake tasks

## Architecture

### Component Pattern

All components inherit from `NitroKit::Component` (which extends `Phlex::HTML`) and follow this structure:

```ruby
class ComponentName < Component
  def initialize(params, **attrs)
    # Store parameters, merge attributes
    super(**attrs_with_defaults(attrs))
  end

  def view_template
    # Main rendering logic
  end

  builder_method def part_name
    # Nested component parts
  end
end
```

### Key Architectural Principles

1. **Phlex-Based Rendering**: Components use Phlex::HTML for Ruby-based templating
2. **TailwindMerge Integration**: CSS classes are intelligently merged to prevent conflicts
3. **Stimulus Controllers**: Interactive behavior uses minimal JavaScript with naming convention `nk--{component-name}`
4. **Builder Methods**: Components use builder pattern for composable nested parts
5. **Rails Integration**: Each component has a corresponding helper module (e.g., `nk_button` for `Button` component)

### Form Builder

Custom `NitroKit::FormBuilder` extends Rails' form builder to automatically use NitroKit components for form fields. Access via `form.nk` namespace in forms.

### File Organization

- `app/components/nitro_kit/` - Component classes
- `app/helpers/nitro_kit/` - Rails helper modules
- `app/javascript/controllers/nk/` - Stimulus controllers
- `test/dummy/` - Dummy Rails app for testing/development

### Adding New Components

Use the generator: `rails generate nitro_kit:component ComponentName`

### Testing Components

1. Add example view in `test/dummy/app/views/tests/examples/`
2. Component will appear in development server at http://localhost:3031/tests
3. Write integration tests in `test/integration/`

### CSS Architecture

- Uses Tailwind utility classes with CSS custom properties for theming
- Dark mode support via Tailwind's dark variant
- Theme colors defined as CSS variables (--foreground, --background, --border, etc.)
- Component styles encapsulated in private methods (base_class, variant_class, size_class)

### JavaScript Pattern

- Minimal Stimulus controllers for UI interactions only
- Data attributes follow pattern: `data-nk--{component}-target` and `data-action`
- External libraries (floating-ui, etc.) integrated via importmaps or package manager
