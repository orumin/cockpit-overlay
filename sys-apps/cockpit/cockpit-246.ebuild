# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools eutils pam systemd

KEYWORDS="~amd64 ~x86"
DESCRIPTION="Server Administration Web Interface "
HOMEPAGE="http://cockpit-project.org/"
SRC_URI="https://github.com/cockpit-project/${PN}/releases/download/${PV}/${P}.tar.xz"

if [[ ${PV} == 9999* ]] ; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/cockpit-project/cockpit.git"
	KEYWORDS=""
fi

LICENSE="LGPL-2.1+"
SLOT="0"
IUSE="debug +doc firewall +networkmanager pcp selinux udisks"

BDEPEND="
	>=app-crypt/mit-krb5-1.11
	>=dev-libs/glib-2.50
	>=dev-libs/json-glib-1.4
	>=net-libs/gnutls-3.6.0
	>=net-libs/libssh-0.8.5[server]
	>=sys-apps/systemd-235[policykit]
	>=sys-auth/polkit-0.105[systemd]
	doc? (
		app-text/xmlto
	)
"
DEPEND="
	dev-libs/libpwquality
	dev-python/dbus-python
	net-libs/nodejs[npm]
	networkmanager? (
		firewall? (
			net-firewall/firewalld
		)
		net-misc/networkmanager[policykit,systemd]
	)
	pcp? (
		sys-apps/pcp
	)
	sys-apps/accountsservice[systemd]
	udisks? (
		sys-fs/udisks[lvm,systemd]
	)
"

RDEPEND="${DEPEND}
	acct-group/cockpit-ws
	acct-group/cockpit-wsinstance
	acct-user/cockpit-ws
	acct-user/cockpit-wsinstance
	dev-libs/libgudev
	net-libs/glib-networking[ssl]
	virtual/krb5
"

src_prepare() {
	eapply_user
	eautoreconf
}

src_configure() {
	local myconf=(
		$(use_enable debug)
		$(use_enable pcp)
		$(use_enable doc)
		"--with-pamdir=/lib64/security"
		"--with-cockpit-user=cockpit-ws"
		"--with-cockpit-ws-instance-user=cockpit-wsinstance"
		"--with-cockpit-group=cockpit-ws"
		"--localstatedir=${ROOT}/var")
	econf "${myconf[@]}"
}

src_install(){
	emake DESTDIR="${D}" install || die "emake install failed"

	if ! use selinux ; then
    	rm -rf "${D}"/usr/share/cockpit/selinux
    	rm -rf "${D}"/usr/share/metainfo/org.cockpit-project.cockpit-selinux.metainfo.xml
    fi

    rm -rf "${D}"/usr/share/cockpit/packagekit

	ewarn "Installing experimetal pam configuration file"
	ewarn "use at your own risk"
	newpamd "${FILESDIR}/cockpit.pam" cockpit
	dodoc README.md AUTHORS
}