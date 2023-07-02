export KV_DIR = $(shell pwd)/../

ifeq ($(KV_DIR),)
$(error KV_DIR is not defined)
endif

ifeq ($(wildcard $(KV_DIR)),)
$(error KV_DIR points to an invalid location)
endif

DPDK_VERSION=$(shell cat $(KV_DIR)/vend/spdk/dpdk/VERSION)
SPDK_VERSION=$(shell git -C $(KV_DIR)/vend/spdk rev-parse HEAD)

# Debug Binary
CONFIG_DEBUG=n
# KV NVMe Driver Log Level
# 1. Error, 2. Warning, 3. Info, 4. Debug
CONFIG_KVNVME_LOG_LEVEL=3

LIB = lib_kv_interface.a
LIB_BDEV = lib_bdev_mpdk.a
C_SRCS = src/kv_driver.c src/kv_interface.c src/kv_cmd.c src/lba_cmd.c src/kv_io.c src/lba_io.c src/kv_util.c src/kv_version.c

SDK_INCLUDE = $(KV_DIR)/sdk/include
COMMON_INCLUDE = $(KV_DIR)/common
KV_LIBS = -lm -pthread -lrt -ldl -lnuma -luuid
OBJS = $(C_SRCS:.c=.o)
LINK_C = $(CC) -o $@ $(LDFLAGS) $(OBJS) $(LIBS)
LIB_C = ar crDs $@ $(OBJS)
CFLAGS += -Wall -Wextra -Wno-unused-parameter -march=native -m64 -I$(KV_DIR)/driver/include -D_GNU_SOURCE -fPIC -std=gnu99 -I$(SDK_INCLUDE) -I$(KV_DIR)/vend/spdk/include -I$(COMMON_INCLUDE)

ifeq ($(CONFIG_DEBUG),y)
CFLAGS += -g -O0
LDFLAGS += -O0
DEBUG=y
else
CFLAGS += -O2
LDFLAGS += -O2
DEBUG=n
endif

ifndef ($(CONFIG_KV_LOG_LEVEL))
CFLAGS += -DKVNVME_LOG_LEVEL=$(CONFIG_KVNVME_LOG_LEVEL)
endif

ifeq ($(CONFIG_LBA_SSD), y)
CFLAGS += -DLBA_SSD
endif

LDFLAGS+= -Wl,-z,relro,-z,now -Wl,-z,noexecstack

buildtime=$(shell date +%Y_%m%d_%H%M)
hash=$(shell git log -1 --format="%H")
os=$(shell uname -o)
processor=$(shell uname -p)
kernel=$(shell uname -r)


all : version $(LIB_BDEV) $(LIB)
	rm -rf temp
	mkdir temp
	pushd temp
	cp $(KV_DIR)/build/dpdk/lib/librte_eal.a .
	cp $(KV_DIR)/build/dpdk/lib/librte_mempool.a .
	cp $(KV_DIR)/build/dpdk/lib/librte_ring.a .
	cp $(KV_DIR)/build/dpdk/lib/librte_pci.a .
	cp $(KV_DIR)/build/dpdk/lib/librte_bus_pci.a .
	cp $(KV_DIR)/build/spdk/lib/libspdk_env_dpdk.a .
	cp $(KV_DIR)/build/spdk/lib/libspdk_log.a .
	cp $(KV_DIR)/build/spdk/lib/libspdk_nvme.a .
	cp $(KV_DIR)/build/spdk/lib/libspdk_util.a .
	cp $(KV_DIR)/build/spdk/lib/libspdk_json.a .
	cp $(KV_DIR)/build/spdk/lib/libspdk_bdev_nvme.a .
	ar -x libspdk_bdev_nvme.a
	ar -r libspdk_bdev_nvme.a bdev*.o lba_bdev.o
	rm -f bdev*.o lba_bdev.o
# TODO What is this for?
	mv libspdk_bdev_nvme.a $(KV_DIR)/build/spdk/lib/
	ar -x $(LIB)
	ar -x librte_eal.a
	ar -x librte_mempool.a
	ar -x librte_ring.a
	ar -x librte_pci.a
	ar -x librte_bus_pci.a
	mv pci.o pci_bus.o
	ar -x libspdk_env_dpdk.a
	ar -x libspdk_log.a
	ar -x libspdk_nvme.a
	ar -x libspdk_util.a
	ar -x libspdk_json.a
	ar -r $(KV_LIB) *.o
	rm -f librte_eal.a librte_mempool.a librte_ring.a librte_pci.a librte_bus_pci.a libspdk_env_dpdk.a libspdk_log.a libspdk_nvme.a libspdk_util.a libspdk_json.a $(LIB)
	rm -f *.o
	popd

version :
	$(shell echo '#include "kv_version.h"' > src/kv_version.c)
	$(shell echo '' >> src/kv_version.c)
	$(shell echo 'const char* buildtime="$(buildtime)";' >> src/kv_version.c)
	$(shell echo 'const char* hash="$(hash)";' >> src/kv_version.c)
	$(shell echo 'const char* os="$(os)";' >> src/kv_version.c)
	$(shell echo 'const char* processor="$(processor)";' >> src/kv_version.c)
	$(shell echo 'const char* kernel="$(kernel)";' >> src/kv_version.c)
	$(shell echo 'const char* dpdk_version="$(DPDK_VERSION)";' >> src/kv_version.c)
	$(shell echo 'const char* spdk_version="$(SPDK_VERSION)";' >> src/kv_version.c)
	$(CC) $(CFLAGS) -c src/kv_version.c

$(LIB_BDEV) :
	$(CC) $(CFLAGS) -c src/lba_bdev.c

clean :
ifeq ($(DEBUG),y)
	rm -f $(KV_DIR)/build/driver/debug/lib/$(KV_LIB)
	rm -f $(KV_DIR)/build/driver/debug/include/*.h
else
	rm -f $(KV_DIR)/build/driver/release/lib/$(KV_LIB)
	rm -f $(KV_DIR)/build/driver/release/include/*.h
endif

install:
ifeq ($(DEBUG),y)
	mkdir -p $(KV_DIR)/build/driver/debug
	cp temp/$(KV_LIB) $(KV_DIR)/build/driver/debug/lib/
	cp $(KV_DIR)/driver/include/* $(KV_DIR)/build/driver/debug/include/
else
	mkdir -p $(KV_DIR)/build/driver/release
	cp temp/$(KV_LIB) $(KV_DIR)/build/release/lib/
	cp $(KV_DIR)/driver/include/* $(KV_DIR)/build/driver/release/include/
endif

$(LIB) : $(OBJS)
	$(LIB_C)
