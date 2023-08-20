#!/usr/bin/env bash
SERVICE_NAME="service-b"
GITLAB_TOKEN=""
TARGET_BRANCH="main"
MANIFEST_PATH="${SERVICE_NAME}.yaml"

mkdir tmp-gitops \
&& cd tmp-gitops

git clone https://gitlab.com/guybalmas/tap-gitops.git \
&& cd tap-gitops \
&& git checkout $TARGET_BRANCH

COMMIT_HASH=$(git log --oneline $MANIFEST_PATH | head -2 | sed -n 2p | cut -d " " -f1 | sed -z '$ s/\n$//')
COMMIT_BRANCH="revert-${TARGET_BRANCH}-${SERVICE_NAME}-to-${COMMIT_HASH}"

echo "Commit Hash: ${COMMIT_HASH}"
echo "Commit Branch: ${COMMIT_BRANCH}"

git branch ${COMMIT_BRANCH} \
&& git checkout ${COMMIT_BRANCH} \
&& git checkout ${COMMIT_HASH} -- ${MANIFEST_PATH} \
&& git commit -m "Reverted to commit: [${COMMIT_HASH}]"

git push -u origin ${COMMIT_BRANCH}

jx-scm pull-request create \
  --kind "gitlab" \
  --server "https://gitlab.com" \
  --owner "my-gitops-repo-owner" \
  --name "tap-gitops" \
  --head ${COMMIT_BRANCH} \
  --title "Revert ${SERVICE_NAME} in ${TARGET_BRANCH} to ${COMMIT_HASH}" \
  --body "Revert of ${SERVICE_NAME} commit: [${COMMIT_HASH}] is ready for review" \
  --base ${TARGET_BRANCH} \
  --token ${GITLAB_TOKEN} \
  --username "my-git-username"

rm -rf ../../tmp-gitops