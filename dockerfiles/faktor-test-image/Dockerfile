FROM phusion/baseimage:0.9.16

RUN echo /root > /etc/container_environment/HOME

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]


# ADD TOOLS
# =========
# refaktor/dockertools/bin will be mounted here
ENV PATH /tools/bin:$PATH


# ADD faktor USER
# ==============
RUN mkdir -p /home/faktor
RUN groupadd -r faktor -g 1000 && useradd -u 1000 -r -g faktor -d /home/faktor -s /sbin/nologin -c "Docker image user" faktor && chown -R faktor:faktor /home/faktor

USER faktor
