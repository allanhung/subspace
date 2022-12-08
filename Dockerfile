FROM golang:1.16-alpine as build

RUN apk add --no-cache \
    git \
    make

WORKDIR /src

COPY Makefile ./
# go.mod and go.sum if exists
COPY go.* ./
COPY cmd/ ./cmd
COPY web ./web

ARG BUILD_VERSION=unknown

ENV GODEBUG="netdns=go http2server=0"

RUN make build BUILD_VERSION=${BUILD_VERSION}

FROM centos:7
LABEL maintainer="github.com/subspacecommunity/subspace"

RUN yum install -y iproute https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN curl -o /etc/yum.repos.d/jdoss-wireguard-epel-7.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo
RUN curl -s https://packagecloud.io/install/repositories/imeyer/runit/script.rpm.sh | bash
RUN yum install -y wireguard-dkms wireguard-tools runit dnsmasq socat
# patch for centos 7.7
#RUN echo "#define ipv6_dst_lookup_flow(a, b, c, d) ipv6_dst_lookup(a, b, &dst, c) + (void *)0 ?: dst" >> /usr/src/wireguard-$(dkms status |grep wireguard | awk -F':' '{print $1}' | awk -F'/' '{print $2}')/compat/compat.h

COPY --from=build  /src/subspace /usr/bin/subspace
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY bin/my_init /sbin/my_init

ENV DEBIAN_FRONTEND noninteractive

RUN chmod +x /usr/bin/subspace /usr/local/bin/entrypoint.sh /sbin/my_init

ENTRYPOINT ["/usr/local/bin/entrypoint.sh" ]

CMD [ "/sbin/my_init" ]
