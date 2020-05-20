## Web Server with PD tools

FROM ubuntu:18.04

RUN apt-get update && \
  apt install -y git dnsutils inetutils-ftp inetutils-ping inetutils-tools \
  inetutils-traceroute openssh-client net-tools nginx


RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80

STOPSIGNAL SIGTERM

WORKDIR /

CMD ["nginx", "-g", "daemon off;"]