#!/bin/sh
# Expects: WORK_DIR, APP_NAME, EXTRA_DEPS, EXTRA_DEV_DEPS

cd "$WORK_DIR"
npm create vite@latest "$APP_NAME" -- --template react-ts
cd "$APP_NAME"

npm install
printf '\n\n\n\n' | npm create amplify@latest

[ -n "$EXTRA_DEPS" ] && npm install $EXTRA_DEPS
[ -n "$EXTRA_DEV_DEPS" ] && npm install --save-dev $EXTRA_DEV_DEPS