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

echo "=== Starting setup for $APP_NAME ==="

# Create temp directory
TEMP_DIR=$(mktemp -d)
echo "Created temp dir: $TEMP_DIR"
cd $TEMP_DIR

# Create Vite project with React + TypeScript
echo "=== Creating Vite project with React + TypeScript ==="
npm create vite@latest $APP_NAME -- --template react-ts

if [ ! -d "$APP_NAME" ]; then
  echo "ERROR: Vite project directory not created!"
  exit 1
fi

cd $APP_NAME
echo "=== Installing base dependencies ==="
npm install

# Initialize Amplify Gen 2 with auto-answers
echo "=== Initializing Amplify Gen 2 ==="
printf '\n\n\n\n' | npm create amplify@latest || true

# Override with skeleton if provided
if [ -n "$SKELETON_REPO" ]; then
  echo "=== Fetching skeleton from repository ==="
  cd ..
  SKELETON_DIR="skeleton_temp"

  # Clone with authentication using token
  SKELETON_AUTH_URL=$(echo $SKELETON_REPO | sed "s|https://|https://oauth2:${GITLAB_TOKEN}@|")
  git clone $SKELETON_AUTH_URL $SKELETON_DIR

  echo "=== Overriding files and folders from skeleton ==="

  # Find the actual project folder (handles nested structure)
  SKELETON_PROJECT_DIR=$(find $SKELETON_DIR -type d -name "src" -exec dirname {} \; | head -n 1)

  if [ -z "$SKELETON_PROJECT_DIR" ]; then
    echo "ERROR: Could not find src folder in skeleton repo"
    exit 1
  fi

  echo "Found skeleton project at: $SKELETON_PROJECT_DIR"

  # Copy folders (from variable)
  for folder in $SKELETON_FOLDERS; do
    if [ -d "$SKELETON_PROJECT_DIR/$folder" ]; then
      rm -rf "$APP_NAME/$folder"
      cp -r "$SKELETON_PROJECT_DIR/$folder" "$APP_NAME/$folder"
      echo "✓ Copied $folder folder"
    else
      echo "⚠ Skipped $folder (not found in skeleton)"
    fi
  done

  # Copy files (from variable)
  for file in $SKELETON_FILES; do
    if [ -f "$SKELETON_PROJECT_DIR/$file" ]; then
      cp "$SKELETON_PROJECT_DIR/$file" "$APP_NAME/$file"
      echo "✓ Copied $file"
    else
      echo "⚠ Skipped $file (not found in skeleton)"
    fi
  done

  # Cleanup skeleton
  rm -rf $SKELETON_DIR

  cd $APP_NAME

  # Create placeholder amplify_outputs.json if it doesn't exist
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

  echo "=== Skeleton merged successfully ==="
fi

# Install extra dependencies (latest versions)
if [ -n "$EXTRA_DEPS" ]; then
  echo "=== Installing extra dependencies ==="
  npm install $EXTRA_DEPS
  echo "✓ Installed: $EXTRA_DEPS"
fi

# Install extra dev dependencies (latest versions)
if [ -n "$EXTRA_DEV_DEPS" ]; then
  echo "=== Installing extra dev dependencies ==="
  npm install --save-dev $EXTRA_DEV_DEPS
  echo "✓ Installed dev: $EXTRA_DEV_DEPS"
fi

echo "=== Configuring git ==="
git config --global user.email "$GIT_EMAIL"
git config --global user.name "$GIT_NAME"

echo "=== Initializing git repository ==="
git init

# Force add amplify_outputs.json even if gitignored
if [ -f "amplify_outputs.json" ]; then
  git add -f amplify_outputs.json
  echo "✓ Force-added amplify_outputs.json (was in .gitignore)"
fi

git add .
git commit -m "Initial commit with Vite + Amplify Gen 2"
git branch -M main

# Push using token
echo "=== Pushing to GitLab ==="
git remote add origin https://oauth2:${GITLAB_TOKEN}@gitlab.com/${GITLAB_GROUP}/${APP_NAME}.git > /dev/null 2>&1
git push -u origin main > /dev/null 2>&1

echo "=== Success! Cleaning up ==="
cd ../..
rm -rf $TEMP_DIR
echo "=== Setup complete ==="