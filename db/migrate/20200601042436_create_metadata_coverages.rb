class CreateMetadataCoverages < ActiveRecord::Migration[6.0]
  def change
    create_table :metadata_coverages do |t|
      t.string :key
      t.integer :count
      t.integer :collection_id

      t.timestamps
    end
  end
end
