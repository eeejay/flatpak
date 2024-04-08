#!/bin/bash
#
# Copyright (C) 2011 Colin Walters <walters@verbum.org>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.

set -euo pipefail

. $(dirname $0)/libtest.sh

skip_without_bwrap
skip_revokefs_without_fuse

echo "1..2"

# Use stable rather than master as the branch so we can test that the run
# command automatically finds the branch correctly
setup_repo "" "" stable
$FLATPAK remote-ls test-repo ${U}
${FLATPAK} ${U} install -y test-repo org.test.Hello.Plugin.fun v1 >&2
echo eh
$FLATPAK list ${U} 
exit(1)

install_repo "" stable

# Verify that app is correctly installed

assert_has_dir $FL_DIR/app/org.test.Hello
assert_has_symlink $FL_DIR/app/org.test.Hello/current
assert_symlink_has_content $FL_DIR/app/org.test.Hello/current ^$ARCH/stable$
assert_has_dir $FL_DIR/app/org.test.Hello/$ARCH/stable
assert_has_symlink $FL_DIR/app/org.test.Hello/$ARCH/stable/active
ID=`readlink $FL_DIR/app/org.test.Hello/$ARCH/stable/active`
assert_has_file $FL_DIR/app/org.test.Hello/$ARCH/stable/active/deploy
assert_has_file $FL_DIR/app/org.test.Hello/$ARCH/stable/active/metadata
assert_has_dir $FL_DIR/app/org.test.Hello/$ARCH/stable/active/files
assert_has_dir $FL_DIR/app/org.test.Hello/$ARCH/stable/active/export
assert_has_file $FL_DIR/exports/share/applications/org.test.Hello.desktop
assert_has_file $FL_DIR/exports/share/metainfo/org.test.Hello.metainfo.xml
assert_has_file $FL_DIR/exports/share/metainfo/org.test.Hello.cmd.appdata.xml
# Ensure Exec key is rewritten
assert_file_has_content $FL_DIR/exports/share/applications/org.test.Hello.desktop "^Exec=.*flatpak run --branch=stable --arch=$ARCH --command=hello\.sh org\.test\.Hello$"
assert_has_file $FL_DIR/exports/share/gnome-shell/search-providers/org.test.Hello.search-provider.ini
assert_file_has_content $FL_DIR/exports/share/gnome-shell/search-providers/org.test.Hello.search-provider.ini "^DefaultDisabled=true$"
assert_has_file $FL_DIR/exports/share/icons/hicolor/64x64/apps/org.test.Hello.png
assert_not_has_file $FL_DIR/exports/share/icons/hicolor/64x64/apps/dont-export.png
assert_has_file $FL_DIR/exports/share/icons/HighContrast/64x64/apps/org.test.Hello.png

# Ensure triggers ran
assert_has_file $FL_DIR/exports/share/applications/mimeinfo.cache
assert_file_has_content $FL_DIR/exports/share/applications/mimeinfo.cache x-test/Hello
# assert_has_file $FL_DIR/exports/share/icons/hicolor/icon-theme.cache
# assert_has_file $FL_DIR/exports/share/icons/hicolor/index.theme

$FLATPAK list ${U} | grep org.test.Hello > /dev/null
$FLATPAK list ${U} -d | grep org.test.Hello | grep test-repo > /dev/null
$FLATPAK list ${U} -d | grep org.test.Hello | grep current > /dev/null
$FLATPAK list ${U} -d | grep org.test.Hello | grep ${ID:0:12} > /dev/null

$FLATPAK info ${U} org.test.Hello > /dev/null
$FLATPAK info ${U} org.test.Hello | grep test-repo > /dev/null
$FLATPAK info ${U} org.test.Hello | grep $ID > /dev/null

$FLATPAK list ${U} | grep org.test.Platform > /dev/null

ok "install"

run org.test.Hello &> hello_out
assert_file_has_content hello_out '^Hello world, from a sandbox$'

ok "hello"

true > value-in-sandbox
head value-in-sandbox >&2
run_sh org.test.Hello 'echo fd passthrough >&5' 5>value-in-sandbox
assert_file_has_content value-in-sandbox '^fd passthrough$'
