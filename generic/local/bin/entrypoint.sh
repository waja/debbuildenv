#!/bin/bash

set -x

if [ ! -f /.initialized ]; then
	[ -n "${CACHE_HOST}" ] && echo "Acquire::http::Proxy \"http://${CACHE_HOST}:3142\";" > /etc/apt/apt.conf.d/01proxy; \
	printf "APT::Install-Recommends \"false\";\nAptitude::Recommends-Important \"False\";" >	/etc/apt/apt.conf.d/00InstallRecommends && \
	[ -n "${LOCAL_DEB_MIRROR}" ] && [ -f /etc/apt/sources.list ] && \
		if [ "${LOCAL_DEB_MIRROR}" == "http://archive.debian.org" ]; then
			sed -i "s#http://deb.debian.org/debian #[check-valid-until=no] ${LOCAL_DEB_MIRROR}/debian #g" /etc/apt/sources.list && sed -i '/security.debian.org/d' /etc/apt/sources.list && sed -i '/-updates/d' /etc/apt/sources.list 
			APT_INSTALL_CMD+=" --force-yes"
			CURL_INSECURE="-k"
		else
			sed -i "s#http://deb.debian.org/debian #${LOCAL_DEB_MIRROR}/debian #g" /etc/apt/sources.list
		fi;  \
	[ -n "${LOCAL_DEB_MIRROR}" ] && [ -f /etc/apt/sources.list.d/debian.sources ] && sed -i "s#http://deb.debian.org/debian\$#${LOCAL_DEB_MIRROR}/debian#g" /etc/apt/sources.list.d/debian.sources;  \
	apt-get update > /dev/null && apt-get -y upgrade > /dev/null && \
	${APT_INSTALL_CMD} curl ca-certificates gnupg adduser > /dev/null && \
	[ "${BUILD_USER}" != "root" ] && adduser -shell /bin/bash --gecos '' --disabled-password --home "${USER_HOME_DIR}" "${BUILD_USER}" > /dev/null && sed -i "s/# auth       sufficient pam_wheel.so trust/auth       sufficient pam_wheel.so trust group=${BUILD_USER}/" /etc/pam.d/su; \
	curl -fsSL "${CURL_INSECURE:-}" https://ftp.cyconet.org/debian/repo.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/debian-cyconet-archive-keyring.gpg > /dev/null 2>&1 && \
	cat << EOF > /etc/apt/sources.list.d/restricted-cyconet.list
deb     [signed-by=/etc/apt/trusted.gpg.d/debian-cyconet-archive-keyring.gpg] http://ftp.cyconet.org/debian restricted     main non-free contrib
deb-src [signed-by=/etc/apt/trusted.gpg.d/debian-cyconet-archive-keyring.gpg] http://ftp.cyconet.org/debian restricted     main non-free contrib
EOF
	apt-get update > /dev/null && ${APT_INSTALL_CMD} debian-cyconet-archive-keyring > /dev/null
	# Refresh packages for EOL suites
	if [ "${APT_FORCE_YES}" == "--force-yes" ]; then
		curl -fsSL "${CURL_INSECURE:-}" "${PKG_CA_CERTIFICATES}" -o /tmp/ca-certificates_all.deb && dpkg -i /tmp/ca-certificates_all.deb &&
		curl -fsSL "${CURL_INSECURE:-}" "${PKG_KEYRING}" -o /tmp/debian-archive-keyring_all.deb && dpkg -i /tmp/debian-archive-keyring_all.deb
	fi

	case ${BUILD_TARGET} in
		bookworm-backports)
			cat << EOF > /etc/apt/sources.list.d/testing.list
deb-src http://ftp.de.debian.org/debian/ testing main contrib non-free
EOF
			;& #fallthru
		bullseye-backports)
			cat << EOF > /etc/apt/sources.list.d/bookworm.list
deb-src http://ftp.de.debian.org/debian/ bookworm main contrib non-free
EOF
			;& #fallthru
		*-backports)
			cat << EOF > /etc/apt/sources.list.d/"${BUILD_TARGET}"-cyconet.list
deb     http://ftp.cyconet.org/debian ${BUILD_TARGET}     main non-free contrib
deb-src http://ftp.cyconet.org/debian ${BUILD_TARGET}     main non-free contrib
EOF
			apt-get update > /dev/null && \
			${APT_INSTALL_CMD} dpkg-dev devscripts > /dev/null
			;;
		unstable|sid)
			sed "s/ deb/ deb-src/g" /etc/apt/sources.list.d/debian.sources > /etc/apt/sources.list.d/debian-src.sources && \
			apt-get update > /dev/null && \
			${APT_INSTALL_CMD} git-buildpackage bash-completion > /dev/null
			;;
		*)
			;;
	esac
fi

touch /.initialized

if [ "${ENTRY_EXIT_COMMAND}" != "bash" ]; then
	su -c "${ENTRY_EXIT_COMMAND}" "${BUILD_USER}"
else
	su - "${BUILD_USER}"
fi
