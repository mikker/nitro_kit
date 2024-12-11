# frozen_string_literal: true

module NitroKit
  class Theme < Rouge::CSSTheme
    name "nitro"

    extend Rouge::HasModes

    def self.make_light!
      style(Comment, italic: true, fg: "#a1a1aa")
      style(Error, fg: "#b91c1c")
      style(Keyword, bold: true, fg: "#71717a")
      style(Literal::String, italic: true, fg: "#7c3aed")
      style(Name::Function, fg: "#71717a")
      style(Text, fg: "#09090b", bg: "#ffffff")
    end

    def self.make_dark!
      style(Comment, italic: true, fg: "#71717a")
      style(Error, fg: "#b91c1c")
      style(Keyword, bold: true, fg: "#a1a1aa")
      style(Literal::String, italic: true, fg: "#a78bfa")
      style(Name::Function, fg: "#a1a1aa")
      style(Text, fg: "#f4f4f5", bg: "#09090b")
    end

    style Comment::Preproc, italic: false

    style Keyword::Pseudo, bold: false
    style Keyword::Type, bold: false

    style Operator, bold: true

    style Name::Class, bold: true
    style Name::Namespace, bold: true
    style Name::Exception, bold: true
    style Name::Entity, bold: true
    style Name::Tag, bold: true

    style Literal::String::Affix, bold: true
    style Literal::String::Interpol, bold: true
    style Literal::String::Escape, bold: true

    style Generic::Heading, bold: true
    style Generic::Subheading, bold: true
    style Generic::Emph, italic: true
    style Generic::EmphStrong, italic: true, bold: true
    style Generic::Strong, bold: true
    style Generic::Prompt, bold: true

    make_light!
  end
end
