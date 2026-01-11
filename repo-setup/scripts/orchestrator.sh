#!/bin/sh
set -e

SCRIPT_DIR=$(dirname "$0")
WORK_DIR=$(mktemp -d)

cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

echo "=== Step 1: Creating project ==="
. "$SCRIPT_DIR/create_project.sh"

if [ -n "$SKELETON_REPO_URL" ]; then
  echo "=== Step 2: Merging skeleton ==="
  . "$SCRIPT_DIR/merge_skeleton.sh"
fi

echo "=== Step 3: Push to GitLab ==="
cd "$WORK_DIR/$APP_NAME"
git config user.email "$GIT_USER_EMAIL"
git config user.name "$GIT_USER_NAME"
git init
[ -f "amplify_outputs.json" ] && git add -f amplify_outputs.json
git add .
git commit -m "Initial commit with Vite + Amplify Gen 2"
git branch -M main
git remote add origin "https://oauth2:${GITLAB_TOKEN}@gitlab.com/${GITLAB_GROUP}/${APP_NAME}.git"
git push -u origin main

echo "=== Done ==="