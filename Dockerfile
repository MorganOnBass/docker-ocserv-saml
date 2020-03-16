FROM debian:latest

LABEL maintainer="@MorganOnBass" \
      maintainer="morgan@mackechnie.uk" \
      version=0.1 \
      description="Openconnect server with libpam-ldap for AD authentication"

# Forked from MarkusMcNugen for AD Auth
# Forked from TommyLau for unRAID

VOLUME /config

# Install ocserv
#RUN apk add --update bash rsync ipcalc sipcalc ca-certificates rsyslog logrotate runit

RUN apt-get update && apt-get -y install ocserv libnss-ldap iptables procps rsync sipcalc ca-certificates
RUN rm /etc/pam_ldap.conf && touch /config/pam_ldap.conf && ln -s /config/pam_ldap.conf /etc/pam_ldap.conf

ADD ocserv /etc/default/ocserv
ADD pam_ldap /etc/default/pam_ldap

WORKDIR /config

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 443/tcp
EXPOSE 443/udp
CMD ["ocserv", "-c", "/config/ocserv.conf", "-f"]
#CMD ["/bin/bash"]