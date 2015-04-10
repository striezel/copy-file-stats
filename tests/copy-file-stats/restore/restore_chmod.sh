#!/bin/bash

# This file is part of the test suite for copy-file-stats.
# Copyright (C) 2015  Dirk Stolle
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# check parameter
if [[ -z $1 ]]
then
  echo "Error: Expecting one parameter - path of executable copy-file-stats!"
  return 1
fi

# create base directory where the test shall take place
BASE_DIR=`mktemp --directory --tmpdir testSaveRestoreXXXXXXXXXX`

# get default user name and group
USER_NAME=`id -un`
USER_ID=`id -u`
GROUP_NAME=`id -gn`
GROUP_ID=`id -g`

ALL_GROUPS=`id -Gn`
echo "Info: User $USER_NAME belongs to the following groups: $ALL_GROUPS."

#include create_directory and create_file functions
source ${BASH_SOURCE%/*}/../../script-includes/creation.sh

# create some files
create_file $BASE_DIR/alpha 0700
create_file $BASE_DIR/beta 0600
create_file $BASE_DIR/gamma 0600
create_file $BASE_DIR/delta 0600

# -- create subdirectory
create_directory $BASE_DIR/sub 0700

# -- create some files in subdirectory
create_file $BASE_DIR/sub/epsilon 0600
create_file $BASE_DIR/sub/riemann 0600
create_file $BASE_DIR/sub/zeta 0600

# -- create directory within subdirectory
create_directory $BASE_DIR/sub/marine 0770

# create some files in .../sub/marine
create_file $BASE_DIR/sub/marine/anachronistic 0700
create_file $BASE_DIR/sub/marine/brontosaurus 0700
create_file $BASE_DIR/sub/marine/catharsis 0700

# -- create another subdirectory
create_directory $BASE_DIR/trivial 0700

if [[ $? -ne 0 ]]
then
  echo "Failed to create test files!"
  exit 1
fi

echo "Files created successfully in $BASE_DIR!"

# name for stat file
OUTPUT_STAT_FILE=`mktemp --dry-run --tmpdir=/tmp statfileXXXXXXXX`
# ... and file from template against which it will be compared
REFERENCE_STAT_FILE=`mktemp --dry-run --tmpdir=/tmp statfile_compareXXXXXXXX`

# replace placeholders in template statfile.tpl with actual values and sort it
SCRIPT_DIR=`dirname $0`
sed "s/USER_NAME/$USER_NAME/g" $SCRIPT_DIR/statfile.tpl | sed "s/USER_ID/$USER_ID/g" | \
sed "s/GROUP_NAME/$GROUP_NAME/g" | sed "s/GROUP_ID/$GROUP_ID/g" | \
LC_ALL=C sort > $REFERENCE_STAT_FILE

# run test
$1 --restore --force $REFERENCE_STAT_FILE $BASE_DIR
# ...and save its exit code
TEST_EXIT_CODE=$?

# save current directory status
$1 --save $BASE_DIR $OUTPUT_STAT_FILE
SAVE_EXIT_CODE=$?

if [[ $TEST_EXIT_CODE -eq 0 && $SAVE_EXIT_CODE -eq 0 ]]
then
  # sort generated stat file
  cat $OUTPUT_STAT_FILE | LC_ALL=C sort > $OUTPUT_STAT_FILE.sort
  # overwrite generated file with sorted version (sort + mv has to be two steps, otherwise file will be empty)
  mv $OUTPUT_STAT_FILE.sort $OUTPUT_STAT_FILE
  # compare both files with diff
  diff $OUTPUT_STAT_FILE $REFERENCE_STAT_FILE
  # files are identical, if return code of diff is zero
  DIFF_EXIT_CODE=$?
  if [[ $DIFF_EXIT_CODE -ne 0 ]]
  then
    echo "Error: Files are NOT identical."
    echo "Generated file:"
    cat $OUTPUT_STAT_FILE
    echo "Template-based file:"
    cat $REFERENCE_STAT_FILE
    echo "---- end of files ---"
    echo ""
    echo "Directory listings:"
    echo "base:"
    ls -la $BASE_DIR
    echo "sub:"
    ls -la $BASE_DIR/sub
    echo "marine:"
    ls -la $BASE_DIR/sub/marine
  else
    echo "Both stat files are identical. :)"
  fi
else
  echo "Executable returned non-zero exit code:"
  echo "-- Test exit code: $TEST_EXIT_CODE"
  echo "-- Save exit code: $SAVE_EXIT_CODE"
  DIFF_EXIT_CODE=2
fi

# clean up
# -- test directory
rm -rf $BASE_DIR
# -- stat file
if [[ -f $OUTPUT_STAT_FILE ]]
then
  rm -f $OUTPUT_STAT_FILE
fi
# -- stat file generated from template
if [[ -f $REFERENCE_STAT_FILE ]]
then
  rm -f $REFERENCE_STAT_FILE
fi

if [[ $TEST_EXIT_CODE -eq 0 && $DIFF_EXIT_CODE -eq 0 ]]
then
  exit 0
else
  exit 1
fi
