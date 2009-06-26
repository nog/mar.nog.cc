require 'rubygems'
gem 'rack', "0.9.1"
gem 'sinatra', "0.9.2"
require 'sinatra'
gem 'haml', '2.0.9'
require 'haml'
require 'sass'
require 'yaml'

DATA_DIR = File.dirname(__FILE__) + "/data"

configure :development do
  use Rack::Reloader
end

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

    def self.get(mode, year, month, day)
      month = month.to_i < 10 ? "0" + month.to_i.to_s : month.to_s
      day = day.to_i < 10 ? "0" + day.to_i.to_s : day.to_s
      file = "#{DATA_DIR}/#{mode}/#{year}/#{month}#{day}.yml"
      YAML.load_file(file)
    end
  end
end

helpers do
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

get "/r/:mode/:date" do
  @date = Date.parse(params[:date])
  @ranking = Mar::Ranking.get(
    params[:mode], @date.year, @date.month, @date.day
  )
  haml :ranking
end

get "/style.css" do
  content_type 'text/css', :charset => 'utf-8'
  sass :style
end
