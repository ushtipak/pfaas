FROM alpine:3.9
MAINTAINER ushtipak@gmail.com

RUN apk update
RUN apk upgrade
RUN apk add bash

WORKDIR /opt/pfaas
COPY . /opt/pfaas

CMD ["bash", "pfaas.sh"]
