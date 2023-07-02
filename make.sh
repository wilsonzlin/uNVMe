#!/bin/bash

set -Eeuo pipefail

pushd "$(dirname "$0")" &>/dev/null

SDK=libuio.a

ROOT=$PWD

set_red(){
	echo -e "\033[31m"
}
set_green(){
	echo -e "\033[32m"
}

set_white(){
	echo -e "\033[0m"
}

log_normal() {
	set_green && echo $1 && set_white
}

log_error() {
	set_red && echo $1 && set_white
}

build_driver() {
	pushd driver
	make clean && make
	ret=$?
	popd
	if [ $ret = 0 ]; then
		log_normal "[Build Driver].. Done"
	else
		log_error "[Build Driver].. Error"
	fi
	return $ret
}

build_io() {
	log_normal "[Build IO]"
	cd io

	if [ -f "deps/check-0.9.8" ]; then
		cd deps/check-0.9.8/
		if [ ! -f "./lib/.libs/libcompat.a" ]; then
			./configure && make -j 4 && make install
		fi
		ret=$?
		cd ../..
		if [ $ret = 0 ]; then
			log_normal "[Build IO-check].. Done"
		else
			log_error "[Build IO-check].. Error"
			return $ret
		fi
	fi

	scons -c && scons
	ret=$?
	cd ..
	if [ $ret = 0 ]; then
		log_normal "[Build IO].. Done"
	else
		log_error "[Build IO].. Error"
	fi
	return $ret
}

build_all() {
	log_normal "[Build All]"
	build_driver && build_io && build_sdk
	ret=$?
	if [ $ret = 0 ]; then
		log_normal "[Build All].. Done"
	else
		log_error "[Build All].. Error"
	fi
	return $ret
}

build_sdk() {
	log_normal "[Build $SDK]"
	libudd=libkvnvmedd.a
	libio=libkvio.a
	rm -rf tmp bin/$SDK && mkdir -p bin tmp && cp driver/core/$libudd io/$libio tmp
	cd tmp
	ar -x $libudd
	ar -x $libio
	ar -r $SDK *.o 2>/dev/null
	ret=$?
	mv $SDK ../bin/
	rm -rf *.o *.a
	cd ..
	if [ $ret = 0 ]; then
		log_normal "[Build $SDK].. Done"
	else
		log_error "[Build $SDK].. Error"
	fi
	rm -rf tmp
	return $ret
}

clean() {
	log_normal "[Clean driver / io / sdk / app]"
	cd io && scons -c && cd ..
	cd driver && make clean && cd ..
	cd app
	cd fio_plugin && make clean && cd ..
	cd fuse && make clean && cd ..
	cd mkfs && make clean && cd ..
	cd unvme_rocksdb && make clean && cd ..
	cd ..
	rm -rf bin
	log_normal "[Clean driver / io / sdk / app].. Done"
}

case "$1" in
all)
	build_all
	;;
sdk)
	build_sdk
	;;
io)
	build_io
	;;
driver)
	build_driver
	;;
app)
	build_app
	;;
clean)
	clean
	;;
intel)
	build_intel
	;;
intel_clean)
	intel_clean
	;;
analysis)
	build_analysis
	;;
test)
	run_test
	;;

*)
	echo "Usage: make.sh {intel|all|io|driver|sdk|app|clean|intel_clean|test}"
	exit 1
	;;
esac

exit 0
