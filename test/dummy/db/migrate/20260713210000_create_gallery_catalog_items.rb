class CreateGalleryCatalogItems < ActiveRecord::Migration[8.1]
  def change
    create_table :gallery_catalog_items do |table|
      table.string :sku, null: false
      table.string :name, null: false
      table.string :owner, null: false
      table.string :status, null: false
      table.integer :seats, null: false, default: 0
      table.timestamps

      table.index :sku, unique: true
      table.index :status
    end
  end
end
