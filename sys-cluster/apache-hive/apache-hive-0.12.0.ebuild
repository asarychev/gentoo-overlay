# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

inherit eutils java-pkg-2 java-ant-2

DESCRIPTION="data warehouse software on top of Apache Hadoop"
HOMEPAGE="http://hive.apache.org/"
SRC_URI="http://apache.mirrors.hoobly.com/hive/hive-${PV}/hive-${PV}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="mirror"
IUSE="examples"

DEPEND=">=virtual/jdk-1.6
	>=dev-libs/protobuf-2.5.0
	dev-java/ant
	"

RDEPEND=">=virtual/jre-1.6"

S="${WORKDIR}/hive-${PV}/src"

pkg_preinst() {
	enewgroup hive
	enewuser hive -1 /bin/bash /var/lib/hive hive
}

EANT_BUILD_TARGET="package"
EANT_EXTRA_ARGS="-Dbuild.sysclasspath=last"

_do_all_exe() {
	local f t
	local dir=$1
	shift

	for f in "$@" ; do
		local ff=$(basename ${f})

		if [[ -d ${f} ]] ; then
			_do_all_exe "${dir}/${ff}" "${f}/"*
		else
			exeinto ${dir}
			doexe "${f}"
		fi
	done
}

src_install() {

	insinto "/opt/hive-${PV}"
	doins -r "${S}/build/dist/"{LICENSE,NOTICE,README.txt,RELEASE_NOTES.txt,conf,scripts}
	use examples && doins -r "${S}/build/dist/examples"

	_do_all_exe "/opt/hive-${PV}" "${S}/build/dist/bin"

	insinto "/opt/hive-${PV}/hcatalog"
	doins -r "${S}/build/dist/hcatalog/"{etc,share}

	_do_all_exe "/opt/hive-${PV}/hcatalog" "${S}/build/dist/hcatalog/"{bin,libexec,sbin}
}
