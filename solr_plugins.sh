#!/bin/bash

install_solr_plugins() {
	#sudo apt-get -y install ant

	# auto-phrase-tokenfilter
	git clone https://github.com/LucidWorks/auto-phrase-tokenfilter.git
	cd auto-phrase-tokenfilter
	settings='<ivysettings>
    <settings defaultResolver="repo-chain"/>
    <resolvers>
        <ibiblio name="central" m2compatible="true"/>
	<ibiblio name="maven-restlet" root="http://maven.restlet.org/" m2compatible="true" />
	<chain name="repo-chain">
	  <resolver ref="central"/>
	  <resolver ref="maven-restlet"/>
	</chain>
    </resolvers>
</ivysettings>'
	echo $settings > ivy/ivy-settings.xml
	ant

	if [[ -s dist/auto-phrase-tokenfilter-1.0.jar ]]; then
		if [[ ! -s $solr_home/lib ]]; then
			mkdir $solr_home/lib
		fi

		cp dist/auto-phrase-tokenfilter-1.0.jar $solr_home/lib
	fi
}