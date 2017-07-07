#!/bin/bash

EXT="tar.gz"
function maybe_parse_next_opt() {
    if [ "$1" == "--zip" ]; then
	EXT="zip"
	shift
    fi
}

maybe_parse_next_opt
SEARCH_FOR_FILE="$1"
maybe_parse_next_opt
DIRECTORY="$2"
maybe_parse_next_opt
NEW_NAME="$3"
maybe_parse_next_opt
DIR_EXTRA="-anonymized"
REPLACEMENT="REDACTED"
BAD_FILES=".gitmodules .gitattributes .gitignore .mailmap .travis.yml AUTHORS CONTRIBUTORS"
SED_SPECIAL_CHARACTER="~"


if [ -z "${SEARCH_FOR_FILE}" ] || [ -z "${DIRECTORY}" ]; then
    echo "USAGE: $0 [--zip] BLACKLIST_FILE DIRECTORY_TO_PACKAGE"
    echo "BLACKLIST_FILE - newline separated list of sed-escaped search patterns"
    echo "DIRECTORY_TO_PACKAGE - path to the folder to create an anonymized version of"
    echo ""
    echo "Everything in the HEAD commit of the git tree gets packaged"
    exit 1
fi

REPLACE_FROM="$(printf "%s" "$(< "$SEARCH_FOR_FILE")" | tr '\n' '|' | sed s'/|/\\|/g')"
if [ -z "$NEW_NAME" ]; then
    NEW_NAME="$(basename $(cd "$DIRECTORY" && pwd))${DIR_EXTRA}"
fi

if [ ! -z "$(echo "${REPLACE_FROM}" | grep "${SED_SPECIAL_CHARACTER}")" ]; then
    echo "ERROR: Blacklist file $SEARCH_FOR_FILE cannot contain $SED_SPECIAL_CHARACTER"
    exit 1
fi


echo 'The following instances will be redacted:'
(cd "$DIRECTORY" && git --no-pager grep -i "$REPLACE_FROM")
echo 'The above instances will be redacted when creating ${NEW_NAME}.tar.gz.'
echo 'Press ENTER to continue, or C-c to break.'
read

# http://stackoverflow.com/a/10983009/377022
mydir="$(mktemp -d "${TMPDIR:-/tmp/}$(basename "$0").XXXXXXXXXXXX")"
function cleanup {
    if [ -z "$NO_CLEANUP" ]; then
	rm -rf "$mydir"
    fi
}
trap cleanup INT TERM EXIT

cp -a "$DIRECTORY" "$mydir/$NEW_NAME"

pushd "$mydir/$NEW_NAME" >/dev/null
git clean -xfd
git reset --hard
git submodule foreach git clean -xfd
git submodule foreach git reset --hard
git submodule foreach rm -rf $BAD_FILES
rm -rf $BAD_FILES
rm -rf "$(basename "$SEARCH_FOR_FILE")" "$SEARCH_FOR_FILE"
find . -name .git | xargs rm -rf
git init
git add .
git grep --name-only -i "$REPLACE_FROM" | xargs sed s"${SED_SPECIAL_CHARACTER}${REPLACE_FROM}${SED_SPECIAL_CHARACTER}${REPLACEMENT}${SED_SPECIAL_CHARACTER}gI" -i
git --no-pager diff
git add .
if [ ! -z "$(git grep -i "$REPLACE_FROM")" ]; then
    echo 'Failed to make all replacements:'
    git grep -i "$REPLACE_FROM"
    echo 'Failed to make the above replacements.'
    echo 'Press ENTER to continue, or C-c to break.'
    read
fi
rm -rf .git
cd ..
tar --numeric-owner -a -cvf "${NEW_NAME}.${EXT}" "$NEW_NAME"
popd >/dev/null

cp "$mydir/${NEW_NAME}.${EXT}" ./

cleanup
