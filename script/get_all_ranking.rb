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
gem 'mechanize'
require 'mechanize'
gem 'kakutani-yaml_waml'
require 'yaml_waml'
require 'yaml/store'


WWW::Mechanize.html_parser = Hpricot
agent = WWW::Mechanize.new
agent.follow_meta_refresh = true
page = agent.get("http://mixi.jp/")
sleep 1

login_form = page.forms.find{|f|
  f.action == "/login.pl"
}


login_form["email"] = config["email"]
login_form["password"] = config["password"]

logined_page = login_form.submit

results = []
(1..14).each{|i|
  ranking_page = agent.get("http://platform001.mixi.jp/search_appli.pl?page=#{i.to_s}&mode=ranking")

  ranking_page.root.search("ul.mainList02>li").each{|app|
    title = app.search("p.appName strong")[0].inner_text.toutf8
    count = app.search("dd.numAllUser")[0].inner_text.toutf8.to_i

    app_link = app.search(".appIcon a")[0]
    href = app_link[:href]
    href.match(/view_appli\.pl\?id\=(\d+)$/)
    app_id = $~[1].to_i

    app_image = app.search("p.catch img")[0]
    image_url = app_image[:src]


    user_link = app.search("dd.provider a")[0]
    user_name = user_link.inner_text.toutf8
    user_id   = user_link[:href].match(/show_friend.pl\?id=(\d+)$/)[1].to_i

    app_intro = app.search(".introduction .intro_txt")[0]
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

data_base_dir = File.dirname(__FILE__) + "/../data/all"
file_path = data_base_dir + "/" + Time.now.strftime("%Y/%m%d") + ".yml"
FileUtils.mkdir_p(File.dirname(file_path))
db = YAML::Store.new(file_path)
db.transaction do
  db[:data] = results
  db[:time] = Time.now
end

puts "finish!!!!!!!!!!!!"
