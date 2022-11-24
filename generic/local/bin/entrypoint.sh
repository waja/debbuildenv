#!/bin/bash

if [ ! -f /.initialized ]; then
	[ -n "${LOCAL_DEB_MIRROR}" ] && [ -f /etc/apt/sources.list ] && sed -i "s#http://deb.debian.org/debian #${LOCAL_DEB_MIRROR}/debian #g" /etc/apt/sources.list;  \
	[ -n "${LOCAL_DEB_MIRROR}" ] && [ -f /etc/apt/sources.list.d/debian.sources ] && sed -i "s#http://deb.debian.org/debian#${LOCAL_DEB_MIRROR}/debian#g" /etc/apt/sources.list.d/debian.sources;  \
	[ -n "${CACHE_HOST}" ] && echo "Acquire::http::Proxy \"http://${CACHE_HOST}:3142\";" > /etc/apt/apt.conf.d/01proxy; \
	[ "${BUILD_USER}" != "root" ] && adduser -shell /bin/bash --gecos '' --disabled-password --home "${USER_HOME_DIR}" "${BUILD_USER}" > /dev/null && sed -i "s/# auth       sufficient pam_wheel.so trust/auth       sufficient pam_wheel.so trust group=${BUILD_USER}/" /etc/pam.d/su; \
	echo 'Aptitude::Recommends-Important "False";' > /etc/apt/apt.conf.d/10norecommands && \
	apt-get update > /dev/null && apt-get -y upgrade > /dev/null && \
	apt-get install -y --no-install-recommends curl ca-certificates gnupg > /dev/null && \
	curl -fsSL https://ftp.cyconet.org/debian/repo.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/debian-cyconet-archive-keyring.gpg > /dev/null 2>&1 && \
	cat << EOF > /etc/apt/sources.list.d/restricted-cyconet.list
deb     [signed-by=/etc/apt/trusted.gpg.d/debian-cyconet-archive-keyring.gpg] http://ftp.cyconet.org/debian restricted     main non-free contrib
deb-src [signed-by=/etc/apt/trusted.gpg.d/debian-cyconet-archive-keyring.gpg] http://ftp.cyconet.org/debian restricted     main non-free contrib
EOF
	apt-get update > /dev/null && apt-get install debian-cyconet-archive-keyring > /dev/null

	case ${BUILD_TARGET} in
		bullseye-backports)
			cat << EOF > /etc/apt/sources.list.d/testing.list
deb-src http://ftp.de.debian.org/debian/ testing main contrib non-free
EOF
			;& #fallthru
		*-backports)
			cat << EOF > /etc/apt/sources.list.d/"${BUILD_TARGET}"-cyconet.list
deb     http://ftp.cyconet.org/debian ${BUILD_TARGET}     main non-free contrib
deb-src http://ftp.cyconet.org/debian ${BUILD_TARGET}     main non-free contrib
EOF
			apt-get update > /dev/null && \
			apt-get install -y --no-install-recommends dpkg-dev devscripts > /dev/null
			;;
		unstable|sid)
			sed "s/ deb/ deb-src/g" /etc/apt/sources.list.d/debian.sources > /etc/apt/sources.list.d/debian-src.sources && \
			apt-get update > /dev/null && \
			apt-get install -y --no-install-recommends git-buildpackage bash-completion > /dev/null
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
