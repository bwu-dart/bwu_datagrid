#!/bin/bash
PKG_DIR=$(pwd)

docgen --no-include-sdk --no-include-dependent-packages --out=dartdoc .

# --start-page=core_elements # makes CoreAjax class as start page, which doesn't make any sense.
# --exclude-lib="core:dart" # has no effect
# --out=dartdoc # has no effect when used with --compile
# --compile # only generates a package for the viewer

#cd dartdoc-viewer/client
pwd
#pub build

rm -Rf $PKG_DIR/../bwu_datagrid_gh/dartdoc/docs

mv $PKG_DIR/dartdoc $PKG_DIR/../bwu_datagrid_gh/dartdoc/docs