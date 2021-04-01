FROM ruby:3.0.0-alpine

LABEL maintainer="tac@tac42.net"
LABEL Description="Yasuri is a library for declarative web scraping and a command line tool for scraping with it." Vendor="TAC" Version="3.3.2"

RUN apk add gcc g++ make libffi-dev openssl-dev

RUN gem install yasuri
