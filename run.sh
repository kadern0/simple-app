#!/bin/ash

cd /app/simple-sinatra-app/
#rm helloworld.rb
#cat << EOF > helloworld.rb
#require 'sinatra'
#get '/' do
#  "Hello World updated!"
#end
#EOF
rackup exec --host 0.0.0.0 config.ru
