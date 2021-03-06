Sequel.migration do
  up do
    create_table! :tags do
      primary_key :id
      String :name, :unique => true, :null => false
      String :code, :unique => true, :null => true, :default => nil
      foreign_key :group_id, :tags, :on_delete => :set_null, :on_update => :cascade
    end

    self[:tags].insert(:id => 1, :name => '未分類', :code => 'no_group')    
  end
  down do
    drop_table :tags
  end
end