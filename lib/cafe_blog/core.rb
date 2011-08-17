# -*- encoding: utf-8 -*-

module CafeBlog
  module Core
    vpath = File.expand_path(File.dirname(__FILE__) + '/../../VERSION')
    VERSION = File.exist?(vpath) ? File.open(vpath) {|x| x.read } : 'unknown version'
  end
end
