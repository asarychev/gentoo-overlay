# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

inherit eutils java-pkg-2

MY_PV=$(tr -- _ - <<<${PV})

DESCRIPTION="Software framework for data intensive distributed applications"
HOMEPAGE="http://hadoop.apache.org/"
SRC_URI="http://apache.osuosl.org/hadoop/core/hadoop-${MY_PV}/hadoop-${MY_PV}-src.tar.gz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="mirror"
IUSE="+snappy +native"

_common_deps="
	native? ( >=dev-libs/protobuf-2.5.0 dev-util/cmake )
	snappy? ( app-arch/snappy )
	"
DEPEND=">=virtual/jdk-1.6
	>=dev-java/maven-bin-3.0
	dev-java/ant
	${_common_deps}
	"

RDEPEND=">=virtual/jre-1.6
	${_common_deps}
	"

S=${WORKDIR}/hadoop-${MY_PV}-src/hadoop-common-project
INSTALL_DIR="opt/apache-hadoop/common-${MY_PV}"	# relative to ${EROOT}

pkg_setup() {
	#Setup Maven.
	mkdir "${T}/maven"

	cat > "${T}/maven/settings.xml" <<- EOF || die "Cannot setup Maven"
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0
                      http://maven.apache.org/xsd/settings-1.0.0.xsd">
  <localRepository>${T}/maven/repository</localRepository>
  <interactiveMode>false</interactiveMode>
</settings>
	EOF

}

src_compile() {
	local cmd="mvn --settings ${T}/maven/settings.xml package -Pdist$(usex native ",native" "") -Dtar $(usex snappy "-Drequire.snappy" "") -DskipTests"
	einfo ${cmd}
	${cmd} || die "Error building package"
}

src_install() {
	dodir "/${INSTALL_DIR}"

	# Using cp to preserve all executable files
	cp -r "hadoop-common/target/hadoop-common-${MY_PV}"/* "${ED}${INSTALL_DIR}/" || die
	cp -r "hadoop-nfs/target/hadoop-nfs-${MY_PV}"/* "${ED}${INSTALL_DIR}/" || die

	# Get rid of windows .cmd files.
	find "${ED}${INSTALL_DIR}" -name '*.cmd' -exec rm '{}' + || die

	dodir "/etc/env.d"
	cat > "${ED}/etc/env.d/30apache-common" <<- EOF || die
	HADOOP_COMMON_HOME="${EROOT}${INSTALL_DIR}"
	HADOOP_COMMON_CONF_DIR="${EROOT}etc/hadoop"
	PATH="${EROOT}${INSTALL_DIR}/bin"
	EOF

	# Install basic config files.
	insinto /etc/hadoop
	doins "${FILESDIR}/hadoop-cfg/"*
}
