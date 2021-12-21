FROM    ubuntu:20.10 AS devel-base

ENV	    NVIDIA_DRIVER_CAPABILITIES compat32,compute,video
WORKDIR     /tmp/workdir

RUN     apt-get -yqq update && \
        apt-get install -yq --no-install-recommends ca-certificates expat libgomp1 && \
        apt-get autoremove -y && \
        apt-get clean -y

FROM        ubuntu:20.10 AS runtime-base

ENV	    NVIDIA_DRIVER_CAPABILITIES compat32,compute,video
WORKDIR     /tmp/workdir

RUN     apt-get -yqq update && \
        apt-get install -yq --no-install-recommends ca-certificates expat libgomp1 libxcb-shape0-dev && \
        apt-get autoremove -y && \
        apt-get clean -y

FROM  devel-base as build
     
ENV         FFMPEG_VERSION=4.4.1 \
            AOM_VERSION=v3.2.0 \
            FDKAAC_VERSION=0.1.5 \
            FONTCONFIG_VERSION=2.12.4 \
            FREETYPE_VERSION=2.11.1 \
            FRIBIDI_VERSION=0.19.7 \
            KVAZAAR_VERSION=2.1.0 \
            LAME_VERSION=3.100 \
            LIBASS_VERSION=0.15.2 \
            LIBPTHREAD_STUBS_VERSION=0.4 \
            LIBVIDSTAB_VERSION=1.1.0 \
            LIBXCB_VERSION=1.13.1 \
            XCBPROTO_VERSION=1.13 \
            OGG_VERSION=1.3.5 \
            OPENCOREAMR_VERSION=0.1.5 \
            OPUS_VERSION=1.2 \
            OPENJPEG_VERSION=2.4.0 \
            VORBIS_VERSION=1.3.5 \
            VPX_VERSION=1.11.0 \
            WEBP_VERSION=1.2.1 \
            X264_VERSION=20191217-2245-stable \
            X265_VERSION=3.2.1 \
            XAU_VERSION=1.0.9 \
            XORG_MACROS_VERSION=1.19.2 \
            XPROTO_VERSION=7.0.31 \       
			NVIDIA_HEADERS_VERSION=11.1.5.0 \
            LIBBLURAY_VERSION=1.1.2 \
            SRC=/usr/local

ARG         FRIBIDI_SHA256SUM="3fc96fa9473bd31dcb5500bdf1aa78b337ba13eb8c301e7c28923fea982453a8 0.19.7.tar.gz"
ARG         LIBASS_SHA256SUM="8fadf294bf701300d4605e6f1d92929304187fca4b8d8a47889315526adbafd7 0.13.7.tar.gz"
ARG         LIBVIDSTAB_SHA256SUM="14d2a053e56edad4f397be0cb3ef8eb1ec3150404ce99a426c4eb641861dc0bb v1.1.0.tar.gz"
ARG         OGG_SHA256SUM="fe5670640bd49e828d64d2879c31cb4dde9758681bb664f9bdbf159a01b0c76e libogg-1.3.4.tar.gz"
ARG         OPUS_SHA256SUM="77db45a87b51578fbc49555ef1b10926179861d854eb2613207dc79d9ec0a9a9 opus-1.2.tar.gz"
ARG         VORBIS_SHA256SUM="6efbcecdd3e5dfbf090341b485da9d176eb250d893e3eb378c428a2db38301ce libvorbis-1.3.5.tar.gz"
ARG         LIBXML2_SHA256SUM="f07dab13bf42d2b8db80620cce7419b3b87827cc937c8bb20fe13b8571ee9501  libxml2-v2.9.10.tar.gz"
ARG         LIBBLURAY_SHA256SUM="a3dd452239b100dc9da0d01b30e1692693e2a332a7d29917bf84bb10ea7c0b42 libbluray-1.1.2.tar.bz2"


ARG         LD_LIBRARY_PATH=/opt/ffmpeg/lib
ARG         MAKEFLAGS="-j12"
ARG         PKG_CONFIG_PATH="/opt/ffmpeg/share/pkgconfig:/opt/ffmpeg/lib/pkgconfig:/opt/ffmpeg/lib64/pkgconfig"
ARG         PREFIX=/opt/ffmpeg
ARG         LD_LIBRARY_PATH="/opt/ffmpeg/lib:/opt/ffmpeg/lib64:/usr/lib64:/usr/lib"

RUN			chmod 777 /var/cache/debconf/ 
RUN			chmod 777 /var/cache/debconf/passwords.dat
RUN 		echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && apt-get install -y -q


RUN      buildDeps="autoconf \
                    automake \
                    cmake \
                    curl \
                    bzip2 \
                    libexpat1-dev \
                    g++ \
                    gcc \
                    git \
                    gperf \
                    libtool \
                    make \
                    nasm \
                    perl \
                    pkg-config \
                    python \
                    libssl-dev \
                    yasm \
					libargtable2-0 \
					xmltv \
					gettext \
					libdvbcsa-dev \
					libhdhomerun-dev \
					libargtable2-dev \
                    zlib1g-dev" && \
        apt-get -yqq update && \
        apt-get install -yq --no-install-recommends ${buildDeps}

RUN \
	DIR=/tmp/nv-codec-headers && \
	git clone https://github.com/FFmpeg/nv-codec-headers ${DIR} && \
	cd ${DIR} && \
	git checkout n${NVIDIA_HEADERS_VERSION} && \
	make PREFIX="${PREFIX}" && \
	make install PREFIX="${PREFIX}" && \
        rm -rf ${DIR}

## opencore-amr https://sourceforge.net/projects/opencore-amr/
RUN \
        DIR=/tmp/opencore-amr && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sL https://versaweb.dl.sourceforge.net/project/opencore-amr/opencore-amr/opencore-amr-${OPENCOREAMR_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        ./configure --prefix="${PREFIX}" --enable-shared  && \
        make && \
        make install && \
        rm -rf ${DIR}
# x264 http://www.videolan.org/developers/x264.html
RUN \
        DIR=/tmp/x264 && \
        mkdir -p ${DIR} && \
       cd ${DIR} && \
        curl -sL https://download.videolan.org/pub/videolan/x264/snapshots/x264-snapshot-${X264_VERSION}.tar.bz2 | \
        tar -jx --strip-components=1 && \
      ./configure --prefix="${PREFIX}" --enable-shared --enable-pic --disable-cli && \
        make && \
       make install && \
        rm -rf ${DIR}
### x265 http://x265.org/
RUN \
        DIR=/tmp/x265 && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        #curl -sL https://download.videolan.org/pub/videolan/x265/x265_${X265_VERSION}.tar.gz  | \
		curl -sL https://github.com/videolan/x265/archive/3.4.tar.gz  | \
        tar -zx && \
        #cd x265_${X265_VERSION}/build/linux && \
		cd x265-3.4/build/linux && \
        sed -i "/-DEXTRA_LIB/ s/$/ -DCMAKE_INSTALL_PREFIX=\${PREFIX}/" multilib.sh && \
        sed -i "/^cmake/ s/$/ -DENABLE_CLI=OFF/" multilib.sh && \
        ./multilib.sh && \
        make -C 8bit install && \
        rm -rf ${DIR}
### libogg https://www.xiph.org/ogg/
RUN \
        DIR=/tmp/ogg && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://downloads.xiph.org/releases/ogg/libogg-1.3.5.tar.gz && \
        tar -zx --strip-components=1 -f libogg-1.3.5.tar.gz && \
        ./configure --prefix="${PREFIX}" --enable-shared  && \
        make && \
        make install && \
        rm -rf ${DIR}
### libopus https://www.opus-codec.org/
RUN \
        DIR=/tmp/opus && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://archive.mozilla.org/pub/opus/opus-${OPUS_VERSION}.tar.gz && \
        echo ${OPUS_SHA256SUM} | sha256sum --check && \
        tar -zx --strip-components=1 -f opus-${OPUS_VERSION}.tar.gz && \
        autoreconf -fiv && \
        ./configure --prefix="${PREFIX}" --enable-shared && \
        make && \
        make install && \
        rm -rf ${DIR}
### libvorbis https://xiph.org/vorbis/
RUN \
        DIR=/tmp/vorbis && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO http://downloads.xiph.org/releases/vorbis/libvorbis-${VORBIS_VERSION}.tar.gz && \
        echo ${VORBIS_SHA256SUM} | sha256sum --check && \
        tar -zx --strip-components=1 -f libvorbis-${VORBIS_VERSION}.tar.gz && \
        ./configure --prefix="${PREFIX}" --with-ogg="${PREFIX}" --enable-shared && \
        make && \
        make install && \
        rm -rf ${DIR}
### libtheora http://www.theora.org/
#RUN \
   #     DIR=/tmp/theora && \
      #  mkdir -p ${DIR} && \
      #  cd ${DIR} && \
      #  curl -sLO http://downloads.xiph.org/releases/theora/libtheora-1.1.1.tar.bz2 && \
      #  tar -jx --strip-components=1 -f libtheora-1.1.1.tar.bz2 && \
      #  ./configure --prefix="${PREFIX}" --with-ogg="${PREFIX}" --enable-shared && \
      #  make && \
       # make install && \
       # rm -rf ${DIR}
### libvpx https://www.webmproject.org/code/
RUN \
        DIR=/tmp/vpx && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
       curl -sL https://codeload.github.com/webmproject/libvpx/tar.gz/v${VPX_VERSION} | \
        tar -zx --strip-components=1 && \
        ./configure --prefix="${PREFIX}" --enable-vp8 --enable-vp9 --enable-vp9-highbitdepth --enable-pic --enable-shared \
        --disable-debug --disable-examples --disable-docs --disable-install-bins  && \
        make && \
        make install && \
        rm -rf ${DIR}
### libwebp https://developers.google.com/speed/webp/
RUN \
        DIR=/tmp/vebp && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sL https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-${WEBP_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        ./configure --prefix="${PREFIX}" --enable-shared  && \
        make && \
        make install && \
        rm -rf ${DIR}
### libmp3lame http://lame.sourceforge.net/
RUN \
        DIR=/tmp/lame && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sL https://versaweb.dl.sourceforge.net/project/lame/lame/$(echo ${LAME_VERSION} | sed -e 's/[^0-9]*\([0-9]*\)[.]\([0-9]*\)[.]\([0-9]*\)\([0-9A-Za-z-]*\)/\1.\2/')/lame-${LAME_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        ./configure --prefix="${PREFIX}" --bindir="${PREFIX}/bin" --enable-shared --enable-nasm --disable-frontend && \
        make && \
        make install && \
        rm -rf ${DIR}
### xvid https://www.xvid.com/
#RUN \
  #      DIR=/tmp/xvid && \
    #    mkdir -p ${DIR} && \
    #    cd ${DIR} && \
    #    curl -sLO https://downloads.xvid.com/downloads/xvidcore-1.3.7.tar.gz && \
     #  tar -zx -f xvidcore-1.3.7.tar.gz && \
     #   cd xvidcore/build/generic && \
     #   ./configure --prefix="${PREFIX}" --bindir="${PREFIX}/bin" && \
     #   make && \
      #  make install && \
      #  rm -rf ${DIR}
### fdk-aac https://github.com/mstorsjo/fdk-aac
RUN \
        DIR=/tmp/fdk-aac && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sL https://github.com/mstorsjo/fdk-aac/archive/v${FDKAAC_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        autoreconf -fiv && \
        ./configure --prefix="${PREFIX}" --enable-shared --datadir="${DIR}" && \
        make && \
        make install && \
        rm -rf ${DIR}
## openjpeg https://github.com/uclouvain/openjpeg
RUN \
        DIR=/tmp/openjpeg && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sL https://github.com/uclouvain/openjpeg/archive/v${OPENJPEG_VERSION}.tar.gz | \
        tar -zx --strip-components=1 && \
        cmake -DBUILD_THIRDPARTY:BOOL=ON -DCMAKE_INSTALL_PREFIX="${PREFIX}" . && \
        make && \
        make install && \
        rm -rf ${DIR}
## freetype https://www.freetype.org/
RUN  \
        DIR=/tmp/freetype && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://de.freedif.org/savannah/freetype/freetype-2.11.1.tar.gz && \        
        tar -zx --strip-components=1 -f freetype-2.11.1.tar.gz && \
        ./configure --prefix="${PREFIX}" --disable-static --enable-shared && \
        make && \
        make install && \
        rm -rf ${DIR}
## libvstab https://github.com/georgmartius/vid.stab
RUN  \
        DIR=/tmp/vid.stab && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://github.com/georgmartius/vid.stab/archive/v${LIBVIDSTAB_VERSION}.tar.gz && \
        echo ${LIBVIDSTAB_SHA256SUM} | sha256sum --check &&  \
        tar -zx --strip-components=1 -f v${LIBVIDSTAB_VERSION}.tar.gz && \
        cmake -DCMAKE_INSTALL_PREFIX="${PREFIX}" . && \
        make && \
        make install && \
        rm -rf ${DIR}
## fridibi https://www.fribidi.org/
RUN  \
        DIR=/tmp/fribidi && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://github.com/fribidi/fribidi/archive/${FRIBIDI_VERSION}.tar.gz && \
        echo ${FRIBIDI_SHA256SUM} | sha256sum --check && \
        tar -zx --strip-components=1 -f ${FRIBIDI_VERSION}.tar.gz && \
        sed -i 's/^SUBDIRS =.*/SUBDIRS=gen.tab charset lib bin/' Makefile.am && \
        ./bootstrap --no-config --auto && \
        ./configure --prefix="${PREFIX}" --disable-static --enable-shared && \
        make -j1 && \
        make install && \
        rm -rf ${DIR}
## fontconfig https://www.freedesktop.org/wiki/Software/fontconfig/
RUN  \
        DIR=/tmp/fontconfig && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://www.freedesktop.org/software/fontconfig/release/fontconfig-${FONTCONFIG_VERSION}.tar.bz2 && \
        tar -jx --strip-components=1 -f fontconfig-${FONTCONFIG_VERSION}.tar.bz2 && \
        ./configure --prefix="${PREFIX}" --disable-static --enable-shared && \
        make && \
        make install && \
        rm -rf ${DIR}
## libass https://github.com/libass/libass
#RUN  \
      #  DIR=/tmp/libass && \
     #   mkdir -p ${DIR} && \
     #   cd ${DIR} && \
      #  curl -sLO https://github.com/libass/libass/releases/download/0.15.2/libass-0.15.2.tar.gz && \
      #  tar -zx --strip-components=1 -f libass-0.15.2.tar.gz && \
      #  ./autogen.sh && \
      #  ./configure --prefix="${PREFIX}" --disable-static --enable-shared && \
      #  make && \
      #  make install && \
      #  rm -rf ${DIR}
	  
	  RUN     apt-get install libass-dev -y
	  
	  
## kvazaar https://github.com/ultravideo/kvazaar
RUN \
        DIR=/tmp/kvazaar && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://github.com/ultravideo/kvazaar/archive/v${KVAZAAR_VERSION}.tar.gz && \
        tar -zx --strip-components=1 -f v${KVAZAAR_VERSION}.tar.gz && \
        ./autogen.sh && \
        ./configure --prefix="${PREFIX}" --disable-static --enable-shared && \
        make && \
        make install && \
        rm -rf ${DIR}

RUN \
	DIR=/tmp/aom && \
        git clone --branch ${AOM_VERSION} --depth 1 https://aomedia.googlesource.com/aom ${DIR} ; \
        cd ${DIR} ; \
        rm -rf CMakeCache.txt CMakeFiles ; \
        mkdir -p ./aom_build ; \
        cd ./aom_build ; \
        cmake -DCMAKE_INSTALL_PREFIX="${PREFIX}" -DBUILD_SHARED_LIBS=1 ..; \
        make ; \
        make install ; \
        rm -rf ${DIR}

## libxcb (and supporting libraries) for screen capture https://xcb.freedesktop.org/
RUN \
        DIR=/tmp/xorg-macros && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://www.x.org/archive//individual/util/util-macros-${XORG_MACROS_VERSION}.tar.gz && \
        tar -zx --strip-components=1 -f util-macros-${XORG_MACROS_VERSION}.tar.gz && \
        ./configure --srcdir=${DIR} --prefix="${PREFIX}" && \
        make && \
        make install && \
        rm -rf ${DIR}

RUN \
        DIR=/tmp/xproto && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://www.x.org/archive/individual/proto/xproto-${XPROTO_VERSION}.tar.gz && \
        tar -zx --strip-components=1 -f xproto-${XPROTO_VERSION}.tar.gz && \
        ./configure --srcdir=${DIR} --prefix="${PREFIX}" && \
        make && \
        make install && \
        rm -rf ${DIR}

RUN \
        DIR=/tmp/libXau && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://www.x.org/archive/individual/lib/libXau-${XAU_VERSION}.tar.gz && \
        tar -zx --strip-components=1 -f libXau-${XAU_VERSION}.tar.gz && \
        ./configure --srcdir=${DIR} --prefix="${PREFIX}" && \
        make && \
        make install && \
        rm -rf ${DIR}

RUN \
        DIR=/tmp/libpthread-stubs && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://xcb.freedesktop.org/dist/libpthread-stubs-${LIBPTHREAD_STUBS_VERSION}.tar.gz && \
        tar -zx --strip-components=1 -f libpthread-stubs-${LIBPTHREAD_STUBS_VERSION}.tar.gz && \
        ./configure --prefix="${PREFIX}" && \
        make && \
        make install && \
        rm -rf ${DIR}

RUN \
        DIR=/tmp/libxcb-proto && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://xcb.freedesktop.org/dist/xcb-proto-${XCBPROTO_VERSION}.tar.gz && \
        tar -zx --strip-components=1 -f xcb-proto-${XCBPROTO_VERSION}.tar.gz && \
        ACLOCAL_PATH="${PREFIX}/share/aclocal" ./autogen.sh && \
        ./configure --prefix="${PREFIX}" && \
        make && \
        make install && \
        rm -rf ${DIR}

RUN \
        DIR=/tmp/libxcb && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://xcb.freedesktop.org/dist/libxcb-${LIBXCB_VERSION}.tar.gz && \
        tar -zx --strip-components=1 -f libxcb-${LIBXCB_VERSION}.tar.gz && \
        ACLOCAL_PATH="${PREFIX}/share/aclocal" ./autogen.sh && \
        ./configure --prefix="${PREFIX}" --disable-static --enable-shared && \
        make && \
        make install && \
        rm -rf ${DIR}

## libxml2 - for libbluray
RUN \
        DIR=/tmp/libxml2 && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO http://xmlsoft.org/download/libxml2-2.9.12.tar.gz && \
        tar -xz --strip-components=1 -f libxml2-2.9.12.tar.gz && \
        ./autogen.sh --prefix="${PREFIX}" --with-ftp=no --with-http=no --with-python=no && \
        make && \
        make install && \
        rm -rf ${DIR}


## libbluray - Requires libxml, freetype, and fontconfig
RUN \
        DIR=/tmp/libbluray && \
        mkdir -p ${DIR} && \
        cd ${DIR} && \
        curl -sLO https://download.videolan.org/pub/videolan/libbluray/${LIBBLURAY_VERSION}/libbluray-${LIBBLURAY_VERSION}.tar.bz2 && \
        echo ${LIBBLURAY_SHA256SUM} | sha256sum --check && \
        tar -jx --strip-components=1 -f libbluray-${LIBBLURAY_VERSION}.tar.bz2 && \
        ./configure --prefix="${PREFIX}" --disable-examples --disable-bdjava-jar --disable-static --enable-shared && \
        make && \
        make install && \
         rm -rf ${DIR}

## ffmpeg https://ffmpeg.org/
RUN  \
        DIR=/tmp/ffmpeg && mkdir -p ${DIR} && cd ${DIR} && \
        curl -sLO https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.bz2 && \
        tar -jx --strip-components=1 -f ffmpeg-${FFMPEG_VERSION}.tar.bz2
		

RUN		apt-get install -y	libmp3lame-dev libopencore-amrnb-dev libopencore-amrnb-dev libtheora-dev libxvidcore-dev

RUN \
        DIR=/tmp/ffmpeg && mkdir -p ${DIR} && cd ${DIR} && \
        ./configure \
        --disable-debug \
        --disable-doc \
        --disable-ffplay \
        --enable-shared \
        --enable-avresample \
        --enable-libopencore-amrnb \
        #--enable-libopencore-amrwb \
        --enable-gpl \
        --enable-libass \
        --enable-fontconfig \
        --enable-libfreetype \
        --enable-libvidstab \
        --enable-libmp3lame \
        --enable-libopus \
        --enable-libtheora \
        --enable-libvorbis \
        --enable-libvpx \
        --enable-libwebp \
        --enable-libxcb \
        --enable-libx265 \
        --enable-libxvid \
        --enable-libx264 \
        --enable-nonfree \
        --enable-openssl \
        --enable-libfdk_aac \
        --enable-postproc \
        --enable-small \
        --enable-version3 \
        --enable-libbluray \
        --extra-libs=-ldl \
        --prefix="${PREFIX}" \
        --enable-libopenjpeg \
        --enable-libkvazaar \
        --enable-libaom \
        --extra-libs=-lpthread \
        --enable-nvenc \
        --enable-cuda \
        --enable-cuvid \
        #--enable-libnpp \
        --extra-cflags="-I${PREFIX}/include -I${PREFIX}/include/ffnvcodec" && \        
        make && \
        make install && \
        make distclean && \
        hash -r && \
        cd tools && \
        make qt-faststart && \
        cp qt-faststart ${PREFIX}/bin

## cleanup
RUN \
        LD_LIBRARY_PATH="${PREFIX}/lib:${PREFIX}/lib64:${LD_LIBRARY_PATH}" ldd ${PREFIX}/bin/ffmpeg | grep opt/ffmpeg | cut -d ' ' -f 3 | xargs -i cp {} /usr/local/lib/ && \
        cp ${PREFIX}/bin/* /usr/local/bin/ && \
        cp -r ${PREFIX}/share/* /usr/local/share/ && \
        LD_LIBRARY_PATH=/usr/local/lib ffmpeg -buildconf
		
RUN		apt-get install -y	libvpx-dev libopus-dev
		
	RUN \
 echo "**** compile tvheadend ****" && \
 mkdir -p \
	/tmp/tvheadend && \
 git clone https://github.com/Gee1111/tvheadend.git /tmp/tvheadend && \
 cd /tmp/tvheadend && \
 ./configure \
	`#Encoding` \
	--no-cache \
	--disable-ffmpeg_static \
	--disable-libfdkaac_static \
	--disable-libtheora_static \
	--disable-libopus_static \
	--disable-libvorbis_static \
	--disable-libvpx_static \
	--disable-libx264_static \
	--disable-libx265_static \
	--disable-libfdkaac \
	--enable-libopus \
	--enable-libvorbis \
	--enable-libvpx \
	--enable-libx264 \
	--enable-libx265 \
	\
	`#Options` \
	--disable-avahi \
	--disable-dbus_1 \
	--disable-bintray_cache \
	--disable-hdhomerun_static \
	--enable-hdhomerun_client \
	--enable-libav \
	--enable-pngquant \
	--enable-trace \
	--enable-cuvid \
	--enable-cuda-nvcc
	--enable-nvenc \
	--enable-cuda-llvm \
	--enable-libnpp \
	--infodir=/usr/share/info \
	--localstatedir=/var \
	--mandir=/usr/share/man \
	--prefix=/usr \
	--sysconfdir=/config && \
 make -j 12 && \
 make DESTDIR=/tmp/tvheadend-build install	
 
 RUN \
 echo "***** compile comskip ****" && \
 git clone git://github.com/erikkaashoek/Comskip /tmp/comskip && \
 cd /tmp/comskip && \
 ./autogen.sh && \
 ./configure \
	--bindir=/usr/bin \
	--sysconfdir=/config/comskip && \
 make -j 12 && \
 make DESTDIR=/tmp/comskip-build install
 

FROM        ubuntu:20.10 AS release
MAINTAINER  Gee

ENV         LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64:/usr/lib:/usr/lib64:/lib:/lib64

COPY --from=build /usr/local/ /usr/local/
COPY --from=build /tmp/comskip-build/usr/ /usr/
COPY --from=build /tmp/tvheadend-build/usr/ /usr/
COPY --from=build /usr/local/share/man/ /usr/local/share/man/

#### install runtime librarys ###########
RUN  	apt-get update && \
		apt-get install -y --no-install-recommends libargtable2-dev \
		libhdhomerun-dev \
		gettext \
		libdvbcsa-dev \
		nano \
		libnpp \
		libass9 \
		libtheora-dev \
		libxvidcore4 \
		# x264 \
		# x265 \
		xmltv && \		
		apt-get autoremove -y && \
        apt-get clean -y
		
ENV HOME="/config"

# RUN useradd -ms /bin/bash hts

# RUN	mkdir -p /config /records && \
#	chown -R hts:bin /config /records

# USER hts

EXPOSE 9981 9982
VOLUME /config /records

ENTRYPOINT ["/usr/bin/tvheadend"]
CMD ["-C","-c","/config"]
