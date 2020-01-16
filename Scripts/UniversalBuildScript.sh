#!/bin/sh

#
# Copyright (C) 2018 High-Mobility GmbH
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see http:#www.gnu.org/licenses/.
#
# Please inquire about commercial licensing options at
# licensing@high-mobility.com
#
#  UniversalBuildScript.sh
#
#  Created by Mikk Rätsep on 16/03/2018.
#  Copyright © 2018 High-Mobility. All rights reserved.


######################
# Conf Some Vars
######################


if [ -z "${CONFIGURATION}" ]; then
    CONFIGURATION="Release"
fi

if [ -z "${SRCROOT}" ]; then
    SRCROOT="$( cd "$(dirname "$0")" ; pwd -P )/.."
fi

if [ -z "${BUILD_DIR}" ]; then
    BUILD_DIR="${SRCROOT}/build"
fi


######################
# Options
######################

FRAMEWORK_NAME="$(find ${SRCROOT} -name '*.xcodeproj')"
FRAMEWORK_NAME=${FRAMEWORK_NAME##*/}
FRAMEWORK_NAME=${FRAMEWORK_NAME%.*}

PROJECT_PATH="${SRCROOT}/${FRAMEWORK_NAME}.xcodeproj"

SIMULATOR_PATH="${BUILD_DIR}/${CONFIGURATION}-simulator"
SIMULATOR_LIBRARY_PATH="${SIMULATOR_PATH}/${FRAMEWORK_NAME}.framework"

DEVICE_PATH="${BUILD_DIR}/${CONFIGURATION}-device"
DEVICE_LIBRARY_PATH="${DEVICE_PATH}/${FRAMEWORK_NAME}.framework"

ARCHIVE_PATH="${DEVICE_PATH}/${FRAMEWORK_NAME}.xcarchive"

UNIVERSAL_LIBRARY_DIR="${BUILD_DIR}/${CONFIGURATION}-iosUniversal"

FRAMEWORK="${UNIVERSAL_LIBRARY_DIR}/${FRAMEWORK_NAME}.framework"


######################
# Build Frameworks
######################

echo "Building for Simulator..."
xcodebuild -quiet -project ${PROJECT_PATH} -target ${FRAMEWORK_NAME} -sdk iphonesimulator -configuration ${CONFIGURATION} CONFIGURATION_BUILD_DIR=${SIMULATOR_PATH} OTHER_CFLAGS="-fembed-bitcode" ONLY_ACTIVE_ARCH=NO clean build

echo "Archiving for Device..."
xcodebuild -quiet -project ${PROJECT_PATH} -scheme ${FRAMEWORK_NAME} -sdk iphoneos -configuration ${CONFIGURATION} OTHER_CFLAGS="-fembed-bitcode" -archivePath ${ARCHIVE_PATH} clean archive

# Updates the device's library path
DEVICE_LIBRARY_PATH="${ARCHIVE_PATH}/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework"


######################
# Create directory for universal
######################

echo "Removing and making directories..."
rm -rf ${UNIVERSAL_LIBRARY_DIR}

mkdir ${UNIVERSAL_LIBRARY_DIR}
mkdir ${FRAMEWORK}


######################
# Copy files Framework
######################

echo "Copying frameworks..."
cp -r "${DEVICE_LIBRARY_PATH}/." "${FRAMEWORK}"

# And the AppStoreCompatible script
echo "Copying AppStoreCompatible script"
cp "${SRCROOT}/Scripts/AppStoreCompatible.sh" "${FRAMEWORK}"


######################
# Make an universal binary
######################

echo "Combining frameworks together..."
lipo "${SIMULATOR_LIBRARY_PATH}/${FRAMEWORK_NAME}" "${DEVICE_LIBRARY_PATH}/${FRAMEWORK_NAME}" -create -output "${FRAMEWORK}/${FRAMEWORK_NAME}"

# For Swift framework, Swiftmodule needs to be copied in the universal framework
if [ -d "${DEVICE_LIBRARY_PATH}/Modules/${FRAMEWORK_NAME}.swiftmodule/" ]; then
cp -f -R "${DEVICE_LIBRARY_PATH}/Modules/${FRAMEWORK_NAME}.swiftmodule/" "${FRAMEWORK}/Modules/${FRAMEWORK_NAME}.swiftmodule/"
fi

if [ -d "${SIMULATOR_LIBRARY_PATH}/Modules/${FRAMEWORK_NAME}.swiftmodule/" ]; then
cp -f -R "${SIMULATOR_LIBRARY_PATH}/Modules/${FRAMEWORK_NAME}.swiftmodule/" "${FRAMEWORK}/Modules/${FRAMEWORK_NAME}.swiftmodule/"
fi


######################
# Cleanup
######################

# Copy the Universal to the root dir
cp -f -R "${FRAMEWORK}" "${SRCROOT}"

# Removes the build/ folder from the source folder
echo "Removing build directory..."
rm -rfd "${SRCROOT}/build"
