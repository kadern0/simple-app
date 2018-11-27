FROM ruby:alpine

RUN apk add -U git \
    && adduser -D frank \
    && mkdir /app \
    && chown -R frank /app 
WORKDIR /app
#USER frank
RUN  git clone https://github.com/rea-cruitment/simple-sinatra-app.git \ 
    && cd simple-sinatra-app \
    && bundle install
ADD run.sh /
ENTRYPOINT ["/bin/ash","-c","chmod +x /run.sh && /run.sh"]    
