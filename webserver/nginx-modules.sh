#!/bin/bash

# Install needed development packages if not yet installed in the system
sudo apt -y install git libpcre3 libpcre3-dev zlib1g zlib1g-dev openssl libssl-dev libxslt-dev

# For predefined NGINX version, use:
#ngver=1.16.1

# For passing the version via the command line (i.e.: user@server:~$ ./mkbrotli 1.17.1), use:
#ngver=$1

# For automated detection of currently installed NGINX version (not to be used for auto-updating, see hooks in post), use:
ngver=$(nginx -v 2>&1 | grep -o '[0-9\.]*')

# To manually set NGINX modules directory:
# moddir=/path/to/modules/directory

# To automatically select NGINX modules directory:
[ -d /usr/share/nginx/modules ] && moddir=/usr/share/nginx/modules
[ -d $(nginx -V 2>&1 | grep -o 'prefix=[^ ]*' | sed 's/prefix=//')/modules ] && moddir=$(nginx -V 2>&1 | grep -o 'prefix=[^ ]*' | sed 's/prefix=//')/modules
[ -d $(nginx -V 2>&1 | grep -o 'modules-path=[^ ]*' | sed 's/modules-path=//') ] && moddir=$(nginx -V 2>&1 | grep -o 'modules-path=[^ ]*' | sed 's/modules-path=//')
[ $moddir ] || { echo '!! missing modules directory, exiting...'; exit 1; }

# Set temporary directory and build on it
builddir=$(mktemp -d)
cd ${builddir}

echo
echo '################################################################################'
echo
echo "Building Modules for NGINX $ngver"
echo "Temporary build directory: $builddir"
echo "Modules directory: $moddir"
echo

# Download and unpack NGINX
wget https://nginx.org/download/nginx-${ngver}.tar.gz && { tar zxf nginx-${ngver}.tar.gz && rm nginx-${ngver}.tar.gz; } || { echo '!! download failed, exiting...'; exit 2; }

# Download, initialize, and make Brotli dynamic modules, http_dav_module, nginx_cookie_flag_module,
# nginx_fancyindex_module and nginx_dav_ext_module
git clone https://github.com/google/ngx_brotli.git && git clone https://github.com/AirisX/nginx_cookie_flag_module.git && git clone https://github.com/aperezdc/ngx-fancyindex.git && git clone https://github.com/arut/nginx-dav-ext-module.git
cd ngx_brotli && git submodule update --init && cd ../nginx-${ngver}
nice -n 19 ionice -c 3 ./configure --with-http_dav_module --with-compat --add-dynamic-module=../ngx_brotli --with-compat --add-dynamic-module=../nginx_cookie_flag_module --add-dynamic-module=../ngx-fancyindex --add-dynamic-module=../nginx-dav-ext-module || { echo '!! configure failed, exiting...'; exit 3; }
nice -n 19 ionice -c 3 make modules || { echo '!! make failed, exiting...'; exit 4; }

# Replace Brotli in modules directory
[ -f ${moddir}/ngx_http_brotli_filter_module.so ] && sudo mv ${moddir}/ngx_http_brotli_filter_module.so ${moddir}/ngx_http_brotli_filter_module.so.old
[ -f ${moddir}/ngx_http_brotli_static_module.so ] && sudo mv ${moddir}/ngx_http_brotli_static_module.so ${moddir}/ngx_http_brotli_static_module.so.old
sudo cp objs/*.so ${moddir}/
sudo chmod 644 ${moddir}/ngx_http_brotli_filter_module.so || { echo '!! module permissions failed, exiting...'; exit 5; }
sudo chmod 644 ${moddir}/ngx_http_brotli_static_module.so || { echo '!! module permissions failed, exiting...'; exit 6; }
sed -i '3iload_module modules/ngx_http_brotli_filter_module.so;' /etc/nginx/nginx.conf && sed -i '3iload_module modules/ngx_http_brotli_static_module.so;' /etc/nginx/nginx.conf

# Add other modules to nginx loaded modules and change permissions
sed -i '3iload_module modules/ngx_http_fancyindex_module.so;' /etc/nginx/nginx.conf && sed -i '3iload_module modules/ngx_http_dav_ext_module.so;' /etc/nginx/nginx.conf
sed -i '3iload_module modules/ngx_http_cookie_flag_filter_module.so;' /etc/nginx/nginx.conf
sudo chmod 644 ${moddir}/ngx_http_fancyindex_module.so || { echo '!! module permissions failed, exiting...'; exit 6; }
sudo chmod 644 ${moddir}/ngx_http_cookie_flag_filter_module.so || { echo '!! module permissions failed, exiting...'; exit 6; }
sudo chmod 644 ${moddir}/ngx_http_dav_ext_module.so || { echo '!! module permissions failed, exiting...'; exit 6; }

# Clean up build files
cd ${builddir}/..
sudo rm -r ${builddir}/ngx_brotli
rm -r ${builddir}

echo
echo "Sucessfully built Modules for NGINX $ngver in $moddir"
echo
echo '################################################################################'
echo

# Start/restart NGINX.
# Not recommended if script is hooked since NGINX is automatically restarted by the package manager (e.g. apt) after an upgrade.
# Restarting NGINX before the upgrade could cause a module version mismatch.
# sudo nginx -t && { systemctl is-active nginx && sudo systemctl restart nginx || sudo systemctl start nginx; } || true
# echo
# systemctl --no-pager status nginx
# echo