#!/bin/bash
#
# File: jobs/scripts/my_first_job.sh
#

# Enable 'debug' mode.
set -ex

COUNT=0

while [[ ${COUNT} -lt ${MAX_COUNT} ]]; do
    echo ${MESSAGE}
    sleep 1
    COUNT=$((COUNT+1))
done

exit 0
