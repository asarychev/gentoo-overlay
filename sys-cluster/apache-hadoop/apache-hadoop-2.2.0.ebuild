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

DEPEND=">=virtual/jdk-1.6
	>=dev-java/maven-bin-3.0
	>=dev-libs/protobuf-2.5.0
	dev-util/cmake
	dev-java/ant
	app-arch/snappy
	"

RDEPEND=">=virtual/jre-1.6"

S=${WORKDIR}/hadoop-${MY_PV}-src
INSTALL_DIR=opt/hadoop	# relative to ${EROOT}

pkg_preinst() {
	enewgroup hadoop
	enewuser hdfs -1 /bin/bash /var/lib/hadoop/hdfs hadoop
	enewuser mapred -1 /bin/bash /var/lib/hadoop/mapred hadoop
}

src_compile() {
	local cmd="mvn package -Pdist$(usex native ",native" "") -Dtar $(usex snappy "-Drequire.snappy" "") -DskipTests"
	einfo ${cmd}
	${cmd} || die "Error building package"
}

src_install() {
	local keys=(hdfs yarn)
	local vals=("namenode datanode" "resourcemanager nodemanager")
	local i f

	dodir "${INSTALL_DIR}"
	tar xf "hadoop-dist/target/hadoop-${MY_PV}.tar.gz" --directory "${ED}${INSTALL_DIR}"
	find "${ED}${INSTALL_DIR}" -name '*.cmd' -exec rm '{}' +

	# Init scripts
	dodir /etc/conf.d

	for (( i = 0; i < ${#keys[*]}; i++ )) ; do
		local k=${keys[${i}]}
		newinitd "${FILESDIR}/${k}.initd" ${k}

		for v in ${vals[${i}]} ; do
			dosym "${k}" "/etc/init.d/${k}.${v}"
		done

		cat > "${ED}/etc/conf.d/${k}" <<- EOF
		HADOOP_HOME="${EROOT}${INSTALL_DIR}/hadoop-${MY_PV}"
		HADOOP_CONF_DIR="${EROOT}etc/hadoop"
		EOF
	done

	# Install basic config files.
	insinto /etc/hadoop
	doins "${FILESDIR}/hadoop-cfg/"*
}
