FROM ruby:2.2



RUN gem install rubocop
RUN gem install inch -v "0.7.0"



# ADD TOOLS
# =========
# refaktor/dockertools/bin will be mounted here
ENV PATH /tools/bin:$PATH


# ADD faktor USER
# ==============
RUN mkdir -p /home/faktor
RUN groupadd -r faktor -g 1000 && useradd -u 1000 -r -g faktor -d /home/faktor -s /sbin/nologin -c "Docker image user" faktor && chown -R faktor:faktor /home/faktor

USER faktor


# Goto mounted code directory
# ===========================
WORKDIR /job/code
