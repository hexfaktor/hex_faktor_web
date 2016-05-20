FROM otp-18.0-ex-1.1.0


# ADD TOOLS
# =========
# refaktor/dockertools/bin will be mounted here
ENV PATH /tools/bin:$PATH


# ADD faktor USER
# ==============
RUN mkdir -p /home/faktor
RUN groupadd -r faktor -g 1000 && useradd -u 1000 -r -g faktor -d /home/faktor -s /sbin/nologin -c "Docker image user" faktor && chown -R faktor:faktor /home/faktor

ENV HOME /home/faktor
USER faktor

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix hex.info


# Goto mounted code directory
# ===========================
WORKDIR /job/code
