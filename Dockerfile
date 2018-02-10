FROM alpine:3.7

MAINTAINER MarkusMcNugen
# Forked from TommyLau for unRAID

ENV OC_VERSION=0.11.10

VOLUME /config

# Install dependencies
RUN buildDeps=" \
		curl \
		g++ \
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
	"; \
	set -x \
	&& apk add --update --virtual .build-deps $buildDeps \
	&& curl -SL "ftp://ftp.infradead.org/pub/ocserv/ocserv-$OC_VERSION.tar.xz" -o ocserv.tar.xz \
	&& curl -SL "ftp://ftp.infradead.org/pub/ocserv/ocserv-$OC_VERSION.tar.xz.sig" -o ocserv.tar.xz.sig \
	&& gpg --keyserver pool.sks-keyservers.net --recv-key 7F343FA7 \
	&& gpg --keyserver pool.sks-keyservers.net --recv-key 96865171 \
	&& gpg --verify ocserv.tar.xz.sig \
	&& mkdir -p /usr/src/ocserv \
	&& tar -xf ocserv.tar.xz -C /usr/src/ocserv --strip-components=1 \
	&& rm ocserv.tar.xz* \
	&& cd /usr/src/ocserv \
	&& ./configure \
	&& make \
	&& make install \
	&& cd / \
	&& rm -fr /usr/src/ocserv \
	&& runDeps="$( \
		scanelf --needed --nobanner /usr/local/sbin/ocserv \
			| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
			| xargs -r apk info --installed \
			| sort -u \
		)" \
	&& apk add --virtual .run-deps $runDeps gnutls-utils iptables \
	&& apk del .build-deps \
	&& rm -rf /var/cache/apk/* \
	&& mkdir -p /etc/ocserv/config-per-group

RUN apk add --update bash

ADD ocserv/ocserv.conf /etc/ocserv/ocserv.conf
ADD ocserv/connect.sh /etc/ocserv/connect.sh
ADD ocserv/disconnect.sh /etc/ocserv/disconnect.sh
ADD ocserv/ocserv.conf /etc/ocserv/ocserv.conf.bak
RUN chmod a+x /etc/ocserv/*.sh
RUN chmod -R 775 /etc/ocserv/

WORKDIR /etc/ocserv

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 4443
CMD ["ocserv", "-c", "/etc/ocserv/ocserv.conf", "-f"]
