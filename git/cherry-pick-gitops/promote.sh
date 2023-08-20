#!/usr/bin/env bash
SERVICE_NAME="service-b"
GITLAB_TOKEN="my-token"
SOURCE_BRANCH="dev"
TARGET_BRANCH="main"
MANIFEST_PATH="${SERVICE_NAME}.yaml"

mkdir tmp-gitops
cd tmp-gitops

git clone https://gitlab.com/guybalmas/tap-gitops.git \
&& cd tap-gitops \
&& git checkout $SOURCE_BRANCH

COMMIT_HASH=$(git log --oneline $MANIFEST_PATH | head -1 | cut -d " " -f1 | sed -z '$ s/\n$//')
COMMIT_BRANCH="cherry-pick-${SOURCE_BRANCH}-${SERVICE_NAME}-to-${COMMIT_HASH}"

echo "Commit Hash: ${COMMIT_HASH}"
echo "Commit Branch: ${COMMIT_BRANCH}"

git checkout ${TARGET_BRANCH} \
&& git branch ${COMMIT_BRANCH} \
&& git checkout ${COMMIT_BRANCH} \
&& git cherry-pick ${COMMIT_HASH}

git push -u origin ${COMMIT_BRANCH}

jx-scm pull-request create \
  --kind "gitlab" \
  --server "https://gitlab.com" \
  --owner "my-gitops-repo-owner" \
  --name "tap-gitops" \
  --head ${COMMIT_BRANCH} \
  --title "Promote ${SERVICE_NAME} Cherry Pick ${SOURCE_BRANCH} to ${TARGET_BRANCH}" \
  --body "cherry-pick promotion of ${SERVICE_NAME} commit: [${COMMIT_HASH}] is ready for review" \
  --base ${TARGET_BRANCH} \
  --token ${GITLAB_TOKEN} \
  --username "my-git-user"

rm -rf ../../tmp-gitops