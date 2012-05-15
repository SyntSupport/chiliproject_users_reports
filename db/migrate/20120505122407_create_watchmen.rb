class CreateWatchmen < ActiveRecord::Migration
  def self.up
    create_table :watchmen do |t|
      t.column :watchman_id, :integer
      t.column :watched_id, :integer
    end
  end

  def self.down
    drop_table :watchmen
  end
end
