Sequel.migration do
  up do
    create_table(:authors) do
      primary_key :id
      String :code, :unique => true, :null => false
      String :name, :unique => true, :null => false
      String :mailto
    end
  end
  down do
    drop_table(:authors)
  end
end