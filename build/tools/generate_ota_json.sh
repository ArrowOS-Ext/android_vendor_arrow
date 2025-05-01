#!/bin/bash

if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <TARGET_DEVICE> <PRODUCT_OUT> <FILENAME> <MAINTAINER_NAME> <MOD_VERSION>"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVICE_LIST="$SCRIPT_DIR/device_name.list"
TARGET_DEVICE=$1
PRODUCT_OUT=$2
ARROW_ZIP=$3
MT_NAME=$4
VERSION=$5
FILENAME="$ARROW_ZIP"

if [[ "$FILENAME" =~ ^ArrowExtended.*-(OFFICIAL|UNOFFICIAL)- ]]; then
    BUILDTYPE="${BASH_REMATCH[1]}"
else
    echo "Error: Unable to detect build type (OFFICIAL/UNOFFICIAL) in filename: $FILENAME"
    exit 1
fi

if [[ "$FILENAME" =~ ^ArrowExtended-.*-(GAPPS|VANILLA)\.zip$ ]]; then
    FLAVOR="${BASH_REMATCH[1]}"
else
    echo "Error: Unable to extract build flavor from filename: $FILENAME"
    exit 1
fi

FILE_PATH="$PRODUCT_OUT/$FILENAME"

if [ ! -f "$FILE_PATH" ]; then
    echo "Error: File $FILE_PATH not found."
    exit 1
fi

SIZE=$(stat -c%s "$FILE_PATH")
SUM=$(md5sum "$FILE_PATH" | awk '{print $1}')
DATETIME=$(date +%s)
if [ "$BUILDTYPE" != "OFFICIAL" ]; then
    MAINTAINER=""
else
    MAINTAINER=$MT_NAME
fi

DEVICE_NAME=$(grep "^${TARGET_DEVICE}=" $DEVICE_LIST | cut -d= -f2- | tr -d '"')

if [ -z "$DEVICE_NAME" ] || [ "$BUILDTYPE" != "OFFICIAL" ]; then
    DEVICE_NAME=""
fi

JSON_OUT="$PRODUCT_OUT/$FLAVOR"
if [ ! -d "$JSON_OUT" ]; then
    mkdir -p "$JSON_OUT"
fi
JSON_FILE="$JSON_OUT/${TARGET_DEVICE}.json"

cat > "$JSON_FILE" <<EOF
{
    "response": [
        {
            "device": "$DEVICE_NAME",
            "codename": "$TARGET_DEVICE",
            "maintainer": "$MAINTAINER",
            "timestamp": $DATETIME,
            "filename": "$FILENAME",
            "md5": "$SUM",
            "buildtype": "$BUILDTYPE",
            "size": $SIZE,
            "download": "https://sourceforge.net/projects/arata-labs/files/ArrowOS-Extended/",
            "version": "$VERSION",
            "forum": "https://t.me/HinohArata",
            "changelogs": "https://github.com/ArrowOS-Ext/OTA"
        }
    ]
}
EOF

echo "JSON saved to: $JSON_FILE"
cat $JSON_FILE

exit 0
