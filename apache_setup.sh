#!/bin/bash

. util.sh

setup_root="_setup"
[[ ! -s $setup_root ]] || rm -rf $setup_root
mkdir $setup_root
cd $setup_root

sudo apt-get update

b_install_apache2=1
apache2_distro_url="http://www.apache.org/dist/httpd/httpd-2.4.12.tar.gz"
apache2_keys_url="http://www.apache.org/dist/httpd/KEYS"
apache2_signature_url="http://www.apache.org/dist/httpd/httpd-2.4.12.tar.gz.asc"
apache2_prefix="/usr/local/apache2" # default

b_install_apr=1
apr_distro_url="http://psg.mtu.edu/pub/apache/apr/apr-1.5.2.tar.gz"
apr_keys_url="http://www.apache.org/dist/apr/KEYS"
apr_signature_url="http://www.apache.org/dist/apr/apr-1.5.2.tar.gz.asc"
apr_prefix=""

b_install_aprutil=1
aprutil_distro_url="http://psg.mtu.edu/pub/apache/apr/apr-util-1.5.4.tar.gz"
aprutil_keys_url="http://www.apache.org/dist/apr/KEYS"
aprutil_signature_url="http://www.apache.org/dist/apr/apr-util-1.5.4.tar.gz.asc"
aprutil_prefix=""

# try pcre2 first, if apache2 doesn't like pcre2, then try pcre
b_install_pcre=0
pcre_distro_url="ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.37.tar.gz"
pcre_signature_url="ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.37.tar.gz.sig"
pcre2_distro_url="ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre2-10.10.tar.gz"
pcre2_signature_url="ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre2-10.10.tar.gz.sig"
pcre_keys_url="ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/Public-Key"
pcre_prefix="/usr/local/pcre"

#if download $pcre_distro_url "gpg" $pcre_keys_url $pcre_signature_url; then
#  #echo 'good pcre sig'
#  rm -rf $(basename $pcre_keys_url) $(basename $pcre_signature_url)
#
#  filename=$(basename $pcre_distro_url)
#  filename=${filename%.*}
#  pcre_dir=${filename%.*}
#
#  tar zxf $(basename $pcre_distro_url)
#  if [ "$pcre_prefix" = '' ]; then
#    pcre_prefix="/usr/local/pcre"
#  fi 
#   
#  $pcre_dir/configure --prefix=$pcre_prefix
#  make
#  sudo make install 
#fi

if download $aprutil_distro_url "gpg" $aprutil_keys_url $aprutil_signature_url; then
  #echo 'good aprutil sig'
  rm -rf $(basename $aprutil_keys_url) $(basename $aprutil_signature_url)

  filename=$(basename $aprutil_distro_url)
  filename=${filename%.*}
  dir=${filename%.*}

  tar zxf $(basename $aprutil_distro_url)
fi

if download $apr_distro_url "gpg" $apr_keys_url $apr_signature_url; then
  #echo 'good apr sig'
  rm -rf $(basename $apr_keys_url) $(basename $apr_signature_url)

  filename=$(basename $apr_distro_url)
  filename=${filename%.*}
  dir=${filename%.*}

  tar zxf $(basename $apr_distro_url)
fi

if download $apache2_distro_url "gpg" $apache2_keys_url $apache2_signature_url; then
  #echo 'good apache2 sig'
  rm -rf $(basename $apache2_keys_url) $(basename $apache2_signature_url)

  filename=$(basename $apache2_distro_url)
  filename=${filename%.*}
  apache2_dir=${filename%.*}

  tar zxf $(basename $apache2_distro_url)

  # copy apr and aprutil to srclib
  filename=$(basename $apr_distro_url)
  filename=${filename%.*}
  apr_dir=${filename%.*}
  mkdir -p $apache2_dir/srclib/apr
  cp -R $apr_dir/* $apache2_dir/srclib/apr/

  filename=$(basename $aprutil_distro_url)
  filename=${filename%.*}
  aprutil_dir=${filename%.*}
  mkdir -p $apache2_dir/srclib/apr-util
  cp -R $aprutil_dir/* $apache2_dir/srclib/apr-util/

  if [ "$apache2_prefix" = '' ]; then
    $apache2_prefix="/usr/local/apache2"
  fi

#  $apache2_dir/configure --prefix=$apache2_prefix --with-included-apr --with-pcre=$pcre_prefix/bin/pcre-config
  $apache2_dir/configure
     --prefix=$apache2_prefix
     --with-included-apr
     --enable-so
     --enable-mods-shared="proxy cache ssl all"
     --enable-ssl
     --with-ssl="/usr/include/openssl"
     --enable-ssl-staticlib-deps
     --enable-mods-static=ssl

  make
  sudo make install
fi