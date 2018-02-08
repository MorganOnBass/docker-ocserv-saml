FROM alpine:3.7

MAINTAINER MarkusMcNugen
# Forked from TommyLau for unRAID

VOLUME /config

ENV OC_VERSION=0.11.10

# Install dependencies
RUN buildDeps=" \
		bash \
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
	
ADD ocserv/ocserv.conf.sample /config/ocserv.conf

# Compile and install ocserv
RUN curl -SL "ftp://ftp.infradead.org/pub/ocserv/ocserv-$OC_VERSION.tar.xz" -o ocserv.tar.xz \
	&& curl -SL "ftp://ftp.infradead.org/pub/ocserv/ocserv-$OC_VERSION.tar.xz.sig" -o ocserv.tar.xz.sig \
	&& gpg --keyserver pgp.mit.edu --recv-key 7F343FA7 \
	&& gpg --keyserver pgp.mit.edu --recv-key 96865171 \
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
	&& rm -rf /var/cache/apk/*

# Setup config
RUN set -x \
	&& sed -i 's/\.\/sample\.passwd/\/config\/ocpasswd/' /config/ocserv.conf \
	&& sed -i 's/\(max-same-clients = \)2/\110/' /config/ocserv.conf \
	&& sed -i 's/\.\.\/tests/\/etc\/ocserv/' /config/ocserv.conf \
	&& sed -i 's/#\(compression.*\)/\1/' /config/ocserv.conf \
	&& sed -i '/^ipv4-network = /{s/192.168.1.0/192.168.99.0/}' /config/ocserv.conf \
	&& sed -i 's/192.168.1.2/8.8.8.8/' /config/ocserv.conf \
	&& sed -i 's/^route/#route/' /config/ocserv.conf \
	&& sed -i 's/^no-route/#no-route/' /config/ocserv.conf \

WORKDIR /config/ocserv

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 443
CMD ["ocserv", "-c", "/config/ocserv.conf", "-f"]
