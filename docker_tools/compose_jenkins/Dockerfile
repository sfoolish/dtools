FROM ubuntu:latest
MAINTAINER Qi Liang <sfoolish.liang@gmail.com>

# Make sure the package repository is up to date.
# RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
RUN apt-get update

# Install JDK 7 (latest edition)
RUN apt-get install -y --no-install-recommends openjdk-7-jdk
RUN apt-get install -y --no-install-recommends wget

# Add user jenkins to the image
RUN adduser --quiet jenkins
# Set password for the jenkins user (you may want to alter this).
RUN echo "jenkins:jenkins" | chpasswd

COPY main.sh /usr/local/bin
RUN chmod +x /usr/local/bin/main.sh

USER jenkins

CMD ["/usr/local/bin/main.sh"]

