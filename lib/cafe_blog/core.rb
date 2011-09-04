# -*- encoding: UTF-8 -*-

# @author Keiichiro Nishi
# CafeBlog 名前空間： CafeBlog に関する全ての機能を実装する名前空間です。
module CafeBlog

  # Core 名前空間: CafeBlog の基礎およびデータモデルに関する機能を実装する名前空間です。
  module Core
    vpath = File.expand_path(File.dirname(__FILE__) + '/../../VERSION')
    ver_string = File.exist?(vpath) ? File.open(vpath) {|x| x.read } : 'unknown version'
    # バージョン文字列： パッケージのバージョンに追随する 
    VERSION = ver_string

    # Model 名前空間: CafeBlog において永続的データと接続するデータモデルを実装する名前空間です。
    module Model; end
  
    # アプリケーションで発生する例外の基底クラスです。
    class ApplicationError < Exception; end
    # データモデルの操作において何らかの失敗をした時に発生する例外クラスです。
    class ModelOperationError < ApplicationError; end
  end
end

require 'cafe_blog/core/environment'
