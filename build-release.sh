#!/usr/bin/env bash
set -euo pipefail

VERSION="1.1.1"
PROJECT_NAME="download-organizer"

echo "🔨 Building release v${VERSION}..."

# Build for both architectures
echo "Building for Apple Silicon (arm64)..."
swift build -c release --arch arm64

echo "Building for Intel (x86_64)..."
swift build -c release --arch x86_64

# Create universal binary
echo "Creating universal binary..."
lipo -create \
  .build/arm64-apple-macosx/release/download-organizer \
  .build/x86_64-apple-macosx/release/download-organizer \
  -output .build/release/download-organizer-universal

# Create release directory
mkdir -p releases/v${VERSION}

# Package binary with scripts
echo "Packaging..."
tar -czf releases/v${VERSION}/${PROJECT_NAME}-${VERSION}.tar.gz \
  -C .build/release download-organizer-universal \
  --transform "s/download-organizer-universal/download-organizer/" \
  && tar -rf releases/v${VERSION}/${PROJECT_NAME}-${VERSION}.tar.gz \
  install.sh uninstall.sh restart.sh scripts/

# Calculate SHA256
echo "Calculating SHA256..."
shasum -a 256 releases/v${VERSION}/${PROJECT_NAME}-${VERSION}.tar.gz

echo "✅ Release package created!"
echo "📦 releases/v${VERSION}/${PROJECT_NAME}-${VERSION}.tar.gz"
echo ""
echo "Next steps:"
echo "1. Create GitHub release with tag v${VERSION}"
echo "2. Upload the .tar.gz file"
echo "3. Update Homebrew formula with new SHA256"