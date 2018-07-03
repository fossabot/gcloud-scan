#!/usr/bin/env bash

SCANFOR="$1"
EXCLUDE="$2"

[[ -z  $EXCLUDE ]] && EXCLUDE="^$"

declare -A SIMPLESCOPES=(
    [sshkeys]="compute project-info describe"
    [instances]="compute instances list"
    [service-accounts]="iam service-accounts list"
)

# Iterate over all projects
for PROJECT in $(gcloud projects list --format="value(projectId)" | sort); do
    echo "Scanning Project $PROJECT..."
    echo " for IAM Users..."
    gcloud projects get-iam-policy "$PROJECT" | egrep -v "$EXCLUDE" | egrep -i --color=always "$SCANFOR" | sort
    # Iterate over all simple scopes
    for SIMPLESCOPE in "${!SIMPLESCOPES[@]}"; do
	echo " for $SIMPLESCOPE..."
	gcloud ${SIMPLESCOPES[$SIMPLESCOPE]} --project="$PROJECT" | egrep -v "$EXCLUDE" | egrep -i --color=always "$SCANFOR" | sort
    done
    echo " for Cloud SQL Users..."
    for SQLINSTANCE in $(gcloud sql instances list --project="$PROJECT" --filter STATUS:RUNNABLE --format="value(name)"); do
	echo "  ... instance $SQLINSTANCE:"
	gcloud sql users list --project="$PROJECT" --instance="$SQLINSTANCE" | egrep -v "$EXCLUDE" | egrep -i --color=always "$SCANFOR" | sort
    done
    echo; echo
done
