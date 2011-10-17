Sequel.migration do
  up do
    create_table :author_logs do
      primary_key :id
    end
  end
  down do
    drop_table :author_logs
  end
end