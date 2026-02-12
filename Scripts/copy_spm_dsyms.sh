#!/bin/bash

# Copy dSYM files from Swift Package Manager packages to Archive
# This script ensures that framework dSYMs from SPM dependencies are included in the archive
# which is required for App Store Connect uploads and crash symbolication

echo "📦 Starting SPM dSYM copy script..."

# Check if we're building for archiving
if [ "${CONFIGURATION}" != "Release" ]; then
    echo "⚠️  Skipping dSYM copy - not a Release build"
    exit 0
fi

# Check if dSYM folder exists
if [ -d "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app.dSYM" ]; then
    echo "✓ Product dSYM found at: ${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app.dSYM"
else
    echo "⚠️  Product dSYM not found, skipping SPM dSYM copy"
    exit 0
fi

# Find all framework dSYMs in the build directory
DSYM_COUNT=0
find "${BUILD_DIR}" -name "*.framework.dSYM" -type d | while read -r dsym; do
    framework_name=$(basename "$dsym" .framework.dSYM)
    echo "Found dSYM for framework: $framework_name"
    
    # Copy to archive dSYMs folder if it exists
    if [ ! -z "${DWARF_DSYM_FOLDER_PATH}" ]; then
        if [ -d "${DWARF_DSYM_FOLDER_PATH}" ]; then
            cp -R "$dsym" "${DWARF_DSYM_FOLDER_PATH}/"
            echo "✓ Copied $framework_name.framework.dSYM to ${DWARF_DSYM_FOLDER_PATH}/"
            DSYM_COUNT=$((DSYM_COUNT + 1))
        else
            echo "⚠️  DWARF_DSYM_FOLDER_PATH does not exist: ${DWARF_DSYM_FOLDER_PATH}"
        fi
    else
        echo "⚠️  DWARF_DSYM_FOLDER_PATH is not set"
    fi
done

echo "✅ SPM dSYM copy completed"
