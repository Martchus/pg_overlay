# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5
inherit eutils qmake-utils

MY_P=${PN}_${PV}

DESCRIPTION="A Qt5 client for the music player daemon (MPD) written in C++"
HOMEPAGE="http://mpd.wikia.com/wiki/Client:Quimup"
SRC_URI="http://coonsden.com/dl0ads/${PN}_${PV}_source.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ~x86"
IUSE=""

RDEPEND="dev-qt/qtcore:5
	dev-qt/qtgui:5
	dev-qt/qtnetwork:5
	dev-qt/qtwidgets:5
	>=media-libs/libmpdclient-2.10
	media-libs/taglib
	media-sound/mpd[libmpdclient]"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

S="${WORKDIR}/${PN} ${PV}"

DOCS=( changelog FAQ.txt README )

src_prepare() {
	epatch "${FILESDIR}"/${P}-qdatastream.patch
}

src_configure() {
	eqmake5
}

src_install() {
	default
	dobin ${PN}

	newicon src/resources/mn_icon.png ${PN}.png
	make_desktop_entry ${PN} Quimup
}
