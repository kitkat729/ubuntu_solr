#!/bin/bash

install_solr_plugins() {
	if [[ $(dpkg --get-selections | grep ant) = '' ]]; then
		sudo apt-get -y install ant
	fi

	# @link http://lucidworks.com/blog/solution-for-multi-term-synonyms-in-lucenesolr-using-the-auto-phrasing-tokenfilter/
	# auto-phrase-tokenfilter - contributed by LucidWorks
	rm -rf auto-phrase-tokenfilter
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

	if [[ ! -s $solr_home/data/lib ]]; then
		mkdir $solr_home/data/lib
	fi

	if [[ -s dist/auto-phrase-tokenfilter-1.0.jar && ! -s $solr_home/data/lib/auto-phrase-tokenfilter-1.0.jar ]]; then
		cp dist/auto-phrase-tokenfilter-1.0.jar $solr_home/data/lib

		core='ih-articles' # temporary defined the core name here
		touch $solr_home/data/$core/conf/autophrases.txt
	fi
}
