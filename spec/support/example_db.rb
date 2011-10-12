ExampleDBDataTables = [:authors]
ExampleDBSeqenceReset = {:authors => true}
ExampleDBData = {}
ExampleDBData[:authors] = [
  {:id => 1, :code => 'admin', :name => '管理人', :mailto => 'admin@foobar.biz', },
  {:id => 2, :code => 'foobar', :name => 'フーバー', :mailto => nil, },
  {:id => 3, :code => 'example', :name => 'example', :mailto => 'foobar@example.com', },
  {:id => 4, :code => 'cafe_blog', :name => 'ブログ筆者2385', :mailto => nil, },
]

ExampleDBAuthorsPassword = {}
def create_sample_salt; ('0123456789abcdef' * 10).split(//).shuffle[0,40].join end
def create_sample_password(code, password, salt); Digest::SHA1.hexdigest([code, password, salt].join(':')) end 
def update_example_db_authors_password(code, password)
  require 'digest/sha1'
  
  hash = ExampleDBData[:authors].find {|x| x[:code] == code }
  raise ArguementError, 'code:%sに対応する筆者がいません' % code unless hash
  salt = create_sample_salt 
  crypted = create_sample_password(code, password, salt)
  hash.merge!(:crypted_password => crypted, :password_salt => salt)

  ExampleDBAuthorsPassword[code] = {:password => password, :salt => salt}
end

update_example_db_authors_password('admin', 'pass159354word')
update_example_db_authors_password('example', 'example_1462_example')
