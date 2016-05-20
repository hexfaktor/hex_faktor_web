FROM phusion/baseimage:0.9.16

RUN echo /root > /etc/container_environment/HOME

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# Set the locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR /tmp

# See : https://github.com/phusion/baseimage-docker/issues/58
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# update and install some software requirements
RUN apt-get update && apt-get upgrade -y && apt-get install -y curl wget git make

WORKDIR /


# ADD faktor USER
# ==============
RUN mkdir -p /home/faktor
RUN groupadd -r faktor -g 1000 && useradd -u 1000 -r -g faktor -d /home/faktor -s /sbin/nologin -c "Docker image user" faktor && chown -R faktor:faktor /home/faktor

#USER faktor
