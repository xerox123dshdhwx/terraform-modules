#!/bin/sh
set -e

APP_NAME=$1
GITLAB_TOKEN=$2
GITLAB_GROUP=$3
SKELETON_REPO=$4
EXTRA_DEPS=$5
EXTRA_DEV_DEPS=$6
SKELETON_FOLDERS=$7
SKELETON_FILES=$8
GIT_EMAIL=$9
GIT_NAME=${10}
PROJECT_EXISTS=${11}

echo "=== Starting setup for $APP_NAME ==="
echo "Project exists: $PROJECT_EXISTS"

if [ "$PROJECT_EXISTS" = "true" ]; then
  echo "=== Project $APP_NAME already exists, skipping setup ==="
  exit 0
fi

TEMP_DIR=$(mktemp -d)
echo "Created temp dir: $TEMP_DIR"
cd $TEMP_DIR

if [ "$PROJECT_EXISTS" = "true" ]; then
  echo "=== Project exists, cloning existing repo ==="
  REPO_AUTH_URL="https://oauth2:${GITLAB_TOKEN}@gitlab.com/${GITLAB_GROUP}/${APP_NAME}.git"

  if git clone "$REPO_AUTH_URL" "$APP_NAME" 2>/dev/null; then
    echo "✓ Cloned existing repository"
    cd "$APP_NAME"
  else
    echo "⚠ Could not clone, creating fresh project"
    PROJECT_EXISTS="false"
  fi
fi

if [ "$PROJECT_EXISTS" != "true" ]; then
  echo "=== Creating Vite project with React + TypeScript ==="
  npm create vite@latest $APP_NAME -- --template react-ts

  if [ ! -d "$APP_NAME" ]; then
    echo "ERROR: Vite project directory not created!"
    exit 1
  fi

  cd $APP_NAME
  echo "=== Installing base dependencies ==="
  npm install

  echo "=== Initializing Amplify Gen 2 ==="
  printf '\n\n\n\n' | npm create amplify@latest || true
fi

if [ -n "$SKELETON_REPO" ]; then
  echo "=== Fetching skeleton from repository ==="
  cd $TEMP_DIR
  SKELETON_DIR="skeleton_temp"

  SKELETON_AUTH_URL=$(echo $SKELETON_REPO | sed "s|https://|https://oauth2:${GITLAB_TOKEN}@|")

  if git clone $SKELETON_AUTH_URL $SKELETON_DIR 2>/dev/null; then
    echo "=== Overriding files and folders from skeleton ==="

    SKELETON_PROJECT_DIR=$(find $SKELETON_DIR -type d -name "src" -exec dirname {} \; | head -n 1)

    if [ -z "$SKELETON_PROJECT_DIR" ]; then
      echo "WARNING: Could not find src folder in skeleton repo, using root"
      SKELETON_PROJECT_DIR="$SKELETON_DIR"
    fi

    echo "Found skeleton project at: $SKELETON_PROJECT_DIR"

    for folder in $SKELETON_FOLDERS; do
      if [ -d "$SKELETON_PROJECT_DIR/$folder" ]; then
        rm -rf "$TEMP_DIR/$APP_NAME/$folder"
        cp -r "$SKELETON_PROJECT_DIR/$folder" "$TEMP_DIR/$APP_NAME/$folder"
        echo "✓ Copied $folder folder"
      else
        echo "⚠ Skipped $folder (not found in skeleton)"
      fi
    done

    for file in $SKELETON_FILES; do
      if [ -f "$SKELETON_PROJECT_DIR/$file" ]; then
        cp "$SKELETON_PROJECT_DIR/$file" "$TEMP_DIR/$APP_NAME/$file"
        echo "✓ Copied $file"
      else
        echo "⚠ Skipped $file (not found in skeleton)"
      fi
    done

    rm -rf $SKELETON_DIR
    echo "=== Skeleton merged successfully ==="
  else
    echo "⚠ Could not clone skeleton repo, continuing without it"
  fi

  cd $TEMP_DIR/$APP_NAME
fi

cd $TEMP_DIR/$APP_NAME

if [ ! -f "amplify_outputs.json" ]; then
  echo "=== Creating placeholder amplify_outputs.json ==="
  cat > amplify_outputs.json << 'EOF'
{
  "version": "1.0",
  "auth": {
    "aws_region": "eu-west-1",
    "user_pool_id": "PLACEHOLDER",
    "user_pool_client_id": "PLACEHOLDER"
  }
}
EOF
  echo "✓ Created placeholder amplify_outputs.json"
fi

if [ -n "$EXTRA_DEPS" ]; then
  echo "=== Installing extra dependencies ==="
  npm install $EXTRA_DEPS
  echo "✓ Installed: $EXTRA_DEPS"
fi

if [ -n "$EXTRA_DEV_DEPS" ]; then
  echo "=== Installing extra dev dependencies ==="
  npm install --save-dev $EXTRA_DEV_DEPS
  echo "✓ Installed dev: $EXTRA_DEV_DEPS"
fi

echo "=== Configuring git ==="
git config --global user.email "$GIT_EMAIL"
git config --global user.name "$GIT_NAME"

if [ ! -d ".git" ]; then
  echo "=== Initializing git repository ==="
  git init
fi

if [ -f "amplify_outputs.json" ]; then
  git add -f amplify_outputs.json
  echo "✓ Force-added amplify_outputs.json"
fi

git add .

if git diff --staged --quiet; then
  echo "=== No changes to commit ==="
else
  git commit -m "Update: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "✓ Changes committed"
fi

git branch -M main

echo "=== Pushing to GitLab ==="
git remote remove origin 2>/dev/null || true
git remote add origin "https://oauth2:${GITLAB_TOKEN}@gitlab.com/${GITLAB_GROUP}/${APP_NAME}.git"
git push -u origin main --force > /dev/null 2>&1

echo "=== Success! Cleaning up ==="
cd /
rm -rf $TEMP_DIR
echo "=== Setup complete ==="