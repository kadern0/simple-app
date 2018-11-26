#!/bin/ash

cd /app/simple-sinatra-app/
rackup exec --host 0.0.0.0 config.ru
