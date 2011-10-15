Sequel.migration do
  up do
    create_table(:authors) do
      primary_key :id
      String :code, :unique => true, :null => false
      String :name, :unique => true, :null => false
      String :mailto
      String :crypted_password, :size => 40
      String :password_salt, :size => 40
      TrueClass :loginable, :null => false, :default => true
    end
  end
  down do
    drop_table(:authors)
  end
end