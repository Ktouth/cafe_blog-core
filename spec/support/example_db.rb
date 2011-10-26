ExampleDBDataTables = [:authors, :author_logs]
ExampleDBSeqenceReset = {:authors => true, :author_logs => true}
ExampleDBData = {}
ExampleDBData[:authors] = [
  {:id => 1, :code => 'admin', :name => '管理人', :mailto => 'admin@foobar.biz', },
  {:id => 2, :code => 'foobar', :name => 'フーバー', :mailto => nil, },
  {:id => 3, :code => 'example', :name => 'example', :mailto => 'foobar@example.com', },
  {:id => 4, :code => 'cafe_blog', :name => 'ブログ筆者2385', :mailto => nil, },
  {:id => 5, :code => 'locked_user', :name => 'ログインは許可していない', :mailto => nil, :loginable => false },
  {:id => 6, :code => 'disabled_user', :name => 'このユーザは認識されません', :mailto => nil, :enable => false },
  {:id => 7, :code => 'suspended_user', :name => '無効ユーザのログインは許可していない', :mailto => nil, :enable => false },
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
update_example_db_authors_password('example', 'example1462example')
update_example_db_authors_password('locked_user', 'Locked1User2IS3Invalid4Login')
update_example_db_authors_password('suspended_user', 'ThisUser123456IsSuspended')

ExampleDBData[:author_logs] = [
  {:id => 1, :time => Time.local(2004, 11, 23, 1, 11, 11), :host => '11-09-111-13.host.example.org', :author_id => 1, :action => 'create.author',},
  {:id => 2, :time => Time.local(2005, 7, 11, 8, 12, 20), :host => 'org.this.host-name@11.22.33.44', :action => 'login',},
  {:id => 3, :time => Time.local(2005, 10, 22, 3, 13, 9), :host => 'ppp1111.kumamoto11.qibb.ja', :author_id => 1, :action => 'login',},
  {:id => 4, :time => Time.local(2006, 6, 12, 9, 14, 17), :host => 'ppp1111.kumamoto11.qibb.ja', :author_id => 1, :action => 'post.article',},
  {:id => 5, :time => Time.local(2007, 3, 7,22, 15, 28), :host => 'unknown.host.name', :action => 'login',},
  {:id => 6, :time => Time.local(2009, 7, 5,18, 16, 16), :host => 'ppp1111.kumamoto11.qibb.ja', :author_id => 1, :action => 'post.article',},
  {:id => 7, :time => Time.local(2010, 12, 25,14, 17, 45), :host => '11-09-111-13.host.example.org', :action => 'login',},
  {:id => 8, :time => Time.local(2011, 1, 1,13, 18, 37), :host => 'ppp192-168-0-2.tokyo.org', :author_id => 3, :action => 'login',},
  {:id => 9, :time => Time.local(2011, 2, 21,22, 19, 55), :host => 'unknown.host.name', :action => 'login',},
  {:id => 10, :time => Time.local(2011, 3, 23, 1, 20, 59), :host => 'ppp192-168-0-2.tokyo.org', :author_id => 3, :action => 'post.comment',},
]
