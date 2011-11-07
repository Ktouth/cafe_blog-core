Sequel.migration do
  up do
    create_table! :configurations do
      String :key, :unique => true, :null => false, :primary_key => true
      String :values, :null => false
    end
  end
  down do
    drop_table :configurations
  end
end