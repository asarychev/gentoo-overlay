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
	>=sys-cluster/apache-hadoop-common-2.2[native?,snappy?]
	"

S=${WORKDIR}/hadoop-${MY_PV}-src/hadoop-yarn-project
INSTALL_DIR="opt/apache-hadoop/yarn-${MY_PV}"	# relative to ${EROOT}

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

pkg_preinst() {
	enewgroup hadoop
	enewuser mapred -1 /bin/bash /var/lib/hadoop/mapred hadoop
}

src_compile() {
	local cmd="mvn --settings ${T}/maven/settings.xml package -Pdist$(usex native ",native" "") $(usex snappy "-Drequire.snappy" "") -DskipTests"
	einfo ${cmd}
	${cmd} || die "Error building package"
}

src_install() {
	local t

	insinto "/${INSTALL_DIR}"

	# Using cp to preserve all executable files
	cp -r "target/hadoop-yarn-project-${MY_PV}/"* "${ED}${INSTALL_DIR}/" || die

	# Get rid of windows .cmd files.
	find "${ED}${INSTALL_DIR}" -name '*.cmd' -exec rm '{}' +

	dodir "/etc/env.d"
	cat > "${ED}/etc/env.d/33apache-hadoop-yarn" <<- EOF
	HADOOP_YARN_HOME="${EROOT}${INSTALL_DIR}"
	#PATH="${EROOT}${INSTALL_DIR}/bin"	# uncomment it if desired
	CONFIG_PROTECT="${EROOT}${INSTALL_DIR}/etc/hadoop"
	EOF

	# init.d files
	newinitd "${FILESDIR}/yarn.initd" yarn
	for t in resourcemanager nodemanager ; do
		dosym yarn "/etc/init.d/yarn.${t}"
	done


	# Install basic config files.
	insinto /etc/hadoop
	doins "${ED}${INSTALL_DIR}/etc/hadoop"/{capacity-scheduler.xml,slaves,yarn-env.sh,container-executor.cfg}
	doins "${FILESDIR}/hadoop-cfg/"*
}
