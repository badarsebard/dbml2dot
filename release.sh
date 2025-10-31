#!/bin/bash
set -euo pipefail

# Usage: ./release.sh <version_bump> <message>
# Examples:
#   ./release.sh patch "Fix bug in generator"
#   ./release.sh minor "Add new feature"
#   ./release.sh major "Breaking change"
#   ./release.sh 1.0.0 "Release 1.0.0"

version_bump="$1"; shift
message="$*"

if [ -z "$version_bump" ]; then
	echo "Error: Version bump (patch/minor/major/X.Y.Z) must not be empty"
	exit 1
fi
if [ -z "$message" ]; then
	echo "Error: Commit message must not be empty"
	exit 1
fi

# Clean up old builds
rm -rf dist/ build/ ./*.egg-info

# Bump version using uv
if [[ "$version_bump" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
	# Exact version specified
	echo "Setting version to $version_bump"
	uv version "$version_bump"
else
	# Semantic version bump (patch/minor/major)
	echo "Bumping $version_bump version"
	uv version --bump "$version_bump"
fi

# Get the new version from pyproject.toml
new_version=$(grep -m1 'version = ' pyproject.toml | cut -d'"' -f2)
echo "New version: $new_version"

# Sync version to __init__.py (uv version only updates pyproject.toml)
sed -i '' "s/^__version__ = .*/__version__ = \"${new_version}\"/" dbmlviz/__init__.py

# Build with verification
echo "Building package..."
uv build --no-sources

# Verify the build succeeded
if [ ! -f "dist/dbmlviz-${new_version}.tar.gz" ]; then
	echo "Error: Build failed - tarball not found"
	exit 1
fi

# Create signed git tag and push
echo "Creating git tag v${new_version}..."
git add pyproject.toml dbmlviz/__init__.py
git commit -m "Bump version to ${new_version}"
git tag --sign --message "$message" "v${new_version}"
git push origin main
git push --tags

# Publish to PyPI
echo "Publishing to PyPI..."
uv publish

echo "✓ Successfully released version ${new_version}"
