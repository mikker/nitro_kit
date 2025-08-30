# Changelog

## Unreleased

### Fixed

- Fix Select component empty rendering issue with from_template pattern
- Add missing `select` method to FormBuilder for Rails API compatibility

## 0.7.0

### Changed

- Migrate from `builder_method` to `from_template` pattern
- Update Input focus styling to use `focus-visible` for better accessibility
- Improve `text_or_block` method with SafeBuffer handling
- Remove I18n dependency from FormBuilder

### Added

- XL size option for Button component
- `radio_button` method to FormBuilder
- `nk_avatar_stack` helper and component
- Pass options to Combobox in `combobox` method
- Support for rendering fields as custom component classes

### Fixed

- Remove duplicate id from field checkbox hidden field
- Fix checkbox field and textarea rendering
- Add spacing between consecutive fieldsets
- Improve dropdown functionality

## 0.6.0

NB: Nitro Kit has been re-licensed to disallow reselling as is. It is still free to use in your projects you just can't sell copies of it.

### Breaking changes

- Update color definitions and add some more. **You'll need to update the color definitions in your CSS file.** See [Getting Started](https://nitrokit.dev/getting_started)

### Changed

- Update `phlex` and `phlex-rails` dependencies
- Increase button[size=sm] size

### Added

- Badge colors!
- Support for `as:` prop in Dialog
- `align:` prop for table cells

## 0.5.2

Start of this document
