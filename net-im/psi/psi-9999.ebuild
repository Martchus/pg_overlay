# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-im/psi/psi-9999.ebuild,v 1.12 2011/06/30 09:23:16 pva Exp $

EAPI=5

PLOCALES="be bg ca cs de en eo es et fa fi fr he hu it ja kk mk nl pl pt pt_BR ru sk sl sr@latin sv sw uk ur_PK vi zh_CN zh_TW"
PLOCALE_BACKUP="en"

PSI_URI="git://github.com/psi-im"
PSI_PLUS_URI="git://github.com/psi-plus"
EGIT_REPO_URI="${PSI_URI}/psi.git"
PSI_LANGS_URI="${PSI_URI}/psi-translations.git"
PSI_PLUS_LANGS_URI="${PSI_PLUS_URI}/psi-plus-l10n.git"
EGIT_MIN_CLONE_TYPE="single"

inherit eutils l10n multilib git-r3 qmake-utils

DESCRIPTION="Qt4 Jabber client, with Licq-like interface"
HOMEPAGE="http://psi-im.org/"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS=""
IUSE="aspell crypt dbus debug doc enchant extras +hunspell jingle iconsets +qt4 qt5 spell sql ssl xscreensaver
+plugins whiteboarding webkit"

REQUIRED_USE="
	spell? ( ^^ ( aspell enchant hunspell ) )
	aspell? ( spell )
	enchant? ( spell )
	hunspell? ( spell )
	iconsets? ( extras )
	plugins? ( extras )
	sql? ( extras )
	webkit? ( extras )
	^^ ( qt4 qt5 )
"

RDEPEND="
	net-dns/libidn
	|| ( >=sys-libs/zlib-1.2.5.1-r2[minizip] <sys-libs/zlib-1.2.5.1-r1 )
	spell? (
		enchant? ( >=app-text/enchant-1.3.0 )
		hunspell? ( app-text/hunspell )
		aspell? ( app-text/aspell )
	)
	xscreensaver? ( x11-libs/libXScrnSaver )
	qt4? (
		dev-qt/qtgui:4
		dbus? ( dev-qt/qtdbus:4 )
		|| ( <app-crypt/qca-2.1:2 >=app-crypt/qca-2.1:2[qt4] )
		whiteboarding? ( dev-qt/qtsvg:4 )
		webkit? ( dev-qt/qtwebkit:4 )
		extras? (
			sql? (
				dev-qt/qtsql:4
				dev-libs/qjson
			)
		)
	)
	qt5? (
		dev-qt/qtgui:5
		dev-qt/qtxml:5
		dev-qt/qtconcurrent:5
		dev-qt/qtmultimedia:5
		dev-qt/qtx11extras:5
		dbus? ( dev-qt/qtdbus:5 )
		>=app-crypt/qca-2.1:2[qt5]
		whiteboarding? ( dev-qt/qtsvg:5 )
		webkit? ( dev-qt/qtwebkit:5 )
		extras? (
			sql? ( dev-qt/qtsql:5 )
		)
	)
"
DEPEND="${RDEPEND}
	extras? (
		>=sys-devel/qconf-1.6_pre1
	)
	doc? ( app-doc/doxygen )
	virtual/pkgconfig
	qt5? ( dev-qt/linguist-tools )
"
PDEPEND="
	crypt? ( >=app-crypt/qca-2.1.0[gpg] )
	jingle? (
		net-im/psimedia[extras?]
		>=app-crypt/qca-2.1.0.3[openssl]
	)
	ssl? ( >=app-crypt/qca-2.1.0.3[openssl] )
"
RESTRICT="test"

pkg_setup() {
	MY_PN=psi
	if use extras; then
		MY_PN=psi-plus
		echo
		ewarn "You're about to build heavily patched version of Psi called Psi+."
		ewarn "It has really nice features but still is under heavy development."
		ewarn "Take a look at homepage for more info: http://code.google.com/p/psi-dev"
		echo

		if use iconsets; then
			echo
			ewarn "Some artwork is from open source projects, but some is provided 'as-is'"
			ewarn "and has not clear licensing."
			ewarn "Possibly this build is not redistributable in some countries."
		fi
	fi
}

src_unpack() {
	git-r3_src_unpack

	# fetch translations
	unset EGIT_BRANCH EGIT_COMMIT
	if use extras; then
		EGIT_REPO_URI="${PSI_PLUS_LANGS_URI}"
	else
		EGIT_REPO_URI="${PSI_LANGS_URI}"
	fi
	EGIT_CHECKOUT_DIR="${WORKDIR}/psi-l10n"
	git-r3_src_unpack

	if use extras; then
		unset EGIT_BRANCH EGIT_COMMIT
		EGIT_CHECKOUT_DIR="${WORKDIR}/psi-plus" \
		EGIT_REPO_URI="${PSI_PLUS_URI}/main.git" \
		git-r3_src_unpack

		if use iconsets; then
			unset EGIT_BRANCH EGIT_COMMIT
			EGIT_CHECKOUT_DIR="${WORKDIR}/resources" \
			EGIT_REPO_URI="${PSI_PLUS_URI}/resources.git" \
			git-r3_src_unpack
		fi
	fi
}

src_prepare() {
	if use extras; then
		cp -a "${WORKDIR}/psi-plus/iconsets" "${S}" || die
		if use iconsets; then
			cp -a "${WORKDIR}/resources/iconsets" "${S}" || die
		fi

		PATCHES_DIR="${WORKDIR}/psi-plus/patches"
		EPATCH_SOURCE="${PATCHES_DIR}" EPATCH_SUFFIX="diff" EPATCH_FORCE="yes" epatch

		PSI_REVISION="$(cd "${WORKDIR}/${P}" && git describe --tags|cut -d - -f 2)"
		PSI_PLUS_REVISION="$(cd "${WORKDIR}/psi-plus" && git describe --tags|cut -d - -f 2)"
		PSI_PLUS_TAG="$(cd "${WORKDIR}/psi-plus" && git describe --tags|cut -d - -f 1)"

		use sql && epatch "${PATCHES_DIR}/dev/psi-new-history.patch"

		use webkit && {
			echo "${PSI_PLUS_TAG}.${PSI_PLUS_REVISION}.${PSI_REVISION}-webkit (@@DATE@@)" > version
		} || {
			echo "${PSI_PLUS_TAG}.${PSI_PLUS_REVISION}.${PSI_REVISION} (@@DATE@@)" > version
		}

		qconf || die "Failed to create ./configure."
	fi
	epatch_user
}

src_configure() {
	# unable to use econf because of non-standard configure script
	# disable growl as it is a MacOS X extension only

	CONF=(
		--libdir="${EPREFIX}"/usr/$(get_libdir)
		--prefix="${EPREFIX}"/usr
		--no-separate-debug-info
		--disable-growl
	)

	use qt4 && CONF+=(--qtdir="$(qt4_get_bindir)/..")
	use qt5 && CONF+=(--qtdir="$(qt5_get_bindir)/..")


	use dbus || CONF+=("--disable-qdbus")
	use debug && CONF+=("--debug")

	for s in aspell enchant hunspell; do
		use $s || CONF+=("--disable-$s")
	done
	
	use whiteboarding && CONF+=("--enable-whiteboarding")
	use xscreensaver || CONF+=("--disable-xss")
	use plugins || CONF+=("--disable-plugins")
	use webkit && CONF+=("--enable-webkit")

	elog ./configure "${CONF[@]}"
	./configure "${CONF[@]}"

	use qt4 && eqmake4 psi.pro
	use qt5 && eqmake5 psi.pro
}

src_compile() {
	emake

	if use doc; then
		cd doc
		make api_public || die "make api_public failed"
	fi
}

src_install() {
	emake INSTALL_ROOT="${D}" install

	# this way the docs will be installed in the standard gentoo dir
	rm -f "${ED}"/usr/share/${MY_PN}/{COPYING,README}
	newdoc iconsets/roster/README README.roster
	newdoc iconsets/system/README README.system
	newdoc certs/README README.certs
	dodoc README

	use doc && dohtml -r doc/api

	# install translations
	cd "${WORKDIR}/psi-l10n"
	insinto /usr/share/${MY_PN}
	install_locale() {
		if use extras; then
			lrelease "translations/${PN}_${1}.ts" || die "lrelease ${1} failed"
			doins "translations/${PN}_${1}.qm"
		else
			# PLOCALES are set from Psi+. So we don't want to fail here if no locale
			if [ -f "${x}/${PN}_${1}.ts" ]; then
				lrelease "${x}/${PN}_${1}.ts" || die "lrelease ${1} failed"
				doins "${x}/${PN}_${1}.qm"
			else
				ewarn "Unfortunately locale \"${1}\" is supported for Psi+ only"
			fi
		fi
	}
	l10n_for_each_locale_do install_locale
}
