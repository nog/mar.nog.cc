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
    attr_reader :mode, :date
    def initialize mode, date
      @date = date
      @mode = mode
    end

    def get_file_path
      file = "#{DATA_DIR}/#{@mode}/#{date.strftime("%Y/%m%d")}.yml"
      return file
    end

    def data
      return @data if @data
      @data = YAML.load_file(self.get_file_path)
      return @data
    end

    def exist?
      File.exist?(self.get_file_path)
    end

    def next
      self.class.get(@mode, (date + 1))
    end

    def prev
      self.class.get(@mode, (date - 1))
    end

    class << self
      def modes
        Dir[DATA_DIR + "/*"].map{|dir|
          File.directory?(dir) ? File.basename(dir) : nil
        }.compact
      end

      def years(mode)
        Dir["#{DATA_DIR}/#{mode}/*"].map{|dir|
          File.directory?(dir) ? File.basename(dir) : nil
        }.compact.map{|y| y.to_i}.sort
      end

      def monthes(mode, year)
        Dir["#{DATA_DIR}/#{mode}/#{year.to_s}/*"].map{|dir|
          file = File.basename(dir)
          file.match(/^(\d{2})\d{2}\.yml/) ? $~[1] : nil
        }.uniq.compact.map{|m| m.to_i}.sort
      end

      def days(mode, year, month)
        month = month.to_i < 10 ? "0" + month.to_i.to_s : month.to_s
        days = Dir["#{DATA_DIR}/#{mode}/#{year.to_s}/*"].find_all{|dir|
          file = File.basename(dir)
          file.match(/^#{month}\d{2}\.yml/)
        }.map{|dir|
          file = File.basename(dir)
          file.match(/^\d{2}(\d{2})\.yml/)[1]
        }.map{|d| d.to_i}.sort
        return days
      end

      def get_path(mode, date)
        year, month, day = date.year.to_s, year.month.to_s, year.day.to_s
        month = month.to_i < 10 ? "0" + month.to_i.to_s : month.to_s
        day = day.to_i < 10 ? "0" + day.to_i.to_s : day.to_s
        file = "#{DATA_DIR}/#{mode}/#{year}/#{month}#{day}.yml"
        return file
      end

      def latest(mode)
        year  = self.years(mode).last
        month = self.monthes(mode, year).last
        day   = self.days(mode, year, month).last
        date  = Date.new(year, month, day)
        self.new(mode, date)
      end

      def get(mode, date)
        obj = self.new(mode, date)
        return obj.exist? ? obj : nil
      end
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
  file = Mar::Ranking.get_path(params[:mode], @date)
  send_file(
    file,
    {:type => "text/plain"}
  )
end

get "/r/:mode/:date" do
  @date = Date.parse(params[:date])
  @ranking = Mar::Ranking.new(params[:mode], @date)
  haml :ranking
end

get "/style.css" do
  content_type 'text/css', :charset => 'utf-8'
  sass :style
end

get "/mixiapp/?" do
  @ranking = Mar::Ranking.latest("indies")
  haml :"mixiapp/ranking", :layout => :"mixiapp/layout"
end

get "/mixiapp/style.css" do
  content_type 'text/css', :charset => 'utf-8'
  sass :"mixiapp/style"
end
