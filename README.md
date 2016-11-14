# repo-anonymizer
A small script that anonymizes repos for paper submission

# Usage

    ./anonymize.sh BLACKLIST_FILE DIRECTORY_TO_PACKAGE

- `BLACKLIST_FILE` - newline separated list of sed-escaped search patterns
- `DIRECTORY_TO_PACKAGE` - path to the folder to create an anonymized version of

Everything in the HEAD commit of the git tree gets packaged
