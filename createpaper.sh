#!/bin/bash
# michaelpeterswa 2021
# createpaper.sh

if [ ! $# -eq 2 ]; then
	echo "Please provide two arguments."
	echo "./createmc.sh {server_name} {version}"
	exit 1
fi

SERVER_NAME=$1
JAR_VERSION=$2
PAPERMC_URL="https://papermc.io/api/v2/projects/paper/versions/$2"
START_SCRIPT="https://raw.githubusercontent.com/michaelpeterswa/createpaper.sh/main/start.sh"

echo "Starting PaperMC server $SERVER_NAME, version $JAR_VERSION"

if ! command -v java &> /dev/null
then
	sudo apt-get install -y openjdk-16-jdk-headless
fi

if ! command -v jq &> /dev/null
then
	sudo apt-get install -y jq
fi

BUILD_NUM=$(curl -sSL $PAPERMC_URL | jq '.builds' | sort -nr | head -n1 | sed 's/^ *//g')
BUILD_URL="$PAPERMC_URL/builds/$BUILD_NUM"
JAR_INFO=$(curl -sSL $BUILD_URL | jq '.downloads.application')
JAR=$(echo $JAR_INFO | jq '.name' | sed -e 's/^"//' -e 's/"$//')
JAR_SHA=$(echo $JAR_INFO | jq '.sha256' | sed -e 's/^"//' -e 's/"$//')
JAR_URL="$BUILD_URL/downloads/$JAR"

download_and_install () {
	curl -sSL $JAR_URL -o $JAR
	RECV_JAR_SHA=$(sha256sum $JAR | cut -d " " -f 1)

	if [ "$RECV_JAR_SHA" = "$JAR_SHA" ]; then
		echo "Jarfile verified."
		echo "eula=true" > eula.txt
		echo "Installing start script..."
		curl -sSL $START_SCRIPT > start.sh
		echo "Starting Server."
		java -Xms4G -Xmx4G -jar $JAR
	else
		echo "Jarfile could not be verified. Exiting..."
		exit 1
	fi
}

if [ ! -d "$SERVER_NAME" ]; then
	mkdir $SERVER_NAME
	cd $SERVER_NAME
	echo "Entered Folder: $SERVER_NAME"
	download_and_install
else
	echo "Folder already exists. Exiting..."
	exit 1
fi
