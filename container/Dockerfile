# The official dCache image with the GSDC site patches applied on top.
#
# The build context must contain the files listed in overlay.txt, as
# prepared by .github/workflows/gsdc-build.yml.
ARG DCACHE_VERSION
FROM docker.io/dcache/dcache:${DCACHE_VERSION}

COPY opt/dcache/ /opt/dcache/
