#!/bin/sh
# Expects: WORK_DIR, APP_NAME, SKELETON_REPO_URL, GITLAB_TOKEN, SKELETON_FOLDERS, SKELETON_FILES

SKELETON_DIR="$WORK_DIR/skeleton_temp"
PROJECT_DIR="$WORK_DIR/$APP_NAME"

# Clone skeleton
SKELETON_AUTH_URL=$(echo "$SKELETON_REPO_URL" | sed "s|https://|https://oauth2:${GITLAB_TOKEN}@|")
git clone "$SKELETON_AUTH_URL" "$SKELETON_DIR"

# Find skeleton root (where src/ lives)
SKELETON_ROOT=$(find "$SKELETON_DIR" -type d -name "src" -exec dirname {} \; | head -n 1)
[ -z "$SKELETON_ROOT" ] && echo "ERROR: No src/ in skeleton" && exit 1

# Copy folders
for folder in $SKELETON_FOLDERS; do
  [ -d "$SKELETON_ROOT/$folder" ] && rm -rf "$PROJECT_DIR/$folder" && cp -r "$SKELETON_ROOT/$folder" "$PROJECT_DIR/$folder"
done

# Copy files
for file in $SKELETON_FILES; do
  [ -f "$SKELETON_ROOT/$file" ] && cp "$SKELETON_ROOT/$file" "$PROJECT_DIR/$file"
done

rm -rf "$SKELETON_DIR"

# Create placeholder amplify_outputs.json if missing
if [ ! -f "$PROJECT_DIR/amplify_outputs.json" ]; then
  cat > "$PROJECT_DIR/amplify_outputs.json" << 'EOF'
{
  "version": "1.0",
  "auth": { "aws_region": "eu-west-1", "user_pool_id": "PLACEHOLDER", "user_pool_client_id": "PLACEHOLDER" }
}
EOF
fi