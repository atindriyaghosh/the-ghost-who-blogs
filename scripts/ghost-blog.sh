#!/bin/bash
# ***************************************************************
# * SCRIPT NAME: ghost-blog.sh                  				*
# *                                             				*
# * VERSION: 1.0.2                              				*
# *                                             				*
# * DATE MODIFIED (MM-DD-YYYY): 06-07-2014      				*
# *                                             				*
# * AUTHOR: Atindriya Ghosh                     				*
# *                                             				*
# * FUNCTIONS:                                  				*
# * 1. Start the blog                           				*
# * 2. Stop the blog                            				*
# * 3. Restart the blog                         				*
# * 4. Deploy the latest release artifacts      				*
# * 5. List all deployed artifacts      						*
# * 6. Clean deployment path by removing specified artifact     *
# ***************************************************************
## Functions
usage(){
    echo "PARAMETERS:"
    echo "1. $(tput setaf 6)./ghost-blog.sh -s$(tput sgr 0) or $(tput setaf 6)./ghost-blog.sh --start$(tput sgr 0)$(tput sgr 0) - Starts the blog"
    echo "2. $(tput setaf 6)./ghost-blog.sh -t$(tput sgr 0) or $(tput setaf 6)./ghost-blog.sh --terminate$(tput sgr 0)$(tput sgr 0) - Stops the blog"
	echo "3. $(tput setaf 6)./ghost-blog.sh -r$(tput sgr 0) or $(tput setaf 6)./ghost-blog.sh --restart$(tput sgr 0)$(tput sgr 0) - Restarts the blog"
	echo "4. $(tput setaf 6)./ghost-blog.sh -d <Artifact Path> <Release Version> <Deployment Path>$(tput sgr 0) or $(tput setaf 6)./ghost-blog.sh --deploy <Artifact Path> <Release Version> <Deployment Path>$(tput sgr 0)$(tput sgr 0) - Deploy the latest release"
	echo "5. $(tput setaf 6)./ghost-blog.sh -l <Deployment Path>$(tput sgr 0) or $(tput setaf 6)./ghost-blog.sh --list <Deployment Path>$(tput sgr 0)$(tput sgr 0) - List all deployed artifacts"
	echo "6. $(tput setaf 6)./ghost-blog.sh -c <Deployment Path> <Artifact Name>$(tput sgr 0) or $(tput setaf 6)./ghost-blog.sh --clean <Deployment Path> <Artifact Name>$(tput sgr 0)$(tput sgr 0) - Clean deployment path by removing specified artifact"
}
startup(){ 
	echo "$(tput setaf 3)Starting The Blog ...$(tput sgr 0)"
	sudo rm -rf /var/cache/nginx/*
	sudo service nginx restart
	sudo NODE_ENV=production forever start /var/www/index.js
	echo "$(tput setaf 2)Blog Started Successfully$(tput sgr 0)"
}
shutdown(){ 
	echo "$(tput setaf 3)Stopping The Blog ...$(tput sgr 0)"
	sudo forever stop /var/www/index.js
	sudo service nginx stop
	echo "$(tput setaf 2)Blog Stopped Successfully$(tput sgr 0)"
}
restart(){ 
	echo "$(tput setaf 3)Restarting The Blog ...$(tput sgr 0)"
	shutdown
	startup
	echo "$(tput setaf 2)Blog Restarted Successfully$(tput sgr 0)"
}
deploy(){ 
	shutdown
	echo "$(tput setaf 3)Deploying Latest Release Artifacts ...$(tput sgr 0)"
	dir_path="$3"
	dir_name="the-ghost-who-blogs-$2"
	version="$2"
	date=`date +"%Y-%m-%d %T"`
	echo "$(tput setaf 3)Deployed Artifact Location = $dir_name$(tput sgr 0)"
	cd $dir_path
	sudo rm -rf $dir_name
	sudo mkdir $dir_name
	cd $dir_name
	sudo unzip "$1"
	release_json="{\"artifactName\":\"The-Ghost-Who-Blogs\",\"artifactVersion\":\"$version\",\"releaseDate\":\"$date\"}"
	echo "$(tput setaf 3)Release Details$(tput sgr 0)"
	echo $release_json | python -mjson.tool | sudo tee RELEASE_INFO.json
	cd /var/www
	echo "$(tput setaf 2)Release Artifacts Deployed Successfully$(tput sgr 0)"
	startup
}
list(){
	dir_path="$1"
	artifacts=`ls -l $dir_path | egrep '^d' | awk '{print $9}'`
	echo "$(tput setaf 3)Currently deployed artifacts$(tput sgr 0)"
	count=1
	for artifact in $artifacts
	do
		echo "  $(tput setaf 4)$count.$(tput sgr 0) $artifact"
		count=$((count + 1))
	done
	
}
clean(){
	dir_path="$1"
	dir_name="$2"
	echo "$(tput setaf 3)Cleaning artifact $dir_name ...$(tput sgr 0)"
	sudo rm -rf $dir_path/$dir_name
	echo "$(tput setaf 3)Cleaning successful$(tput sgr 0)"
}
## Main
while [ "$1" != "" ]; do
    case $1 in
    	"-s" | "--start"	)	startup
							exit
							;;
		"-t" | "--terminate")	shutdown
							exit
							;;
		"-r" | "--restart"	)	restart
							exit
							;;
		"-d" | "--deploy"	)	
							if [ $# -eq 3 ]; 
							then
								echo "$(tput setaf 1)Please pass artifact path, release version and deployment path$(tput sgr 0)"
								usage
							else
								deploy $2 $3 $4
							fi
							exit
							;;
		"-l" | "--list"	)	if [ $# -eq 1 ]; 
							then
								echo "$(tput setaf 1)Please pass deployment path$(tput sgr 0)"
								usage
							else
								list $2
							fi
							exit
							;;
		"-c" | "--clean")	if [ $# -eq 2 ]; 
							then
								echo "$(tput setaf 1)Please pass deployment path and artifact name$(tput sgr 0)"
								usage
							else
								clean $2 $3
							fi
							exit
							;;
		"-h" | "--help"		)	usage
							exit
							;;
		*					)	echo "$(tput setaf 1)Please pass the available parameters$(tput sgr 0)"
							usage
							exit
	esac
done
if ["$1" == ""]; then
	echo "$(tput setaf 1)Please pass the available parameters$(tput sgr 0)\n"
	usage
fi