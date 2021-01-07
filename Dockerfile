FROM ghcr.io/leafo/lapis-archlinux-itchio
MAINTAINER leaf corcoran <leafot@gmail.com>

WORKDIR /site/ludum-dare
ADD . .
ENTRYPOINT ./ci.sh
