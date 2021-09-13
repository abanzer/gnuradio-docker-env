FROM ubuntu:focal

# Utilities and libraries (GRC has a lot of dependencies)
RUN apt update && \
	DEBIAN_FRONTEND="noninteractive" apt install -y \
	cmake \
	doxygen \
	g++ \
	gir1.2-gtk-3.0 \
	git \
	libboost-all-dev \
	libfftw3-dev \
	libgmp3-dev \
	liblog4cpp5-dev \
	libqwt-qt5-dev \
	libsoapysdr-dev \
	libsoapysdr0.7 \
	libzmq3-dev \
	libgsl-dev \
	libiio-dev \
	libad9361-dev \
	libsoapysdr-dev \
	soapysdr-tools \
	libsndfile1-dev \
	portaudio19-dev \
	python3-click-plugins \
	python3-distutils \
	python3-gi-cairo \
	python3-mako \
	python3-numpy \
	python3-pip \
	#python3-pyqt5 \
	python3-pyqtgraph \
	python3-scipy \
	python3-yaml \
	qtbase5-dev \
	clang-format \
	pulseaudio \
	vim \
	socat \
	gqrx-sdr \
	wsjtx

RUN apt install -y --no-install-recommends libuhd-dev

# Pip dependencies
RUN pip3 install "pybind11[global]" pygccxml
RUN pip3 install pyzmq
RUN pip3 install PyQt5==5.13.2
RUN pip3 install pyserial

# Add root user to group for pulseaudio access
RUN adduser root pulse-access

# Make folder, add GRC files, & move .asoundrc to home directory
RUN mkdir GRC
COPY Final* GRC/
RUN cd GRC/ && mv .asoundrc ~/.asoundrc && cd ..

# Volk
RUN mkdir src/ && cd src/ && \
	git clone --recursive https://github.com/gnuradio/volk.git && \
	cd volk && mkdir build && cd build && \
	cmake -DCMAKE_BUILD_TYPE=Release -DPYTHON_EXECUTABLE=/usr/bin/python3 ../ \
	&& make && make test && make install

# Configure the paths required to run GR
ENV GR_PREFIX=/root/gr_prefix
WORKDIR $GR_PREFIX
RUN PYSITEDIR=$(python3 -m site --user-site) && \
	mkdir -p "$PYSITEDIR" && \
	echo "$GR_PREFIX/lib/python3/dist-packages/" > "$PYSITEDIR/gnuradio.pth"
RUN echo "$GR_PREFIX/lib/" >> /etc/ld.so.conf.d/gnuradio.conf
RUN echo "export PATH=$GR_PREFIX/bin/:${PATH}" >> /root/.bashrc

# Change the entrypoint to run ldconfig on startup
ADD entrypoint.sh /bin/entrypoint
RUN chmod +x /bin/entrypoint
ENTRYPOINT ["/bin/entrypoint"]
CMD ["/bin/bash"]
