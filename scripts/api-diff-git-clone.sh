#!/bin/bash

FOLDER_NAME=swift-sdk-$1

pushd ../..; \
rm -Rf $FOLDER_NAME; \
git clone https://github.com/Kinvey/swift-sdk.git $FOLDER_NAME; \
popd; \
pushd ../../$FOLDER_NAME; \
git checkout $1; \
popd
