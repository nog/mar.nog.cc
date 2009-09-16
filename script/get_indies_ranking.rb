#!/usr/bin/ruby
require 'yaml'
config = YAML.load_file(File.dirname(__FILE__) + "/../config/mixi.yml")

require 'kconv'
require 'rubygems'
require 'fileutils'

puts 'Content-type:text/html'
puts ''

gem 'hpricot', "0.6"
require 'hpricot'
gem 'mechanize', "0.7.6"
require 'mechanize'
gem 'kakutani-yaml_waml'
require 'yaml_waml'
require 'yaml/store'


agent = WWW::Mechanize.new
#agent.html_parser = Hpricot
agent.follow_meta_refresh = true
page = agent.get("http://platform001.mixi.jp/")
sleep 1

login_form = page.forms.find{|f|
  f.action == "/login.pl"
}


login_form["email"] = config["email"]
login_form["password"] = config["password"]

logined_page = login_form.submit

results = []
(1..10).each{|i|
  ranking_page = agent.get("http://platform001.mixi.jp/search_appli.pl?page=#{i.to_s}&mode=indies")

  ranking_page.root.search(".applicationList01>tr").each{|app|
    app_link = app.search(".appTitle a")[0]
    text = app_link.inner_html.toutf8
    text.match(/^(.+)\((\d+)\)$/)
    title = $~[1]
    count = $~[2].to_i

    href = app_link[:href]
    href.match(/^\/view_appli\.pl\?id\=(\d+)$/)
    app_id = $~[1].to_i

    app_image = app.search(".appImage img")[0]
    image_url = app_image[:src]


    user_link = app.search("a").find{|a| a[:href].match(/^\/show_friend.pl/)}
    user_name = user_link.inner_text.toutf8
    user_id   = user_link[:href].match(/\/show_friend.pl\?id=(\d+)$/)[1].to_i

    app_intro = app.search(".appIntro")[0]
    description = app_intro.inner_text.toutf8.gsub(/\r?\n/, "\n")


    puts "----"
    puts title
    puts count
    puts app_id
    puts image_url
    puts user_name
    puts user_id
    puts description


    results.push({
      :title => title,
      :count => count,
      :app_id => app_id,
      :image_url => image_url,
      :user_name => user_name,
      :user_id => user_id,
      :description => description
    })
  }
  sleep 1
}

data_base_dir = File.dirname(__FILE__) + "/../data/indies"
file_path = data_base_dir + "/" + Time.now.strftime("%Y/%m%d") + ".yml"
FileUtils.mkdir_p(File.dirname(file_path))
db = YAML::Store.new(file_path)
db.transaction do
  db[:data] = results
  db[:time] = Time.now
end

puts "finish!!!!!!!!!!!!"
