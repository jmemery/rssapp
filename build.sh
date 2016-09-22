#!/bin/bash

if test $# -lt 1 ; then
    echo "Usage: build.sh <config filename>"
    echo "Here is a list of current possibilities (config files under build-configs dir):"
    find build-configs -name "*.config" -print | sed -e 's/build-configs\/*/           /'
    exit 0
fi

CONFIG_FILENAME=$1

echo "Loading this config file: ${CONFIG_FILENAME}"
. "build-configs/${CONFIG_FILENAME}"

CHANGES=$(curl -s "$BUILD_URL/api/xml?wrapper=changes&xpath=//changeSet//comment")
CHANGES=$(echo $CHANGES | sed -e "s/<\/comment>//g; s/<comment>//g; s/<\/*changes>//g" | sed '/^$/d;G')

echo $CHANGES

bundle install
bundle exec pod install
bundle exec ipa build -s $SCHEME --clean --verbose
bundle exec ipa distribute:testflight -a $TESTFLIGHT_UPLOAD_TOKEN -T $TESTFLIGHT_TEAM_TOKEN -m "$CHANGES" -l $TESTFLIGHT_GROUP_NOTIFY --notify

echo ""
echo "***********************************************************"
echo "DONE with config:$SCHEME"
echo "***********************************************************"
echo ""