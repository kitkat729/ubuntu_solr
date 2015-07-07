#!/bin/bash

# Download a file from the give file url. Optionally do checksum verification if parameters are supplied
#
# @param string file		file download url
# @param string key_type 	checksum key type. Support gpg only for now
# @param string keys		key file download url
# @param string signature 	signature download url
# @return boolean			0=good download, 1=bad download
download() {
   local file=$1 key_type=$2 keys=$3 signature=$4
   wget $file

   if [ ! "$keys" = '' ]; then
     if verify_signature $key_type $keys $signature; then
        return 0
     else
        return 1
     fi
   fi
   return 0
}

#distro_fprint="A93D62ECC3C8EA12DB220EC934EA76E6791485A8"

# Do checksum verification
#
# @param string key_type 	checksum key type. Support gpg only for now
# @param string keys		key file download url
# @param string signature 	signature download url
# @return boolean			0=good signature, 1=bad signature
verify_signature() {
  local key_type=$1 keys=$2 signature=$3 out=

  case "$key_type" in
    "gpg")
      wget $keys
      wget $signature
      gpg --import $(basename $keys) >/dev/null 2>&1

      if out=$(gpg --status-fd 1 --verify $(basename $signature) 2>/dev/null) &&
        echo "$out" | grep -qs "^\[GNUPG:\] GOODSIG" &&
        echo "$out" | grep -qs "^\[GNUPG:\] VALIDSIG"; then
       #echo "$out" | grep -qs "^\[GNUPG:\] TRUST_ULTIMATE\$"; then
        return 0
      else
        echo "$out" >&2
        return 1
      fi
      ;;
    *) return 0
      ;;
   esac
}