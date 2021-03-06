#!/bin/bash
# 
# Download an patch the nRF5 SDK to compile the connectivity application.
# Run this script from the `hex` folder. Download and install the SDK in a tmp folder.
#
# Adapted from 'https://github.com/NordicSemiconductor/nrf5-sdk-for-eddystone'.
# Version 0.2

# SDK download link (as zip file, full URL with extension)
SDK_LINK='https://developer.nordicsemi.com/nRF5_SDK/nRF5_SDK_v11.x.x/nRF5_SDK_11.0.0_89a8197.zip'

# Configuration of the destination folder (no trailing slash)
DL_LOCATION=../tmp

SDK_FILE=${SDK_LINK##*/}  # SDK file name with extension
SDK_NAME=${SDK_FILE%.zip} # SDK folder name without extension

# Display a fatal error and exit
function fatal () {
    printf "\e[1;31m[ERROR] $1\r\n[ERROR] Press Enter to exit...\e[0;0m"
    read
    exit 1
}

# Check if the required program are available
function check_requirements () {
    command -v unzip >/dev/null 2>&1 || { fatal "Unzip is not available"; }
    command -v curl >/dev/null 2>&1 || { fatal "Curl is not available"; }
    command -v git >/dev/null 2>&1 || { fatal "Git is not available"; }
    command -v patch >/dev/null 2>&1 || { fatal "Patch is not available"; }
}

# Check if the SDK folder already exist
function sdk_exists () {
    if [[ -d $DL_LOCATION && -d $DL_LOCATION/$SDK_NAME ]]; then
        # Erase the existing SDK folder if needed
        echo "> SDK folder already available"
        read -p "> Do you want to erase the existing SDK folder [Y/n]? " -n 1 -r
        echo ""

        if [[ $REPLY =~ ^[Y]$ ]]; then
            echo "> Deleting existing SDK folder..."
            rm -rf $DL_LOCATION/$SDK_NAME
        else
            return 0 # Exists
        fi
    fi

    # No SDK folder available
    return 1
}

# Patch the downloaded SDK in order to compile the connectivity application
function sdk_patch () {
    echo "> Applying patch..."

    # Apply the patch from the base nRF SDK folder (remove the first portion of the path)
    # FIXME: check if the patch has been already applied
    local C_DIR=$(pwd)
    patch -d $DL_LOCATION/$SDK_NAME/ -p1 -s --ignore-whitespace -i $C_DIR/SD20_SDK11.patch

    err_code=$?
    if [ "$err_code" != "0" ]; then
        # The patch has been probably already applied
        fatal "> Patch does not apply"
    fi
}

# Download and patch the SDK. Check if it is already available
function sdk_download () {
    # First check if the SDK already exist
    if sdk_exists $1; then
        # SDK folder already available (assume patched)
        echo "> Nothing to do"
        return 0
    fi

    if [[ -z "${SDK_NAME}" ]]; then
        fatal "Invalid SDK link"
    fi

    # Create the destination folder and download the SDK
    echo "> Downloading nRF SDK..."

    mkdir -p $DL_LOCATION

    curl --progress-bar -o $DL_LOCATION/$SDK_FILE $SDK_LINK

    err_code=$?
    if [ "$err_code" != "0" ]; then
        fatal "Could not download SDK from '${SDK_LINK}'"
    fi

    echo "> Unzipping SDK..."
    unzip -q $DL_LOCATION/$SDK_FILE -d $DL_LOCATION/$SDK_NAME

    err_code=$?
    if [ "$err_code" != "0" ]; then
        fatal "Could not unzip the SDK file"
    fi

    echo "> Clean up. Removing SDK zip file..."
    rm $DL_LOCATION/$SDK_FILE

    err_code=$?
    if [ "$err_code" != "0" ]; then
        fatal "Could not remove the SDK zip file"
    fi

    # Apply the connectivity patch
    sdk_patch

    # FIXME: unused files from the modified SDK should be deleted
    # Keep only the components and the connectivity application ?
}

clear
printf "Starting SDK bootstrap script\r\n\r\n"

check_requirements
sdk_download

echo "> SDK ready to use. Exit."

exit 0
