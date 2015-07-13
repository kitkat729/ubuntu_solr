#!/bin/bash

# This script sets up solr a single instance mode, sets up java if it does not exist,
# configure the new solr to a production-like instance

# supports download from oracle only
java_7_url='http://download.oracle.com/otn-pub/java/jdk/7u67-b01/jdk-7u67-linux-x64.tar.gz'
java_8_url='http://download.oracle.com/otn-pub/java/jdk/8u45-b14/jdk-8u45-linux-x64.tar.gz'
java_distro_url=$java_8_url
java_prefix="/usr/lib/jvm"

solr_distro_url='http://mirror.symnds.com/software/Apache/lucene/solr/5.2.1/solr-5.2.1.tgz'
solr_prefix="/opt"
solr_runas="ubuntu"
# config for a standalone instance named 'solr' at a port
solr_id="solr"
solr_port="8983"
solr_home="/var/$solr_id"
solr_host='ec2-54-211-112-13.compute-1.amazonaws.com'	# bare host name or ip

git_handle='https://github.com/kitkat729'
git_repo_name="ubuntu_solr_$solr_id"

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
	# There is no better ways to detect solr but to check solr service
	if [[ "$(sudo service solr status 2>&1)" == "solr: unrecognized service" ]]; then
		return 1
	else
		return 0
	fi
}

solr_config() {
	local solr_instance_dir=$1 solr_instance_home=$2
	#echo 'config standalone solr'

	if [[ ! -f $solr_instance_home/solr.in.sh.orig ]]; then
		cp $solr_instance_home/solr.in.sh $solr_instance_home/solr.in.sh.orig
	fi

	# @todo Find out why SOLR_HOST does not override the default setting
	sed -i "/SOLR_HOST=\"$solr_host\"/d" $solr_instance_home/solr.in.sh
	sed -i -r "s/^(SOLR_HOST=.*)/# \1/g" $solr_instance_home/solr.in.sh 	# bash sed uses -r instead of -e
	echo "SOLR_HOST=\"$solr_host\"" >> $solr_instance_home/solr.in.sh

	# make sure the instance is running to accept commands
	$solr_instance_dir/bin/solr restart -p $solr_port -s $solr_instance_home

	# Specs:
	# Creates a standalone core using the default data_driven_schema without -d or -n options
	# -d is the custom config directory (use data_driven_schema for now)
	# -n is the config name (will be same as the core name)
	solr_core='ih-articles'
	$solr_instance_dir/bin/solr create -c $solr_core -p $solr_port

	# ref: run bin/solr delete -c <name> -p <port> [-deleteConfig (true|false)]

	# A core should have been created by now. An empty private remote repo must have been created at a git handle
	# git username and password may be required.
	# Push the entire home folder to the git repo
	cd $solr_instance_home

	if [[ -f .gitignore ]]; then
		sed -i -r "/logs\/\*/d" .gitignore
		sed -i -r "/data\/$solr_core\/data\/\*/d" .gitignore
		sed -i -r "/\*\.pid/d" .gitignore
	fi
	echo "logs/*" >> .gitignore
	echo "data/$solr_core/data/*" >> .gitignore
	echo "*.pid" >> .gitignore

	readme=''
	echo "$readme" >> README.md

	git init --shared
	git add .
	git commit -m "initial commit. Added a new core"
	git remote add origin $git_handle/$git_repo_name
	git push origin master	# push working master to remote master
}

if ! check_java; then
	echo 'Installing Java'

	#default settings
	[[ ! $java_prefix == '' ]] || java_prefix="/usr/lib/jvm"

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
if ! check_jre '1.7'; then
	echo 'JRE requirement not met'
	exit 1
fi

if ! check_solr && download $solr_distro_url; then
	echo 'Installing Solr'

	# default settings
	[[ ! $solr_prefix == '' ]] || solr_prefix="/opt"
	[[ ! $solr_runas == '' ]] || $solr_runas="solr"
	[[ ! $solr_id == '' ]] || solr_id="solr"
	[[ ! $solr_port == '' ]] || solr_port="8983"
	[[ ! $solr_home == '' ]] || solr_home="/var/$solr_id"

	solr_dir=$(tar zft $(basename $solr_distro_url) | head -n1 | cut -f1 -d/)
	tar zxf $(basename $solr_distro_url) $solr_dir/bin/install_solr_service.sh --strip-components=2

	# install_solr_service.sh will setup a production-like environment where application is separated from data and log
	sudo bash ./install_solr_service.sh $(basename $solr_distro_url) -i $solr_prefix -d $solr_home -u $solr_runas -s $solr_id -p $solr_port
	sudo service $solr_id status

	solr_config $solr_dir $solr_home

	# dev notes:
	# @link https://cwiki.apache.org/confluence/display/solr/Taking+Solr+to+Production
	# solr server config is stored at $solr_home/solr.in.sh
	# solr installed a service script at /etc/init.d/solr
	# solr defaults SOLR_HEAP (Java Heap) to to 512M. In production, setting memory size to 10-20 GB is not uncommon. Do it at $solr_home/solr.in.sh
	# SOLR_JAVA_MEM (not used by default) gives finer memory control over SOLR_HEAP

	# @link https://cwiki.apache.org/confluence/display/solr/Solr+Start+Script+Reference#SolrStartScriptReference-SolrCloudMode
	# solr may be setup as a cloud server where multiple solr can exist on a single machine using shards and replication
	# cloud solr has a collection core. The collection core config gets copied to the Solr embedded Zookeeper to be shared among multiple collections.
	# Embedded Zookeeper is not supported in production environment. You need to install Zookeeper(s) and map the host(s) separately

	# operations:
	# sudo service solr (start|stop|restart|status)
	#
	# solr can also operate with just the solr script bin/solr from the Solr directory
	# @link https://cwiki.apache.org/confluence/display/solr/Running+Solr
else
	# just config without installing solr
	solr_dir="$solr_prefix/solr"
	solr_config $solr_dir $solr_home
fi

echo 'Completed solr setup.'