Sequel.migration do
  up do
    create_table :author_logs do
      primary_key :id
      Time :time, :null => false
      String :host, :null => false
      foreign_key :author_id, :authors, :on_delete => :set_null, :on_update => :cascade
    end
  end
  down do
    drop_table :author_logs
  end
end