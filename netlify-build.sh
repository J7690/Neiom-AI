#!/usr/bin/env bash
set -e

# Install Flutter SDK in Netlify build image (cached in HOME between builds)
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable "$HOME/flutter"
fi

export PATH="$HOME/flutter/bin:$PATH"

flutter --version
flutter config --enable-web

# Build Flutter web app
cd nexiom_ai_studio
flutter pub get
flutter build web --release
