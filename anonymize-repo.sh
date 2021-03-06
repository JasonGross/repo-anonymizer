#!/bin/bash

EXT="tar.gz"
TOOL="tar --numeric-owner -a -cvf"
UNTOOL="tar -xvf"
SUBDIR="."
TEST=yes
JARG=""
if [ ! -z "$J" ]; then JARG="-j$J"; fi
SHIFT_COUNT=0
function parse_opt() {
    if [ "$1" == "--zip" ]; then
	EXT="zip"
	TOOL="zip -r"
	SHIFT_COUNT=1
    elif [ "$1" == "--only-subdir" ]; then
        SUBDIR="$2"
        SHIFT_COUNT=2
    elif [ "$1" == "--no-test" ]; then
        TEST=""
        SHIFT_COUNT=1
    else
	SHIFT_COUNT=0
    fi
}
parse_opt "$@"; shift ${SHIFT_COUNT}
parse_opt "$@"; shift ${SHIFT_COUNT}
parse_opt "$@"; shift ${SHIFT_COUNT}
SEARCH_FOR_FILE="$1"; shift
parse_opt "$@"; shift ${SHIFT_COUNT}
parse_opt "$@"; shift ${SHIFT_COUNT}
parse_opt "$@"; shift ${SHIFT_COUNT}
DIRECTORY="$1"; shift
parse_opt "$@"; shift ${SHIFT_COUNT}
parse_opt "$@"; shift ${SHIFT_COUNT}
parse_opt "$@"; shift ${SHIFT_COUNT}
NEW_NAME="$1"; shift
parse_opt "$@"; shift ${SHIFT_COUNT}
parse_opt "$@"; shift ${SHIFT_COUNT}
parse_opt "$@"; shift ${SHIFT_COUNT}
DIR_EXTRA="-anonymized"
REPLACEMENT="REDACTED"
BAD_FILES=".gitmodules .gitattributes .gitignore .mailmap .travis.yml .github AUTHORS CONTRIBUTORS"
SED_SPECIAL_CHARACTER="~"


if [ -z "${SEARCH_FOR_FILE}" ] || [ -z "${DIRECTORY}" ]; then
    echo "USAGE: $0 [--zip] [--only-subdir SUBDIR] [--no-test] BLACKLIST_FILE DIRECTORY_TO_PACKAGE [NEW_DIRECTORY_NAME]"
    echo "SUBDIR - Only perform anonymization in the given subdirectory (default: .)"
    echo "BLACKLIST_FILE - newline separated list of sed-escaped search patterns"
    echo "DIRECTORY_TO_PACKAGE - path to the folder to create an anonymized version of"
    echo "NEW_DIRECTORY_NAME - the name that replaces the last component of DIRECTORY_TO_PACKAGE in the archive"
    echo "--zip - create a .zip file rather than a .tar.gz"
    echo "--no-test - don't run 'make' in the anonomized folder (done by default as a sanity check)"
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
(cd "$DIRECTORY" && git --no-pager grep -i "$REPLACE_FROM" -- "$SUBDIR")
echo "The above instances will be redacted when creating ${NEW_NAME}.${EXT}."
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
git clean -xffd
git reset --hard
git submodule update --init --recursive
git submodule foreach --recursive git clean -xffd
git submodule foreach --recursive git reset --hard
if [ "$SUBDIR" == "." ]; then
    git submodule foreach --recursive rm -rf $BAD_FILES
fi
(cd "$SUBDIR" && rm -rf $BAD_FILES)
(cd "$SUBDIR" && rm -rf "$(basename "$SEARCH_FOR_FILE")" "$SEARCH_FOR_FILE")
find . -name .git -exec rm -rf "{}" \;
git init
git add .

(cd "$SUBDIR" && (git grep --name-only -i "$REPLACE_FROM" | xargs sed s"${SED_SPECIAL_CHARACTER}${REPLACE_FROM}${SED_SPECIAL_CHARACTER}${REPLACEMENT}${SED_SPECIAL_CHARACTER}gI" -i))
# also handle directory and file names
(cd "$SUBDIR" && (
     do_again=yes;
     while [ "${do_again}" == "yes" ]; do
         do_again="no"
         while read -r dir; do
             newdir="$(echo "$dir" | sed s"${SED_SPECIAL_CHARACTER}${REPLACE_FROM}${SED_SPECIAL_CHARACTER}${REPLACEMENT}${SED_SPECIAL_CHARACTER}gI")"
             if [ "$newdir" != "$dir" ]; then
                 git mv "$dir" "$newdir" || { do_again="yes"; echo "trying again..."; }
             fi
         done < <(find . | sed s',^\./,,g' | grep -v '^\.$' | grep -v '^\.git$' | grep -v '^\.git/')
     done
 ))
git --no-pager diff
git add .
if [ ! -z "$(git grep -i "$REPLACE_FROM" -- "$SUBDIR")" ]; then
    echo 'Failed to make all replacements:'
    git grep -i "$REPLACE_FROM" -- "$SUBDIR"
    echo 'Failed to make the above replacements.'
    echo 'Press ENTER to continue, or C-c to break.'
    read
fi
rm -rf .git
cd ..
${TOOL} "${NEW_NAME}.${EXT}" "${NEW_NAME}"
mkdir "$mydir/__fresh"
cd "$mydir/__fresh"
${UNTOOL} "$mydir/${NEW_NAME}.${EXT}"
popd >/dev/null

cp "$mydir/${NEW_NAME}.${EXT}" ./

if [ ! -z "$TEST" ]; then
    pushd "$mydir/__fresh/${NEW_NAME}" >/dev/null
    make ${JARG}
    popd >/dev/null
fi

cleanup
