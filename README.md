# repo-anonymizer
A small script that anonymizes repos for paper submission

# Usage

    ./anonymize-repo.sh [--zip] [--only-subdir SUBDIR] [--no-test] BLACKLIST_FILE DIRECTORY_TO_PACKAGE [NEW_DIRECTORY_NAME]

- `SUBDIR` - Only perform anonymization in the given subdirectory (default: `.`)
- `BLACKLIST_FILE` - newline separated list of sed-escaped search patterns
- `DIRECTORY_TO_PACKAGE` - path to the folder to create an anonymized version of
- `NEW_DIRECTORY_NAME` - the name that replaces the last component of `DIRECTORY_TO_PACKAGE` in the archive
- `--zip` - create a .zip file rather than a .tar.gz
- `--no-test` - don't run 'make' in the anonomized folder (done by default as a sanity check)

Everything in the HEAD commit of the git tree gets packaged
