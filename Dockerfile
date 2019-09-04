FROM ruby:2.6.4-alpine

ENV SLUG module_name
ENV ENDPOINT url

RUN apk add ruby-dev gcc g++ make

RUN gem install puppet_forge puppet-strings rest-client

COPY entrypoint.rb entrypoint.rb

ENTRYPOINT ["ruby entrypoint.rb"]



