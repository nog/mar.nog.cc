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

from = File.dirname(__FILE__) + "/../"
commands = [
  "open -u #{config["user"]},#{config["password"]} #{config["host"]}",
  "cd #{config["deploy_to"]}",
  "lcd #{from}",
  "mirror -v -R -e -X config/* -X data/* -X .git/*"
]
puts `lftp -c "#{commands.join(" && ")}"`
