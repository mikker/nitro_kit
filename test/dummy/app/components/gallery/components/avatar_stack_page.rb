module Gallery
  module Components
    class AvatarStackPage < ComponentPage
      private

      def source_note
        "app/components/nitro_kit/avatar_stack.rb"
      end

      def api_note
        "NitroKit::AvatarStack.new(label:, size:, max:) { |stack| stack.avatar; stack.overflow }"
      end

      def component_template
        example_section(
          "Sizes",
          slug: "avatar-stack-sizes",
          description: "The stack owns the size of every nested avatar and its overflow indicator."
        ) do
          example("Size scale", slug: "avatar-stack-size-scale", layout: :matrix) do
            Gallery::Data.avatar_stack_sizes.each do |stack|
              sample(stack.label, slug: stack.slug) do
                render_stack(stack)
              end
            end
          end
        end

        example_section(
          "Overflow counts",
          slug: "avatar-stack-overflow",
          description: "Small, large, and explicitly labelled overflow counts remain readable and announced."
        ) do
          example("Count scale", slug: "avatar-stack-count-scale", layout: :matrix) do
            sample("One more", slug: "one") do
              render_overflow_stack(id: "gallery-avatar-stack-overflow-one", count: 1)
            end
            sample("Nine more", slug: "nine") do
              render_overflow_stack(id: "gallery-avatar-stack-overflow-nine", count: 9)
            end
            sample("128 observers", slug: "large") do
              render_overflow_stack(
                id: "gallery-avatar-stack-overflow-large",
                count: 128,
                label: "128 additional deployment observers"
              )
            end
          end
        end

        example_section(
          "Automatic overflow",
          slug: "avatar-stack-max",
          description: "A max: count keeps the visible avatars bounded and derives the +N indicator."
        ) do
          example("Bounded participants", slug: "avatar-stack-max-participants", layout: :row) do
            render NitroKit::AvatarStack.new(
              id: "gallery-avatar-stack-max",
              size: :md,
              max: 3,
              label: "Workspace participants"
            ) do |stack|
              Gallery::Data.dense_members.first(6).each_with_index do |member, index|
                stack.avatar(alt: member.name, id: "gallery-avatar-stack-max-#{index}")
              end
            end
          end
        end

        example_section(
          "Mixed identities",
          slug: "avatar-stack-content",
          description: "Image, generated fallback, long custom fallback, and overflow compose in one labelled group."
        ) do
          example("Deployment reviewers", slug: "avatar-stack-reviewers", layout: :row) do
            render NitroKit::AvatarStack.new(
              id: "gallery-avatar-stack-reviewers",
              size: :lg,
              label: "Deployment reviewers"
            ) do |stack|
              stack.avatar(
                src: "/gallery/avatars/grace.svg",
                alt: "Grace Hopper",
                fallback: "GH",
                id: "gallery-avatar-stack-image"
              )
              stack.avatar(
                alt: "Ada Lovelace",
                id: "gallery-avatar-stack-generated"
              )
              stack.avatar(
                alt: "Platform engineering team",
                fallback: "TEAM",
                id: "gallery-avatar-stack-long-fallback"
              )
              stack.overflow(3, label: "Three more deployment reviewers")
            end
          end
        end
      end

      def render_stack(stack)
        render NitroKit::AvatarStack.new(
          id: "gallery-avatar-stack-size-#{stack.slug}",
          size: stack.size,
          label: stack.label
        ) do |component|
          component.avatar(
            alt: "Ada Lovelace",
            fallback: "AL",
            id: "gallery-avatar-stack-size-#{stack.slug}-ada"
          )
          component.avatar(
            alt: "Grace Hopper",
            fallback: "GH",
            id: "gallery-avatar-stack-size-#{stack.slug}-grace"
          )
          component.overflow(stack.overflow)
        end
      end

      def render_overflow_stack(id:, count:, label: nil)
        render NitroKit::AvatarStack.new(
          id:,
          size: :md,
          label: "Workspace participants"
        ) do |stack|
          stack.avatar(alt: "Ada Lovelace", fallback: "AL", id: "#{id}-ada")
          stack.overflow(count, label:)
        end
      end
    end
  end
end
