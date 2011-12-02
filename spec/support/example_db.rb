ExampleDBDataTables = [:authors, :author_logs, :configurations, :tags]
ExampleDBSeqenceReset = {:authors => true, :author_logs => true, :configurations => true, :tags => true}
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
  {:id => 1, :time => Time.local(2004, 11, 23, 1, 11, 11), :host => '11-09-111-13.host.example.org', :author_id => 1, :action => 'create.author', :detail => 'author "example" created.',},
  {:id => 2, :time => Time.local(2005, 7, 11, 8, 12, 20), :host => 'org.this.host-name@11.22.33.44', :action => 'login', :detail => 'login password is invalid.',},
  {:id => 3, :time => Time.local(2005, 10, 22, 3, 13, 9), :host => 'ppp1111.kumamoto11.qibb.ja', :author_id => 1, :action => 'login', :detail => 'login is successed.',},
  {:id => 4, :time => Time.local(2006, 6, 12, 9, 14, 17), :host => 'ppp1111.kumamoto11.qibb.ja', :author_id => 1, :action => 'post.article', :detail => 'article "サンプルアーティクル"(id: 1) posted.',},
  {:id => 5, :time => Time.local(2007, 3, 7,22, 15, 28), :host => 'unknown.host.name', :action => 'login', :detail => 'code "unknown" is not found.',},
  {:id => 6, :time => Time.local(2009, 7, 5,18, 16, 16), :host => 'ppp1111.kumamoto11.qibb.ja', :author_id => 1, :action => 'post.article', :detail => 'article "テスト日記"(id: 2) posted.',},
  {:id => 7, :time => Time.local(2010, 12, 25,14, 17, 45), :host => '11-09-111-13.host.example.org', :action => 'login', :detail => 'code "unknown" is not found.',},
  {:id => 8, :time => Time.local(2011, 1, 1,13, 18, 37), :host => 'ppp192-168-0-2.tokyo.org', :author_id => 3, :action => 'login', :detail => 'login is successed.',},
  {:id => 9, :time => Time.local(2011, 2, 21,22, 19, 55), :host => 'unknown.host.name', :action => 'login.failed', :detail => 'code "unknown" is not found.',},
  {:id => 10, :time => Time.local(2011, 3, 23, 1, 20, 59), :host => 'ppp192-168-0-2.tokyo.org', :author_id => 3, :action => 'post.comment', :detail => 'article "サンプルアーティクル"(id: 1) comment posted(id: 1).',},
]

ExampleDBData[:configurations] = []
ExampleDBConfigurationData = {
  'example' => {:foo => true, :bar => 'this is foobarbaz', :baz => [:Test, :Data]},
}
['example'].each do |key|
  values = ExampleDBConfigurationData[key]
  ExampleDBData[:configurations].push(:key => key, :values => Marshal.dump(values))
end

ExampleDBData[:tags] = [
  {:id => 1, :name => '未分類', :code => 'no_group',},
    {:id => 7, :name => 'テスト',},
    {:id => 8, :name => 'いぐざんぽー',},
    {:id => 13, :name => 'example',},
    {:id => 16, :name => 'tag',},
    {:id => 9, :name => 'unknown', :code => 'unknown',},
  {:id => 10, :name => '文書',},
  {:id => 11, :name => '実務',},
  {:id => 2, :name => '記',},
    {:id => 5, :name => '日記', :code => 'diary',},
    {:id => 14, :name => '自分メモ',},
    {:id => 15, :name => 'twitter', :code => 'twitter',},
    {:id => 6, :name => 'facebook',},
  {:id => 3, :name => 'ライブラリ', :code => 'library',},
  {:id => 4, :name => 'ゲーム',},
    {:id => 12, :name => 'アニメ化',},
]
