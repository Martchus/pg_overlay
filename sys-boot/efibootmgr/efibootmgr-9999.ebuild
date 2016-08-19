# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit git-r3 toolchain-funcs

DESCRIPTION="User-space application to modify the EFI boot manager"
HOMEPAGE="https://github.com/rhinstaller/efibootmgr"
SRC_URI="git://github.com/rhinstaller/${PN}.git"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ia64 x86"
IUSE=""

RDEPEND="sys-apps/pciutils
	>=sys-libs/efivar-26"
DEPEND="${RDEPEND}"

src_prepare() {
	sed -i -e s/-Werror// Makefile || die
}

src_configure() {
	tc-export CC
	export EXTRA_CFLAGS=${CFLAGS}
}

src_install() {
	# build system uses perl, so just do it ourselves
	dosbin src/efibootmgr
	doman src/efibootmgr.8
	dodoc AUTHORS README TODO
}