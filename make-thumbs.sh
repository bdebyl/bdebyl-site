#!/bin/sh
{ usage="$(cat)"; }<<'EOF'
USAGE
    make-thumbs.sh [OPTIONS] <path>

DESCRIPTION
    Recursively searches through the passed path, ignoring existing thumbnails,
    and generates thumbnails for images greater than 600px in width.

OPTIONS
    -h, --help         Shows this help prompt
    -d, --dry-run      Dry-run that will not create actual thumbnails
EOF

die() {
    printf '%s\n' "$1" >&2
    exit 1
}

show_help() {
    printf '%s\n' "$usage"
    exit
}

while :; do
    case $1 in
        -h|-\?|--help)
            show_help
            exit
            ;;
        -d|--dry-run)
            DRYRUN=1
            ;;
        --)
            shift
            break
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            ;;
        *)
            if [ "$1" ]; then
                BROWSE_PATH=$1
            else
                break
            fi
            ;;
    esac

    shift
done

if [ -z "$BROWSE_PATH" ]; then
    die 'ERROR: path not specified! (See -h/--help)'
fi

CONVERT=$(command -v convert)
if [ ! "$CONVERT" ]; then
    echo "ERROR: imagemagick must be installed!"
    exit 1
fi

find "$BROWSE_PATH" -type f -not -path '*thumb*' | while read -r i; do
    THUMB_PATH="$(dirname "$i")/thumb"
    IMG_NAME="$(basename "$i")"

    # Generate a thumbnail if the width is greater than 600px
    if [ "$(identify -format "%w" "$i")" -gt 600 ]; then
        # Create the thumbnail directory fo the image to be made
        if [ ! -d "$THUMB_PATH" ]; then
            if [ ! "$DRYRUN" ]; then
                mkdir -p "$THUMB_PATH"
            fi
        fi

        # Create the thumbnail image
        if [ ! -f "$THUMB_PATH/$IMG_NAME" ]; then
            printf "└─ Converting %s to thumbnail in %s \n" "$BROWSE_PATH/$IMG_NAME" "$THUMB_PATH"
            if [ ! "$DRYRUN" ]; then
                "$CONVERT" -resize 600x "$i" "$THUMB_PATH/$IMG_NAME";
            fi
        fi
    fi
done
