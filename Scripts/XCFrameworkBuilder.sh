#!/bin/sh

#
#  The MIT License
#
#  Copyright (c) 2014- High-Mobility GmbH (https://high-mobility.com)
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#  THE SOFTWARE.
#
#
#  XCodeFrameworkBuilder.sh
#
#  Created by Mikk Rätsep on 12/09/2019.


######################
# Setup
######################

if [ -z "${SRCROOT}" ]; then
    SRCROOT="$( cd "$(dirname "$0")" ; pwd -P )/.."
fi


NAME=$(ls -1d *.xcodeproj | tail -n 1 | cut -f1 -d ".")

BUILD_DIR="${SRCROOT}/build"
BUILD_DIR_iphoneos="${BUILD_DIR}/iphoneos"
BUILD_DIR_iphonesimulator="${BUILD_DIR}/iphonesimulator"

FINAL_OUTPUT="${SRCROOT}/${NAME}.xcframework"
XCFRAMEWORK_OUTPUT="${BUILD_DIR}/${NAME}.xcframework"

TARGETS=( "iphoneos" "iphonesimulator" )
SYMBOLS_DIR="${SRCROOT}/symbols"


# Remove the "old" build dir
echo "Cleaning previous build products..."
rm -rf $BUILD_DIR
mkdir $BUILD_DIR

# And the symbols dir
rm -rf $SYMBOLS_DIR


######################
# Build
######################

# Archive for iOS
echo "Archiving device..."
xcodebuild archive \
    -project ${NAME}.xcodeproj \
    -scheme ${NAME} \
    -archivePath "${BUILD_DIR_iphoneos}/${NAME}.xcarchive" \
    -derivedDataPath "${BUILD_DIR_iphoneos}/Derived Data" \
    -sdk iphoneos \
    -destination "generic/platform=iOS" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
    -quiet

# Archive for simulator
echo "Archiving simulator..."
xcodebuild archive \
    -project ${NAME}.xcodeproj \
    -scheme ${NAME} \
    -archivePath "${BUILD_DIR_iphonesimulator}/${NAME}.xcarchive" \
    -derivedDataPath "${BUILD_DIR_iphonesimulator}/Derived Data" \
    -sdk iphonesimulator \
    -destination "generic/platform=iOS Simulator" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
    -quiet

# Build xcframework with two archives
echo "Creating XCFramework..."
xcodebuild -create-xcframework \
    -framework "${BUILD_DIR_iphoneos}/${NAME}.xcarchive/Products/Library/Frameworks/${NAME}.framework" \
    -framework "${BUILD_DIR_iphonesimulator}/${NAME}.xcarchive/Products/Library/Frameworks/${NAME}.framework" \
    -output ${XCFRAMEWORK_OUTPUT}


######################
# Move the product
######################

# Copy the Universal to the root dir
echo "Copying XCFramework..."
rm -rf "${FINAL_OUTPUT}"
cp -f -R "${XCFRAMEWORK_OUTPUT}" "${FINAL_OUTPUT}"


######################
# Hold on to files
######################

echo "Copying dSYM files..."
mkdir $SYMBOLS_DIR

for target in "${TARGETS[@]}"
do
    mkdir "${SYMBOLS_DIR}/${target}"

    cp -f -R "${BUILD_DIR}/${target}/Derived Data/Build/Intermediates.noindex/ArchiveIntermediates/${NAME}/BuildProductsPath/Release-${target}/${NAME}.framework.dSYM" "${SYMBOLS_DIR}/${target}/${NAME}.framework.dSYM"
done


######################
# Cleanup
######################

# Removes the "build/" folder from the source folder
echo "Removing build directory..."
rm -rfd "${SRCROOT}/build"
