# This Dockerfile creates an debian image with xfstests-bld build environment
# See https://github.com/tytso/xfstests-bld/blob/master/README
#
# VERSION 0.1
FROM debian

MAINTAINER Dmitry Monakhov dmonakhov@openvz.org
#################Usage example ###################
# docker run -i -t --privileged --rm dmonakhov/xfstests-bld \
#  "kvm-xfstests.sh --kernel /tmp/bzImage --update-files --update-xfstests-tar  smoke"
##################################################

# Install deps. ## TODO: --no-install-recommends
RUN apt-get update && \
    apt-get install -y \
    	    autoconf  \
	    automake \
	    build-essential \
	    curl \
	    debootstrap \
	    gettext \
	    git \
	    libtool \
	    libtool-bin \
	    pkg-config \
	    pigz \
	    qemu-kvm \
	    qemu-utils \
	    uuid-dev \
	    net-tools \
	    iptables && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* \
       /usr/share/doc /usr/share/doc-base \
       /usr/share/man /usr/share/locale /usr/share/zoneinfo
# Fetch and build xfstests-bld
# In order to build root_image from scratch privileged operation are required,
# so it is impossible during build stage.
# One can make it like this:
# docker run -i -t --privileged --rm dmonakhov/xfstests-bld "cd kvm-xfstests/test-appliance && ./gen-image"
# During build stage we simply fetch image precreated by tytso@
#

## Custom config is required in order to workaroung build bug
## TODO: remove  after fix will be merged to xfstests-bld and xfsprogs repos
##       and switch back to tytso's git repo.
ADD config.custom.docker /tmp/

RUN mkdir /devel && \
    cd /devel && \
    git clone https://github.com/dmonakhov/xfstests-bld.git xfstests-bld && \
    cd xfstests-bld && \
    cat /tmp/config.custom.docker >> config && \
    unlink /tmp/config.custom.docker && \
    make && \
    make tarball && \
    cp gce-xfstests.sh kvm-xfstests.sh /usr/local/bin/ && \
    curl https://www.kernel.org/pub/linux/kernel/people/tytso/kvm-xfstests/root_fs.img.x86_64 \
    	 > kvm-xfstests/test-appliance/root_fs.img

WORKDIR /devel/xfstests-bld

# Usage example:
# Run smoke tests for my kernel 
# docker run -i -t --privileged --rm dmonakhov/xfstests-bld \
#    kvm-xfstests.sh --kernel /tmp/bzImage --update-files --update-xfstests-tar smoke
#
# This is build enviroment so there is no sane default command here,
# this command simply demonstrate that enviroment is 
CMD wget -O /tmp/initrd.img https://mirror.yandex.ru/fedora/linux/releases/24/Server/x86_64/os/images/pxeboot/initrd.img && \
    wget -O /tmp/vmlinuz https://mirror.yandex.ru/fedora/linux/releases/24/Server/x86_64/os/images/pxeboot/vmlinuz && \
    kvm-xfstests.sh --kernel /tmp/vmlinuz \
    		    --initrd /tmp/initrd.img \
		    --update-files --update-xfstests-tar smoke
