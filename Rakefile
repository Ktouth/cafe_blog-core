# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "cafe_blog-core"
  gem.homepage = "http://github.com/Ktouth/cafe_blog-core"
  gem.license = "MIT"
  gem.summary = %Q{CafeBlogのモデル層および基底機能の実装}
  gem.description = %Q{CafeBlogで使用するデータモデルおよび例外、モジュール、プラグインその他の動作の基底部分となる機能の実装を行うモジュール}
  gem.email = "ktouth@k-brand.gr.jp"
  gem.authors = ["K.Ktouth"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new
