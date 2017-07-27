# Latex-Online container with Tex Live 2017 (full)
# Provides aslushnikov/latex-online with chrisanthropic/docker-TeXlive tweaked to get full Tex Live 2017
# VERSION       1

# use the ubuntu base image provided by dotCloud
FROM node:7

MAINTAINER Andrey Lushnikov aslushnikov@gmail.com
MAINTAINER Daniel Graziotin daniel@ineed.coffee

## Install TeXlive 2017. Change it accordingly.
ENV TL_VERSION 2017

# Download TeXlive source .iso
# We do this first thing here, so that the long download does not need to restart 
# in case next RUN fails
RUN wget -q   http://mirrors.ctan.org/systems/texlive/Images/texlive$TL_VERSION.iso 
# Install TeXlive profile
# Thanks to https://github.com/papaeye/docker-texlive for the reference
COPY texlive.profile /tmp/

# Sorted list of used packages.
RUN echo "deb http://ftp.us.debian.org/debian jessie contrib" > /etc/apt/sources.list.d/contrib.list; \
    echo "deb http://ftp.us.debian.org/debian jessie-updates contrib" >> /etc/apt/sources.list.d/contrib.list;

RUN export DEBIAN_FRONTEND=noninteractive \
# Update/Upgrade
    && apt-get clean \
    && apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends apt-utils  \
    && apt-get install -y --fix-missing --no-install-recommends perl wget xorriso \
# Use xorriso to extract .iso
    && osirrox -report_about NOTE -indev texlive$TL_VERSION.iso -extract / /usr/src/texlive \
# Remove .iso
    && rm texlive$TL_VERSION.iso \
# Uninstall xorriso now that we no longer need it
    && apt-get purge -y --auto-remove xorriso

# Install Tex Live
RUN /usr/src/texlive/install-tl -profile /tmp/texlive.profile \
# Remove source
    && rm -rf /usr/src/texlive \
    && rm /tmp/texlive.profile \
# Basic apt cleanup
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
# Set ENV variable to use texlive path
ENV PATH /texlive/bin/x86_64-linux:$PATH

# Update fonts
RUN luaotfload-tool -u -v

# Prepare latex-online
RUN apt-get update && apt-get install -y \
    git-core \
    python3 

# Add xindy-2.2 instead of makeindex.
ADD ./packages/xindy-2.2-rc2-linux.tar.gz /opt
ENV PATH="/opt/xindy-2.2/bin:${PATH}"

COPY ./util/docker-entrypoint.sh /

EXPOSE 2700
CMD ["./docker-entrypoint.sh"]

