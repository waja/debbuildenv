#!/bin/bash

[ -n "${LOCAL_DEB_MIRROR}" ] && sed -i "s#http://deb.debian.org/debian #${LOCAL_DEB_MIRROR}/debian #g" /etc/apt/sources.list;  \
[ -n "${CACHE_HOST}" ] && echo "Acquire::http::Proxy \"http://${CACHE_HOST}:3142\";" > /etc/apt/apt.conf.d/01proxy; \
[ "${BUILD_USER}" != "root" ] && adduser -shell /bin/bash --gecos '' --disabled-password --home ${USER_HOME_DIR} ${BUILD_USER}; \
echo 'Aptitude::Recommends-Important "False";' > /etc/apt/apt.conf.d/10norecommands && \
apt update > /dev/null && apt -y upgrade > /dev/null && \
apt install -y --no-install-recommends curl ca-certificates gnupg > /dev/null && \
curl -fsSL https://ftp.cyconet.org/debian/repo.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/debian-cyconet-archive-keyring.gpg > /dev/null 2>&1 && \
cat << EOF > /etc/apt/sources.list.d/restricted-cyconet.list
deb     [signed-by=/etc/apt/trusted.gpg.d/debian-cyconet-archive-keyring.gpg] http://ftp.cyconet.org/debian restricted     main non-free contrib
deb-src [signed-by=/etc/apt/trusted.gpg.d/debian-cyconet-archive-keyring.gpg] http://ftp.cyconet.org/debian restricted     main non-free contrib
EOF
apt update > /dev/null && apt install debian-cyconet-archive-keyring

case ${BUILD_TARGET} in
	*-backports)
cat << EOF > /etc/apt/sources.list.d/${BUILD_TARGET}-cyconet.list
deb     http://ftp.cyconet.org/debian ${BUILD_TARGET}     main non-free contrib
deb-src http://ftp.cyconet.org/debian ${BUILD_TARGET}     main non-free contrib
EOF
		apt update
		;;
	*)
		;;
esac

if [ "${ENTRY_EXIT_COMMAND}" != "bash" ]; then
	su -c "${ENTRY_EXIT_COMMAND}" ${BUILD_USER}
else
	su - ${BUILD_USER}
fi
