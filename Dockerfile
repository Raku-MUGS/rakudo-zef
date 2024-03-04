ARG debian_version=bookworm-slim
ARG rakudo_version=2024.02
FROM debian:$debian_version
ARG debian_version
ARG rakudo_version

LABEL maintainer="Geoffrey Broadwell"
LABEL org.opencontainers.image.source=https://github.com/Raku-MUGS/rakudo-zef

# Install required build packages and build/install Rakudo+Zef to /opt/rakudo
RUN apt-get update \
 && apt-get -y --no-install-recommends install \
    build-essential ca-certificates curl git \
 && git clone https://github.com/rakudo/rakudo.git /tmp/rakudo \
 && git clone https://github.com/ugexe/zef.git /tmp/zef \
 && cd /tmp/rakudo \
 && git checkout $rakudo_version \
 && perl Configure.pl --gen-nqp --gen-moar --backends=moar --prefix=/opt/rakudo \
 && make \
 && make install \
 && cd /tmp/zef \
 && PATH="/opt/rakudo/bin:$PATH" raku -Ilib bin/zef install --/test . \
 && rm -rf /tmp/rakudo /tmp/zef /tmp/.zef \
 && apt-get purge -y --auto-remove build-essential git \
 && rm -rf /var/lib/apt/lists/*

# Create raku user and prepare a stub home directory
RUN groupadd -g 999 raku \
 && useradd -r -m -s /usr/bin/false -u 999 -g raku raku \
 && chmod 700 /home/raku

# Prepare for Zef use in Raku home
ENV PATH="/opt/rakudo/bin:/opt/rakudo/share/perl6/site/bin:/home/raku/.raku/bin:$PATH"
WORKDIR /home/raku
USER raku:raku

# Note versions in docker build output
RUN echo "\n\e[31mRakudo version info:\e[0m" && raku -v \
 && echo "\n\e[31mZef version:\e[0m" && zef --version \
 && echo

# Here ... we ... go!
CMD ["raku"]
