#!/bin/bash

# supports download from oracle only
java_7_url='http://download.oracle.com/otn-pub/java/jdk/7u67-b01/jdk-7u67-linux-x64.tar.gz'
java_8_url='http://download.oracle.com/otn-pub/java/jdk/8u45-b14/jdk-8u45-linux-x64.tar.gz'
java_distro_url=$java_8_url
java_prefix="/usr/lib/jvm"

solr_distro_url='http://mirror.symnds.com/software/Apache/lucene/solr/5.2.1/solr-5.2.1.tgz'
solr_prefix="/opt"
solr_home="/var/solr"
solr_runas="ubuntu"
solr_service_name="solr"
solr_service_port="8983"

. util.sh

setup_root="_setup"
[[ ! -s $setup_root ]] || rm -rf $setup_root
mkdir $setup_root
cd $setup_root

check_java() {
	if [[ "$(which java)" == '' ]]; then
		return 1
	else
		return 0
	fi
}

check_jre() {
	local version= min_version=$1

	if [[ "$min_version" == '' ]]; then
		echo "check_jre error: the min version must be specified in order to compare with existing version"
		exit 1
	fi

	if [[ ! "$(which java)" == '' ]] && version=$(echo $(java -version 2>&1) | awk 'NR==1{ gsub(/"/,""); print ($3)*1 }') && [ ! "$version" == '' ] && [ $(echo " $version >= $min_version" | bc) -eq 1 ]; then
		#echo 'current version='$version
		return 0
	else
		return 1
	fi
}

check_solr() {

}

if ! check_java; then
	echo 'install java'

	if [[ ! -s $java_prefix ]]; then
		sudo mkdir -p $java_prefix
	fi

	wget --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" $java_distro_url
	tar zxf $(basename $java_distro_url)

	version_name=$(echo $(basename $java_distro_url) | awk '{split($0,a,"-"); split(a[2],b,"u"); dir=a[1]"1."b[1]".0_"b[2]; print dir;}')
	version_id=$(echo $(basename $java_distro_url) | awk '{split($0,a,"-"); split(a[2],b,"u"); print b[1];}')
	[[ ! -s $java_prefix/$version_name ]] || sudo rm -rf $java_prefix/$version_name
	sudo mv $version_name $java_prefix
	sudo chown -R root:root $java_prefix/$version_name
	sudo rm $(basename $java_distro_url)

	symlink="java-"$version_id"-oracle"
	[[ ! -s $java_prefix/$symlink ]] || sudo rm $java_prefix/$symlink
	sudo ln -s $java_prefix/$version_name $java_prefix/$symlink

	# tell ubuntu that java exists. Note: pointing alternative directly to the folder here!
	sudo update-alternatives --install /usr/bin/javac javac $java_prefix/$version_name/bin/javac 1
	sudo update-alternatives --install /usr/bin/java java $java_prefix/$version_name/bin/java 1
	sudo update-alternatives --install /usr/bin/jar jar $java_prefix/$version_name/bin/jar 1
	sudo update-alternatives --set javac $java_prefix/$version_name/bin/javac
	sudo update-alternatives --set java $java_prefix/$version_name/bin/java
	sudo update-alternatives --set jar $java_prefix/$version_name/bin/jar

	# add java info to profile
	sudo chmod 666 /etc/profile
	sudo echo "JAVA_HOME=$java_prefix/$symlink  # Added by solr_setup.sh" >> /etc/profile
	sudo echo "PATH=$PATH:$JAVA_HOME/bin  # Added by solr_setup.sh" >> /etc/profile
	sudo echo "export JAVA_HOME  # Added by solr_setup.sh" >> /etc/profile
	sudo echo "export PATH  # Added by solr_setup.sh" >> /etc/profile
	sudo chmod 644 /etc/profile
	source /etc/profile
fi

# this probably is unnecessary because java should have been installed by now
if ! check_jvm '1.7'; then
	echo 'jvm requirement unmet'
	exit 1
fi