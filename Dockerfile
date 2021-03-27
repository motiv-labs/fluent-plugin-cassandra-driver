######## Image to run FluentD Tests #######
FROM fluent/fluentd:v1.11.5-1.0

USER root

RUN apk add git
ARG GITHUB_USER
ENV GITHUB_USER=$GITHUB_USER
ARG GITHUB_TOKEN
ENV GITHUB_TOKEN=$GITHUB_TOKEN
RUN git config --global url."https://$GITHUB_USER:$GITHUB_TOKEN@github.com".insteadOf "https://github.com"

RUN apk add --no-cache --update --virtual .build-deps \
  sudo build-base ruby-dev \
  && sudo gem install specific_install \
  && sudo gem specific_install https://github.com/motiv-labs/fluent-plugin-cassandra-driver \
  && sudo gem sources --clear-all \
  && apk del .build-deps \
  && rm -rf /tmp/* /var/tmp/* /usr/lib/ruby/gems/*/cache/*.gem

USER fluent