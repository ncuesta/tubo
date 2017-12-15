#!/bin/bash

# This script dumps a MySQL database on a remote host, compresses the resulting SQL script,
# and then uploads it to a transfer.sh[1] service, finally printing the URL for the dump on
# the transfer.sh service.
#
# Possible exit statuses are:
#  - 0: Success.
#  - 1: Missing argument: the name of the database to dump.
#  - 2: A required command (see $REQUIRED_COMMANDS for the complete list) is not available
#       on any of the directories in the PATH env variable.
#  - 3: The URL of the remote transfer.sh service is not set in the $TRANSFER_URL env
#       variable.
#
# [1] https://transfer.sh/

set -eo pipefail

if [ $# -eq 0 ]; then
  echo "You need to specify at least the database you want to dump." >&2
  exit 1
fi

REQUIRED_COMMANDS=(curl gzip mysqldump)

for required_cmd in ${REQUIRED_COMMANDS[@]}; do
  if [ -z "$(which ${required_cmd})" ]; then
    echo "Missing required command: ${required_cmd}. Please make sure it is available on your \$PATH and rerun this script." >&2
    exit 2
  fi
done

if [ -z "${TRANSFER_URL}" ]; then
  echo "This script needs an environment variable named \$TRANSFER_URL with the URL of the remote transfer.sh service. Please make sure it is properly set and rerun this script." >&2
  exit 3
fi

DATABASE="$1"
TUBO_USER="${TUBO_USER:-root}"
TUBO_PASS="${TUBO_PASS:-}"
TUBO_HOST="${TUBO_HOST:-localhost}"
EXPIRE_IN="${EXPIRE_IN:-1}" # Expressed in days

# Prepare mysqldump's arguments
MYSQLDUMP_ARGS="-u${TUBO_USER} -h${TUBO_HOST}"
if [ ! -z "${TUBO_PASS}" ]; then
  MYSQLDUMP_ARGS="${MYSQLDUMP_ARGS} -p${TUBO_PASS}"
fi
MYSQLDUMP_ARGS="${MYSQLDUMP_ARGS} ${MYSQLDUMP_EXTRA_ARGS:-}"

# Dump the database | gzip it | upload it to transfer.sh
mysqldump ${MYSQLDUMP_ARGS} ${DATABASE} | gzip -c - - | curl -s --upload-file "-" -H "Max-Days: ${EXPIRE_IN}" "${TRANSFER_URL}/${DATABASE}_$(date +%F).sql.gz"
