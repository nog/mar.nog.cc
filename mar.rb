$LOAD_PATH.unshift *Dir["#{File.dirname(__FILE__)}/vendor/**/lib"]
require 'sinatra'
require 'haml'
require 'sass'
require 'yaml'
require 'pathname'

DATA_DIR = File.dirname(__FILE__) + "/data"

set :root, File.dirname(__FILE__)

module Mar
  class Ranking
    def self.modes
      Dir[DATA_DIR + "/*"].map{|dir|
        File.directory?(dir) ? File.basename(dir) : nil
      }.compact
    end

    def self.years(mode)
      Dir["#{DATA_DIR}/#{mode}/*"].map{|dir|
        File.directory?(dir) ? File.basename(dir) : nil
      }.compact
    end

    def self.monthes(mode, year)
      Dir["#{DATA_DIR}/#{mode}/#{year}/*"].map{|dir|
        file = File.basename(dir)
        file.match(/^(\d{2})\d{2}\.yml/) ? $~[1] : nil
      }.uniq.compact.sort
    end

    def self.days(mode, year, month)
      Dir["#{DATA_DIR}/#{mode}/#{year}/*"].find_all{|dir|
        file = File.basename(dir)
        file.match(/^#{month}\d{2}\.yml/)
      }.map{|dir|
        file = File.basename(dir)
        file.match(/^\d{2}(\d{2})\.yml/)[1]
      }.sort
    end

    def self.get_path(mode, year, month, day)
      month = month.to_i < 10 ? "0" + month.to_i.to_s : month.to_s
      day = day.to_i < 10 ? "0" + day.to_i.to_s : day.to_s
      file = "#{DATA_DIR}/#{mode}/#{year}/#{month}#{day}.yml"
      return file
    end

    def self.get(mode, year, month, day)
      file = self.get_path(mode, year, month, day)
      return YAML.load_file(file)
    end
  end
end

helpers do
  def title
    if @title
      @title + " - mixiアプリランキング定点観測"
    else
      "mixiアプリランキング定点観測"
    end
  end

  def description
    @description || "mixiアプリの人気ランキングを毎日観測"
  end

  def ranking_url(mode, year, month, day)
    month = month.to_i < 10 ? "0" + month.to_i.to_s : month.to_s
    day = day.to_i < 10 ? "0" + day.to_i.to_s : day.to_s
    return "/r/#{mode.to_s}/#{year.to_s}#{month}#{day}"
  end

  def user_url(user_id)
    "http://platform001.mixi.jp/show_friend.pl?id=#{user_id.to_s}"
  end

  def app_url(app_id)
    "http://platform001.mixi.jp/view_appli.pl?id=#{app_id.to_s}"
  end

  def br(str)
    str.gsub(/\r/, "<br />")
  end
end

get "/?" do
  haml :index
end

get "/r/:mode" do
  redirect "/"
end

get "/r/:mode/:date.yaml" do
  @date = Date.parse(params[:date])
  file = Mar::Ranking.get_path(
    params[:mode], @date.year, @date.month, @date.day
  )
  send_file(
    file,
    {:type => "text/plain"}
  )
end

get "/r/:mode/:date" do
  @date = Date.parse(params[:date])
  @ranking = Mar::Ranking.get(
    params[:mode], @date.year, @date.month, @date.day
  )
  haml :ranking
end

get "/mixiapp/?" do
  haml :"mixiapp/index", :layout => :"mixiapp/layout"
end

get "/style.css" do
  content_type 'text/css', :charset => 'utf-8'
  sass :style
end
