FROM leafo/lapis-archlinux-itchio:latest
MAINTAINER leaf corcoran <leafot@gmail.com>

WORKDIR /site/ludum-dare
ADD . .
ENTRYPOINT ./ci.sh
