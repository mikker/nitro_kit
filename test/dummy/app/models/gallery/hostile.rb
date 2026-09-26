module Gallery
  # Worst-case content for the gallery's stress examples.
  #
  # Every value here is deliberately hostile: unbroken words, overlong
  # identifiers, mixed scripts, extreme magnitudes, and far more items than a
  # component was designed around. Stress examples (`example(..., stress: true)`)
  # compose from this module so `test/system/stress_sweep_test.rb` can prove
  # that nothing paints outside its box, clips text mid-letter, or scrolls the
  # document sideways.
  #
  # When a "try to break it" session finds new content that breaks a
  # component, add the content here and use it in a stress example. The
  # finding then stays a regression test instead of a note.
  module Hostile
    # Unbroken words defeat wrapping; only overflow-wrap or ellipsis can help.
    LONG_WORD = "Wolfeschlegelsteinhausenbergerdorffwelchevoralternwarengewissenhaftschaferswessenschafewarenwohlgepflege".freeze
    LONG_SLUG = "analytical-engines-research-and-production-eu-west-2-primary-replica-failover-candidate-2026".freeze
    LONG_URL = "https://enterprise-holdings-international.example/workspaces/analytical-engines-research-and-production/settings/integrations/webhooks/deliveries/whd_01J8ZK3Q9W7RX2M5N6P8T4V1Y0/attempts/3?include=headers,body,response&expand=endpoint.owner".freeze

    # Identities
    LONG_NAME = "Dr. Maximiliana Wolfeschlegelsteinhausenbergerdorff-Featherstonehaugh von Hohenzollern-Sigmaringen III".freeze
    LONG_EMAIL = "maximiliana.wolfeschlegelsteinhausenbergerdorff+billing.notifications.eu-west-2026@finance.department.enterprise-holdings-international.example".freeze
    UNICODE_EMAIL = "ünïcödé.tëst+ß@exämple-bücher.test".freeze
    IDN_EMAIL = "用户@例子.广告".freeze
    RTL_NAME = "محمد عبد الرحمن الهاشمي القحطاني".freeze
    CJK_NAME = "山田太郎（プラットフォームエンジニアリング）".freeze
    THAI_NAME = "สวัสดีครับยินดีต้อนรับสู่ระบบจัดการทีมงานของเรา".freeze
    EMOJI_NAME = "🦄 Unicorn Ops 🚀🔥💯 On-call".freeze
    ZERO_WIDTH_NAME = "Zero​width‍joined⁠name﻿here".freeze
    COMBINING_NAME = "Ạ̈ḅ̈c̣̈ D̷̢i̶a̸c̵r̷i̶t̸i̵c̷s̶".freeze
    SINGLE_LETTER_NAME = "X".freeze

    NAMES = [
      LONG_NAME,
      LONG_WORD,
      RTL_NAME,
      CJK_NAME,
      THAI_NAME,
      EMOJI_NAME,
      ZERO_WIDTH_NAME,
      COMBINING_NAME,
      SINGLE_LETTER_NAME
    ].freeze

    EMAILS = [
      LONG_EMAIL,
      UNICODE_EMAIL,
      IDN_EMAIL,
      "a@b.co",
      "#{LONG_WORD.downcase}@#{LONG_WORD.downcase}.example"
    ].freeze

    # Magnitudes
    HUGE_NUMBER = 2_147_483_647_000
    HUGE_FORMATTED = "2,147,483,647,000".freeze
    HUGE_MONEY = "$9,999,999,999,999.99".freeze
    NEGATIVE_MONEY = "−$1,234,567.89".freeze
    TINY_PERCENT = "0.000001%".freeze
    FAR_DATE = Date.new(2999, 12, 31)
    EPOCH_DATE = Date.new(1970, 1, 1)

    # Prose
    LONG_LABEL = "Regional data residency, retention, and lawful-basis preferences for every workspace".freeze
    LONG_SENTENCE = "This description keeps going well past the point where a sensible product would have stopped, " \
      "because real customers paste release notes, legal disclaimers, and entire support tickets into fields " \
      "that were designed for a single line of text.".freeze
    LONG_PARAGRAPH = ([ LONG_SENTENCE ] * 4).join(" ").freeze
    LONG_ERROR = "must be between 3 and 64 characters, may only contain letters, numbers, hyphens, and underscores, " \
      "must not start or end with a hyphen, and must not collide with a reserved workspace slug such as admin, api, or www".freeze

    # Cardinality
    TAB_LABELS = [
      "General", LONG_LABEL, "Members", "Security & compliance", LONG_WORD, "Billing", "Integrations",
      "Webhooks", "API credentials", "Audit log", "Data residency", "Single sign-on", "SCIM provisioning",
      "Domains", "Branding", "Notifications", "Import & export", "Legal", "Danger zone", CJK_NAME,
      RTL_NAME, EMOJI_NAME, "Legacy", "Experimental"
    ].freeze

    BADGE_LABELS = [
      "Active", LONG_LABEL, "Invited", LONG_WORD, "Suspended", RTL_NAME, "Pending review", CJK_NAME,
      "Owner", EMOJI_NAME, "Read-only", HUGE_FORMATTED, "Beta", THAI_NAME, "Deprecated", "1", "999+",
      "Awaiting payment confirmation from the issuing bank", "Trial", "Enterprise", "Past due",
      "Archived", "Locked", "Verified", "Unverified", "Disabled", "Draft", "Scheduled", "Failed", "Queued"
    ].freeze

    ACTION_LABELS = [
      "Save", "Save and continue editing", LONG_LABEL, "Discard", "Duplicate", "Archive", "Export as CSV",
      "Export as JSON", "Transfer ownership", "Regenerate credentials", "Delete permanently", LONG_WORD
    ].freeze

    # Every badge label as a `[label, value]` choice for selects and groups.
    CHOICES = BADGE_LABELS.each_with_index.map { |label, index| [ label, "hostile_#{index}" ] }.freeze

    # Explicit avatar fallbacks up to the four-character contract limit.
    INITIALS = %w[AL GH KJ TEAM BOT 山田 محمد 🦄].freeze

    NAVIGATION_LABELS = [
      "Dashboard", LONG_LABEL, "Members", LONG_WORD, "Billing and invoices", "Webhook deliveries",
      "API credentials and rotation policy", "Audit log", CJK_NAME, RTL_NAME, EMOJI_NAME, "Data residency",
      "Single sign-on", "SCIM provisioning", "Domains", "Branding", "Notifications", "Import and export",
      "Legal", "Settings"
    ].freeze

    class << self
      # Members whose names and emails cycle through every hostile identity.
      def members(count = 40)
        Array.new(count) do |index|
          Gallery::Data::Member.new(
            id: "mem_hostile_#{index}",
            name: NAMES[index % NAMES.size],
            email: EMAILS[index % EMAILS.size],
            role: %i[owner admin member][index % 3],
            status: index % 4 == 3 ? :invited : :active,
            avatar_url: nil,
            joined_on: index.even? ? FAR_DATE : EPOCH_DATE
          )
        end
      end
    end
  end
end
