Sequel.migration do
  up do
    create_table! :tags do
      primary_key :id
      String :name, :unique => true, :null => false
      String :code, :unique => true, :null => true, :default => nil
    end
  end
  down do
    drop_table :tags
  end
end