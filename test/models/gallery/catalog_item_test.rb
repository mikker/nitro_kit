require "test_helper"

class GalleryCatalogItemTest < ActiveSupport::TestCase
  test "exposes only the attributes used by the gallery Ransack recipe" do
    assert_equal %w[name owner seats sku status updated_at], Gallery::CatalogItem.ransackable_attributes
    assert_empty Gallery::CatalogItem.ransackable_associations
  end

  test "seeds deterministic valid examples idempotently" do
    Gallery::CatalogItem.delete_all

    2.times { Gallery::CatalogItem.seed_examples! }

    assert_equal Gallery::CatalogItem::EXAMPLES.size, Gallery::CatalogItem.count
    assert Gallery::CatalogItem.find_by!(sku: "NK-1001").valid?
  end
end
