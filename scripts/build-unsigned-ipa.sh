#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ios_root="$project_root/ios/Potter8"
output_root="$project_root/dist"
output_ipa="$output_root/Potter-8.0-unsigned.ipa"
temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/potter8-build.XXXXXX")"

cleanup() {
  rm -rf "$temporary_root"
}
trap cleanup EXIT

command -v xcodebuild >/dev/null 2>&1 || {
  echo "error: xcodebuild is required. Run this script on macOS with Xcode installed." >&2
  exit 1
}

command -v xcodegen >/dev/null 2>&1 || {
  echo "error: XcodeGen is required. Install it with: brew install xcodegen" >&2
  exit 1
}

mkdir -p "$output_root"
rm -f "$output_ipa"

(
  cd "$ios_root"
  xcodegen generate
  xcodebuild \
    -project Potter8.xcodeproj \
    -scheme Potter8 \
    -configuration Release \
    -sdk iphoneos \
    -destination 'generic/platform=iOS' \
    -derivedDataPath "$temporary_root/DerivedData" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY='' \
    build
)

products_root="$temporary_root/DerivedData/Build/Products/Release-iphoneos"
app_bundle="$(find "$products_root" -maxdepth 1 -type d -name '*.app' -print -quit)"

if [[ -z "$app_bundle" ]]; then
  echo "error: Xcode completed without producing an iOS app bundle." >&2
  exit 1
fi

mkdir -p "$temporary_root/Payload"
ditto "$app_bundle" "$temporary_root/Payload/$(basename "$app_bundle")"
(
  cd "$temporary_root"
  /usr/bin/zip -qry "$output_ipa" Payload
)

test -s "$output_ipa"
/usr/bin/unzip -tq "$output_ipa"
echo "Created: $output_ipa"
echo "This IPA is unsigned. Sign it with your own Apple Account before installing it."

