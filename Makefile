#
# Build script for Linux workstation and
# Anselm cluster http://www.it4i.cz/
#

include Makefile.inc

all: $(LIBOFFLOADMIC_HOST) $(INSTALL_PREFIX)/host/lib/$(TOOLEXECLIBDIR)/libmicrt.so $(INSTALL_PREFIX)/host/include/mic_runtime.h

$(TARGET_LIB_PATH)/libintrinsics.a: intrinsics/build_mic/intrinsics.o
	$(LOAD_GCC_MODULE) && mkdir -p $(TARGET_LIB_PATH) && ar rcs $@ $<

intrinsics/build_mic/intrinsics.o: intrinsics/intrinsics.c
	$(LOAD_ICC_MODULE) && mkdir -p intrinsics/build_mic && icc -mmic -c $< -o $@

$(LIBOFFLOADMIC_HOST): $(DEPENDS_ON_INTRINSICS_OR_NOT)
	$(LOAD_GCC_MODULE) && cd libgomp && \
	mkdir -p build_mic && \
	cd build_mic && \
	../configure --disable-multilib --build=x86_64-intelmic-linux-gnu --host=k1om-intelmic-linux-gnu --target=k1om-intelmic-linux-gnu CC="$(MIC_CC) $(MIC_CFLAGS)" CXX="$(MIC_CXX) $(MIC_CXXFLAGS)" --prefix=$(INSTALL_PREFIX)/mic && \
	make -j12 && \
	make install && \
	cd .. && \
	mkdir -p build_host && \
	cd build_host && \
	../configure --disable-multilib --build=x86_64-pc-linux-gnu --host=x86_64-pc-linux-gnu --target=x86_64-pc-linux-gnu CC="$(HOST_CC) $(HOST_CFLAGS)" CXX="$(HOST_CXX) $(HOST_CXXFLAGS)" --prefix=$(INSTALL_PREFIX)/host && \
	make -j12 && \
	make install && \
	cd ../.. && \
	cd liboffloadmic && \
	mkdir -p build_mic && \
	cd build_mic && \
	../configure --disable-multilib --build=x86_64-intelmic-linux-gnu --host=k1om-intelmic-linux-gnu --target=x86_64-intelmic-linux-gnu --enable-as-accelerator-for=x86_64-pc-linux-gnu --enable-liboffloadmic=target CC="$(MIC_CC) $(MIC_CFLAGS)" CXX="$(MIC_CXX) $(MIC_CXXFLAGS)" --prefix=$(INSTALL_PREFIX)/mic && \
	make -j12 && \
	make install && \
	cd .. && \
	$(REMOVE_LIBCOI_DEVICE) && \
	mkdir -p build_host && \
	cd build_host && \
	../configure --disable-multilib --build=x86_64-pc-linux-gnu --host=x86_64-pc-linux-gnu --target=x86_64-pc-linux-gnu --enable-liboffloadmic=host CC="$(HOST_CC) $(HOST_CFLAGS)" CXX="$(HOST_CXX) $(HOST_CXXFLAGS)" --prefix=$(INSTALL_PREFIX)/host --enable-offload-targets=x86_64-intelmic-linux-gnu=$(INSTALL_PREFIX)/host && \
	make -j12 && \
	make install && \
	cd ../.. && \
	$(REMOVE_LIBCOI_HOST)

$(INSTALL_PREFIX)/host/include/mic_runtime.h: libmicrt/mic_runtime.h
	mkdir -p $(INSTALL_PREFIX)/host/include && cp $< $@

$(INSTALL_PREFIX)/host/lib/$(TOOLEXECLIBDIR)/libmicrt.so: libmicrt/build_host/micrt.o $(LIBOFFLOADMIC_HOST)
	$(LOAD_GCC_MODULE) && mkdir -p $(HOST_LIB_PATH) && $(HOST_CXX) $< -shared -o $@ -L$(INSTALL_PREFIX)/host/lib/$(TOOLEXECLIBDIR) -Bstatic -lgomp-plugin-intelmic -loffloadmic_host -Bdynamic -lpthread

libmicrt/build_host/micrt.o: libmicrt/micrt.cpp libmicrt/mic_runtime.h
	$(LOAD_GCC_MODULE) && mkdir -p libmicrt/build_host && $(HOST_CXX) $(HOST_CXXFLAGS) -I. -Ilibmicrt -c -fPIC $< -o $@

clean:
	rm -rf install && \
	rm -rf intrinsics/build_mic && \
	rm -rf libmicrt/build_host && \
	rm -rf liboffloadmic/build_mic && \
	rm -rf liboffloadmic/build_host && \
	rm -rf libgomp/build_mic && \
	rm -rf libgomp/build_host

