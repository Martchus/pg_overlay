# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6
inherit autotools fdo-mime flag-o-matic gnome2-utils qmake-utils user

DESCRIPTION="A Fast, Easy and Free BitTorrent client"
HOMEPAGE="http://www.transmissionbt.com/"
SRC_URI="https://build.${PN}bt.com/job/trunk-linux/lastSuccessfulBuild/artifact/${PN}-trunk-${PR}.tar.xz"

# web/LICENSE is always GPL-2 whereas COPYING allows either GPL-2 or GPL-3 for the rest
# transmission in licenses/ is for mentioning OpenSSL linking exception
# MIT is in several libtransmission/ headers
LICENSE="|| ( GPL-2 GPL-3 Transmission-OpenSSL-exception ) GPL-2 MIT"
SLOT=0
IUSE="ayatana gtk libressl lightweight qt4 qt5 systemd xfs"
KEYWORDS="~amd64 ~arm ~mips ~ppc ~ppc64 ~x86 ~x86-fbsd ~amd64-linux"

RDEPEND=">=dev-libs/libevent-2.0.10:=
	!libressl? ( dev-libs/openssl:0= )
	libressl? ( dev-libs/libressl )
	>=net-misc/curl-7.16.3:=[ssl]
	sys-libs/zlib:=
	gtk? (
		>=dev-libs/dbus-glib-0.100:=
		>=dev-libs/glib-2.32:2=
		>=x11-libs/gtk+-3.4:3=
		ayatana? ( >=dev-libs/libappindicator-0.4.90:3= )
		)
	qt4? (
		dev-qt/qtcore:4
		dev-qt/qtgui:4
		dev-qt/qtdbus:4
		)
	qt5? (
		dev-qt/qtcore:5
		dev-qt/qtdbus:5
		dev-qt/qtgui:5
		dev-qt/qtnetwork:5
		dev-qt/qtwidgets:5
		)"
DEPEND="${RDEPEND}
	>=dev-libs/glib-2.32
	dev-util/intltool
	sys-devel/gettext
	virtual/os-headers
	virtual/pkgconfig
	qt5? ( dev-qt/linguist-tools:5 )
	xfs? ( sys-fs/xfsprogs )"

REQUIRED_USE="ayatana? ( gtk ) ?? ( qt4 qt5 )"

DOCS="AUTHORS NEWS qt/README.txt"

S=${S}+

src_prepare() {
	sed -i -e '/CFLAGS/s:-ggdb3::' configure.ac || die

	# Trick to avoid automagic dependency
	use ayatana || { sed -i -e '/^LIBAPPINDICATOR_MINIMUM/s:=.*:=9999:' configure.ac || die; }

	# http://trac.transmissionbt.com/ticket/4324
	sed -i -e 's|noinst\(_PROGRAMS = $(TESTS)\)|check\1|' lib${PN}/Makefile.am || die

	# 2.92+ -> 2.92
	sed -i s/2.92+/2.92/g CMakeLists.txt || die
	sed -i s/TR292Z/TR2920/g CMakeLists.txt || die
	sed -i s/2.92+/2.92/g configure || die
	sed -i s/TR292Z/TR2920/g configure || die
	sed -i s/2.92+/2.92/g configure.ac || die
	sed -i s/TR292Z/TR2920/g configure.ac || die
	sed -i s/2.92+/2.92/g lib${PN}/version.h || die
	sed -i s/TR292Z/TR2920/g lib${PN}/version.h || die

	# Prevent m4_copy error when running aclocal
	# m4_copy: won't overwrite defined macro: glib_DEFUN
	rm m4/glib-gettext.m4 || die

	default
	eautoreconf
}

src_configure() {
	export ac_cv_header_xfs_xfs_h=$(usex xfs)

	# https://bugs.gentoo.org/577528
	append-cppflags -D_LARGEFILE64_SOURCE=1

	econf \
		--disable-external-natpmp \
		$(use_enable lightweight) \
		$(use_with systemd systemd) \
		$(use_with gtk)

	if use qt4 || use qt5; then
		pushd qt >/dev/null || die
		use qt4 && eqmake4 qtr.pro
		use qt5 && eqmake5 qtr.pro
		popd >/dev/null || die
	fi
}

src_compile() {
	emake

	if use qt4 || use qt5; then
		local qt_bindir
		use qt4 && qt_bindir=$(qt4_get_bindir)
		use qt5 && qt_bindir=$(qt5_get_bindir)
		emake -C qt
		"${qt_bindir}"/lrelease qt/translations/*.ts || die
	fi
}

src_install() {
	default

	rm "${ED}"/usr/share/${PN}/web/LICENSE || die

	newinitd "${FILESDIR}"/${PN}-daemon.initd.10 ${PN}-daemon
	newconfd "${FILESDIR}"/${PN}-daemon.confd.4 ${PN}-daemon

	if use qt4 || use qt5; then
		pushd qt >/dev/null || die
		emake INSTALL_ROOT="${ED}"/usr install

		domenu ${PN}-qt.desktop

		local res
		for res in 16 22 24 32 48 64 72 96 128 192 256; do
			doicon -s ${res} icons/hicolor/${res}x${res}/${PN}-qt.png
		done
		doicon -s scalable icons/hicolor/scalable/${PN}-qt.svg

		use qt4 && insinto /usr/share/qt4/translations
		use qt5 && insinto /usr/share/qt5/translations
		doins translations/*.qm
		popd >/dev/null || die
	fi
}

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	fdo-mime_desktop_database_update
	gnome2_icon_cache_update

	elog "If you use transmission-daemon, please, set 'rpc-username' and"
	elog "'rpc-password' (in plain text, transmission-daemon will hash it on"
	elog "start) in settings.json file located at /var/lib/transmission/config or"
	elog "any other appropriate config directory."
	elog
	elog "Since µTP is enabled by default, transmission needs large kernel buffers for"
	elog "the UDP socket. You can append following lines into /etc/sysctl.conf:"
	elog " net.core.rmem_max = 4194304"
	elog " net.core.wmem_max = 1048576"
	elog "and run sysctl -p"
}

pkg_postrm() {
	fdo-mime_desktop_database_update
	gnome2_icon_cache_update
}
