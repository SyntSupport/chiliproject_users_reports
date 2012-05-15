class CreateReports < ActiveRecord::Migration
  def self.up
    create_table :reports do |t|
      t.column :report_date, :datetime
      t.column :report, :text
      t.references :user
      t.column :trash, :boolean
      t.column :comment, :text
      t.column :manager_id, :integer
      
      t.timestamps
    end
  end

  def self.down
    drop_table :reports
  end
end
