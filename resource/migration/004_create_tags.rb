Sequel.migration do
  up do
    create_table! :tags do
      primary_key :id
    end
  end
  down do
    drop_table :tags
  end
end