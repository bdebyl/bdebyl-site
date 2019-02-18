#!/bin/bash
CONVERT=$(command -v convert)
if [ ! $CONVERT ]; then
    echo "ERROR: imagemagick must be installed!"
    exit 1
fi

for i in $(find static/img/*/ -type f -not -path "*thumb*"); do
    THUMB_PATH=$(dirname $i)/thumb
    IMG_NAME=$(basename $i)

    # Generate a thumbnail if the width is greater than 600px
    if [ $(identify -format "%w" $i) -gt 600 ]; then
        # Create the thumbnail directory fo the image to be made
        if [ ! -d $THUMB_PATH ]; then
            echo "Creating directory $THUMB_PATH..."
            mkdir -p $THUMB_PATH
        fi

        # Create the thumbnail image
        if [ ! -f $THUMB_PATH/$IMG_NAME ]; then
            echo "Converting $IMG_NAME to thumbnail..."
            $CONVERT -resize 600x $i $THUMB_PATH/$IMG_NAME;
        fi
    fi
done
