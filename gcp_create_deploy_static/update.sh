
#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$0")"

BUCKET_NAME="$(terraform output -raw bucket_name)"

gcloud storage rsync \
    --recursive \
    --delete-unmatched-destination-objects \
    ./site \
    "gs://${BUCKET_NAME}"

echo "Deploy do site concluído!"
