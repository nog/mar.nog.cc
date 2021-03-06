require 'yaml'

if `which lftp`.size == 0
  puts "lftpをインストールしてください"
  exit
end

begin
  config = YAML.load_file(File.dirname(__FILE__) + "/../config/ftp.yml")
rescue
  puts "設定ファイルが不正です"
  exit
end

local = File.expand_path(File.dirname(__FILE__) + "/../")
commands = [
  "open -u #{config["user"]},#{config["password"]} #{config["host"]}",
  "cd #{config["deploy_to"]}/data",
  "lcd #{local}/data/",
  "mirror -v"
]
system %Q{lftp -c "#{commands.join(" && ")}"}
