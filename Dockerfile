FROM    ubuntu:20.04 AS devel-base

ENV	    NVIDIA_DRIVER_CAPABILITIES compat32,compute,video
WORKDIR     /tmp/workdir

RUN     apt-get -yqq update && \
        apt-get install -yq --no-install-recommends ca-certificates expat libgomp1 && \
        apt-get autoremove -y && \
        apt-get clean -y

FROM        ubuntu:20.04 AS runtime-base

ENV	    NVIDIA_DRIVER_CAPABILITIES compat32,compute,video
WORKDIR     /tmp/workdir

RUN     apt-get -yqq update && \
        apt-get install -yq --no-install-recommends ca-certificates expat libgomp1 libxcb-shape0-dev && \
        apt-get autoremove -y && \
        apt-get clean -y

FROM  devel-base as build
     
ENV         FFMPEG_VERSION=5.0 \
            AOM_VERSION=v3.2.0 \
            FDKAAC_VERSION=2.0.2 \
            FONTCONFIG_VERSION=2.13.94 \
            FREETYPE_VERSION=2.11.1 \ 
            FRIBIDI_VERSION=1.0.11 \
            KVAZAAR_VERSION=2.1.0 \
            LAME_VERSION=3.100 \
            LIBASS_VERSION=0.15.2 \ 
            LIBPTHREAD_STUBS_VERSION=1.14 \
            LIBVIDSTAB_VERSION=1.1.0 \
            LIBXCB_VERSION=1.14 \
            XCBPROTO_VERSION=1.14 \
            OPENCOREAMR_VERSION=0.1.5 \
            OPUS_VERSION=1.3 \
            OPENJPEG_VERSION=2.4.0 \
            VORBIS_VERSION=1.3.7 \
            VPX_VERSION=1.11.0 \
            WEBP_VERSION=1.2.1 \
            X264_VERSION=20191217-2245-stable \
            X265_VERSION=3.2.1 \ 
            XAU_VERSION=1.7.3.1 \
            XORG_MACROS_VERSION=1.19.3 \
            XPROTO_VERSION=7.0.31 \     
			NVIDIA_HEADERS_VERSION=11.1.5.1 \
            LIBBLURAY_VERSION=1.3.0 \
            SRC=/usr/local

ARG         FRIBIDI_SHA256SUM="3fc96fa9473bd31dcb5500bdf1aa78b337ba13eb8c301e7c28923fea982453a8 0.19.7.tar.gz"
ARG         LIBVIDSTAB_SHA256SUM="14d2a053e56edad4f397be0cb3ef8eb1ec3150404ce99a426c4eb641861dc0bb v1.1.0.tar.gz"
ARG         OGG_SHA256SUM="fe5670640bd49e828d64d2879c31cb4dde9758681bb664f9bdbf159a01b0c76e libogg-1.3.4.tar.gz"
ARG         OPUS_SHA256SUM="77db45a87b51578fbc49555ef1b10926179861d854eb2613207dc79d9ec0a9a9 opus-1.2.tar.gz"
ARG         VORBIS_SHA256SUM="6efbcecdd3e5dfbf090341b485da9d176eb250d893e3eb378c428a2db38301ce libvorbis-1.3.5.tar.gz"
ARG         LIBXML2_SHA256SUM="f07dab13bf42d2b8db80620cce7419b3b87827cc937c8bb20fe13b8571ee9501  libxml2-v2.9.10.tar.gz"
ARG         LIBBLURAY_SHA256SUM="a3dd452239b100dc9da0d01b30e1692693e2a332a7d29917bf84bb10ea7c0b42 libbluray-1.1.2.tar.bz2"


ARG         LD_LIBRARY_PATH=/opt/ffmpeg/lib
ARG         MAKEFLAGS="-j16"
ARG         PKG_CONFIG_PATH="/opt/ffmpeg/share/pkgconfig:/opt/ffmpeg/lib/pkgconfig:/opt/ffmpeg/lib64/pkgconfig"
ARG         PREFIX=/opt/ffmpeg
ARG         LD_LIBRARY_PATH="/opt/ffmpeg/lib:/opt/ffmpeg/lib64:/usr/lib64:/usr/lib"

RUN		chmod 777 /var/cache/debconf/ 
RUN		chmod 777 /var/cache/debconf/passwords.dat
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
		libhdhomerun-dev \
		libargtable2-dev \
                    zlib1g-dev" && \
        apt-get -yqq update && \
        apt-get install -yq --no-install-recommends ${buildDeps}
		
RUN \	
	git clone https://github.com/Gee1111/libdvbcsa /tmp/libdvbcsa && \
	cd /tmp/libdvbcsa && \
	# git config apply.whitespace nowarn && \
	git apply -v libdvbcsa.patch && \
	./bootstrap && \
	./configure \
    --prefix=/usr \
    --sysconfdir=/etc \
  --mandir=/usr/share/man \
  --infodir=/usr/share/info \
  --localstatedir=/var && \	
	make && \
 make check && \
 make DESTDIR=/tmp/libdvbcsa-build install && \
        echo "**** copy to /usr for tvheadend dependency ****" && \
 cp -pr /tmp/libdvbcsa-build/usr/* /usr/


ENV	NVIDIA_HEADERS_VERSION=11.1.5.2

RUN \
	DIR=/tmp/nv-codec-headers && \
	git clone https://github.com/FFmpeg/nv-codec-headers ${DIR} && \
	cd ${DIR} && \
	git checkout n${NVIDIA_HEADERS_VERSION} && \
	make PREFIX="${PREFIX}" && \
	make install PREFIX="${PREFIX}" && \
        rm -rf ${DIR}

## opencore-amr https://sourceforge.net/projects/opencore-amr/
        
# x264 http://www.videolan.org/developers/x264.html
RUN 	apt install -y libopencore-amrnb-dev libopencore-amrwb-dev libogg-dev libopus-dev libvorbis-dev libtheora-dev libvpx-dev libwebp-dev libmp3lame-dev libxvidcore-dev libfdk-aac-dev libopenjp2-7-dev libfreetype-dev libvidstab-dev libfreetype6-dev libfribidi-dev python3 fontconfig libass-dev libprotozero-dev libxau-dev libxml2 libbluray-dev libaom-dev libxcb1-dev libpthread-stubs0-dev libx264-dev libx265-dev
### x265 http://x265.org/

### libogg https://www.xiph.org/ogg/

### libopus https://www.opus-codec.org/

### libvorbis https://xiph.org/vorbis/

### libtheora http://www.theora.org/

### libvpx https://www.webmproject.org/code/

### libwebp https://developers.google.com/speed/webp/

### libmp3lame http://lame.sourceforge.net/

### xvid https://www.xvid.com/

### fdk-aac https://github.com/mstorsjo/fdk-aac

## openjpeg https://github.com/uclouvain/openjpeg

## freetype https://www.freetype.org/

## libvstab https://github.com/georgmartius/vid.stab
		
## fridibi https://www.fribidi.org/
	  
## fontconfig https://www.freedesktop.org/wiki/Software/fontconfig/

## libass https://github.com/libass/libass	  
	  
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

## libxcb (and supporting libraries) for screen capture https://xcb.freedesktop.org/

## libxml2 - for libbluray

## libbluray - Requires libxml, freetype, and fontconfig

RUN	apt install -y nvidia-cuda-toolkit

## ffmpeg https://ffmpeg.org/
ENV         FFMPEG_VERSION=4.4.3
RUN  \
        DIR=/tmp/ffmpeg && mkdir -p ${DIR} && cd ${DIR} && \
	curl -sLO https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.bz2 && \
        tar -jx --strip-components=1 -f ffmpeg-${FFMPEG_VERSION}.tar.bz2
	
RUN \
        DIR=/tmp/ffmpeg && mkdir -p ${DIR} && cd ${DIR} && \	
        ./configure \	
	--nvccflags="-gencode arch=compute_35,code=sm_35 -O2" \
        --disable-debug \
        --disable-doc \
        --disable-ffplay \
        --enable-shared \ 
	--enable-avresample \
        --enable-libopencore-amrnb \
        --enable-libopencore-amrwb \
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
	--enable-cuda-nvcc \
        --enable-libnpp \
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
		
RUN		apt-get install -y libvpx-dev libopus-dev libavresample-dev libva-dev liburiparser-dev libiconv-hook-dev
		
	RUN \
 echo "**** compile tvheadend ****" && \
 mkdir -p \
	/tmp/tvheadend && \
 git clone https://github.com/Gee1111/tvheadend.git /tmp/tvheadend && \
 cd /tmp/tvheadend && \
 ## git checkout 4deae00a11e92e6c19da4fd1bae48ef7f124c67b && \
 git apply -v tvheadend43.patch && \
  
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
	--enable-nvenc \
	--enable-cuda-llvm \
	--enable-cuda-nvcc \
	--enable-libnpp \
	--infodir=/usr/share/info \
	--localstatedir=/var \
	--mandir=/usr/share/man \
	--prefix=/usr \
	--sysconfdir=/config && \
 make -j 16 && \
 make DESTDIR=/tmp/tvheadend-build install	
 
 #RUN \
 #echo "***** compile comskip ****" && \
 #git clone git://github.com/erikkaashoek/Comskip /tmp/comskip && \
 #cd /tmp/comskip && \
 #./autogen.sh && \
 #./configure \
#	--bindir=/usr/bin \
#	--sysconfdir=/config/comskip && \
 #make -j 16 && \
 #make DESTDIR=/tmp/comskip-build install
 

FROM        ubuntu:20.04 AS release
MAINTAINER  Gee

ENV         LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64:/usr/lib:/usr/lib64:/lib:/lib64

COPY --from=build /tmp/libdvbcsa-build/usr/ /usr/
COPY --from=build /usr/local/ /usr/local/
#COPY --from=build /tmp/comskip-build/usr/ /usr/
COPY --from=build /tmp/tvheadend-build/usr/ /usr/
COPY --from=build /usr/local/share/man/ /usr/local/share/man/


RUN apt-get update && \
    apt-get install -yq tzdata && \
    ln -fs /usr/share/zoneinfo/Europe/Berlin /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata


#### install runtime librarys ###########
RUN  	apt-get update && \
		apt-get install -y --no-install-recommends libargtable2-dev \
		libhdhomerun-dev \
		gettext \	
		nano \
		libass9 \
		libtheora-dev \
		libxvidcore4 \
		liburiparser1 \
		libva2 \
		libvidstab1.1 \
		libbluray2 \
		libvpx6 \
		libwebpmux3 \
		libopencore-amrwb0 \
		libopencore-amrnb0 \
		libaom0 \
		libfdk-aac1 \
		libmp3lame0 \
		libopenjp2-7 \
		libopus0 \
		libvorbis0a \
		libvorbisenc2 \
		libx264-155 \
		libx265-179 \
		bzip2 \		
		libnppig10 \
		libnppicc10 \
		libnppidei10 \
		libvdpau1 \
		xmltv && \		
		apt-get autoremove -y && \
        apt-get clean -y
		
ENV HOME="/config"

EXPOSE 9981 9982
VOLUME /config /records

ENTRYPOINT ["/usr/bin/tvheadend"]
CMD ["-C","-c","/config"]
