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
#  AppStoreCompatible.sh
#
#  Created by Mikk Rätsep on 07/03/2017.
#


# This script thins the Universal (library) file
# Also removes the irrelevant .swiftmodule-s by removing the Simulator parts


# How to use AppStoreCompatible.sh script:
#   1) navigate to the .framework folder in terminal
#   2) execute
#       sh AppStoreCompatible.sh




# Make some vars
FILE_COUNT=0


# Ignores the macOS platform - there's no simulator on it...
if [ "${PLATFORM_NAME}" != "macosx" ]; then


# See if this is called from XCode or not
if [ -n "${SCRIPT_INPUT_FILE_COUNT}" ]; then

FILE_COUNT="${SCRIPT_INPUT_FILE_COUNT}"
FRAMEWORK_PATH="${SCRIPT_INPUT_FILE_0}"

else

FILE_COUNT=1
FRAMEWORK_PATH="$(pwd)"

fi



# Check there's an input file
if [ ${FILE_COUNT} -eq 1 ]; then


# Gather some paths
NAME=${FRAMEWORK_PATH##*"/"}
NAME=${NAME%%".framework"}

MODULES_DIR="${FRAMEWORK_PATH}/Modules/${NAME}.swiftmodule"


# Remove the x86_64 slices from the binary and files from the .swiftmodule
if $(lipo ${NAME} -verify_arch x86_64); then

lipo ${NAME} -remove x86_64 -o ${NAME}

fi

# Remove the .swiftmodule files
rm -fr "${MODULES_DIR}/x86_64.swiftdoc"
rm -fr "${MODULES_DIR}/x86_64.swiftmodule"
rm -fr "${MODULES_DIR}/x86_64-apple-ios-simulator.swiftdoc"
rm -fr "${MODULES_DIR}/x86_64-apple-ios-simulator.swiftmodule"

# Remove the script (can't upload to iTunesConnect with it)
rm -- "$0"

fi


fi
