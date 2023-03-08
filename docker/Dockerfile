FROM phusion/baseimage:0.10.2

LABEL maintainer="frederic.vauchelles@outlook.com"

RUN apt-get update
RUN apt-get install -y wget
RUN wget -qO - http://package.perforce.com/perforce.pubkey | apt-key add - 
RUN echo "deb http://archive.ubuntu.com/ubuntu/ precise main restricted universe multiverse" >> /etc/apt/sources.list
RUN echo "deb http://package.perforce.com/apt/ubuntu xenial release" >> /etc/apt/sources.list
RUN apt-get update

RUN apt-get install -y helix-p4d=2019.1-1845410~xenial helix-swarm-triggers=2019.1-1829459~xenial

ADD ./run.sh /
ADD ./docker/p4-users.txt /root/
ADD ./docker/p4-groups.txt /root/
ADD ./docker/p4-protect.txt /root/
RUN chmod 777 ./run.sh

ENV P4ROOT=/helix-core P4PORT=1666

EXPOSE 1666

VOLUME ["/helix-core"]

ENTRYPOINT [ "/sbin/my_init" ]
CMD ["/run.sh"] 