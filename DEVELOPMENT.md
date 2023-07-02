# Development

## SPDK

Install all required system dependencies using `sudo vend/spdk/scripts/pkgdep.sh`.

```
cd vend/spdk
./configure
# Do not use DESTDIR, it breaks the build.
make -j
# Use the build of the vendored DPDK instead of building a separate DPDK which may not be compatible with SPDK.
cp -r dpdk/build ../../build/dpdk
cp -r build ../../build/spdk
```
