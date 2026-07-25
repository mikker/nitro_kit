class CreateActiveStorageTables < ActiveRecord::Migration[8.1]
  def change
    create_table :active_storage_blobs do |table|
      table.string :key, null: false
      table.string :filename, null: false
      table.string :content_type
      table.text :metadata
      table.string :service_name, null: false
      table.bigint :byte_size, null: false
      table.string :checksum
      table.datetime :created_at, precision: 6, null: false

      table.index [ :key ], unique: true
    end

    create_table :active_storage_attachments do |table|
      table.string :name, null: false
      table.references :record, null: false, polymorphic: true, index: false
      table.references :blob, null: false
      table.datetime :created_at, precision: 6, null: false

      table.index [ :record_type, :record_id, :name, :blob_id ],
        name: :index_active_storage_attachments_uniqueness,
        unique: true
      table.foreign_key :active_storage_blobs, column: :blob_id
    end

    create_table :active_storage_variant_records do |table|
      table.belongs_to :blob, null: false, index: false
      table.string :variation_digest, null: false

      table.index [ :blob_id, :variation_digest ],
        name: :index_active_storage_variant_records_uniqueness,
        unique: true
      table.foreign_key :active_storage_blobs, column: :blob_id
    end
  end
end
