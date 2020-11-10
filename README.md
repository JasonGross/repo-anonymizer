# repo-anonymizer
A small script that anonymizes repos for paper submission

# Usage

    ./anonymize-repo.sh [--zip] [--only-subdir SUBDIR] BLACKLIST_FILE DIRECTORY_TO_PACKAGE [NEW_DIRECTORY_NAME]

- `SUBDIR` - Only perform anonymization in the given subdirectory (default: `.`)
- `BLACKLIST_FILE` - newline separated list of sed-escaped search patterns
- `DIRECTORY_TO_PACKAGE` - path to the folder to create an anonymized version of
- `NEW_DIRECTORY_NAME` - the name that replaces the last component of `DIRECTORY_TO_PACKAGE` in the archive

Everything in the HEAD commit of the git tree gets packaged
