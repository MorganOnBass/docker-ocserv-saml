FROM alpine:latest

LABEL maintainer="@MorganOnBass" \
      maintainer="morgan@mackechnie.uk" \
      version=0.1 \
      description="Openconnect server with saml authentication support"

# Forked from MarkusMcNugen for LDAP and eventually SAML
# Forked from TommyLau for unRAID

# build ocserv

RUN buildDeps=" \
            autoconf \
            automake \
            curl-dev \
            libtool \
            libxml2-dev \
            py-six \
            python \
            py2-pip \
            perl-dev \
            xmlsec-dev \
            zlib-dev \
            git \
		curl \
		g++ \
            glib-dev \
		gawk \
		gnutls-dev \
		gpgme \
		libev-dev \
		libnl3-dev \
		libseccomp-dev \
		linux-headers \
		linux-pam-dev \
		lz4-dev \
		make \
		readline-dev \
		tar \
		xz \
            protobuf-c \
            gperf \
            apr \
            apr-dev \
	"; \
	set -x && \
      apk add --update --virtual .build-deps $buildDeps && \
      cd /tmp && \
      wget http://www.aleksey.com/xmlsec/download/xmlsec1-1.2.29.tar.gz && \
      tar xzf xmlsec1-1.2.29.tar.gz && \
      cd xmlsec1-1.2.29 && \
      ./configure --enable-soap && \
      make && \
      make install && \
      cd /tmp && \
      pip install six && \
      wget https://dev.entrouvert.org/releases/lasso/lasso-2.5.1.tar.gz && \
      tar zxf lasso-2.5.1.tar.gz && \
      cd lasso-2.5.1 && \
      ./configure && \
      make && \
      make install && \
      git clone https://gitlab.com/morganofbass/ocserv.git && \
      cd ocserv && \
      autoreconf -fvi && \
      ./configure --enable-saml-auth && \
      make && \
      make install && \
      runDeps="$( \
		scanelf --needed --nobanner /usr/local/sbin/ocserv \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
			| xargs -r apk info --installed \
			| sort -u \
		) \
            gnutls-utils \
            iptables \
            xmlsec \
            libxml2 \
            rsync \
            sipcalc \
            libnl3 \
            bash" && \
      apk add --update --virtual .run-deps $runDeps && \
      apk del .build-deps && \
      rm -rf /var/cache/apk/* && \
      rm -rf /tmp/*

VOLUME /config

ADD ocserv /etc/default/ocserv

WORKDIR /ocserv

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 443/tcp
EXPOSE 443/udp
CMD ["ocserv", "-c", "/config/ocserv.conf", "-f"]
