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
  echo "Error: Expecting one parameter - executable for stat_file_test!"
  return 1
fi

# create base directory where the test shall take place
BASE_DIR=`mktemp --directory --tmpdir testSaveRestoreXXXXXXXXXX`

# get default user name and group
USER_NAME=`id -un`
USER_ID=`id -u`
GROUP_NAME=`id -gn`
GROUP_ID=`id -g`

# create some files
touch $BASE_DIR/alpha
chmod 0755 $BASE_DIR/alpha || echo "chmod failed (alpha)"

touch $BASE_DIR/beta
chmod 0644 $BASE_DIR/beta || echo "chmod failed (beta)"

touch $BASE_DIR/gamma
chmod 0640 $BASE_DIR/gamma || echo "chmod failed (gamma)"

touch $BASE_DIR/delta
chmod 0600 $BASE_DIR/delta || echo "chmod failed (delta)"

# -- create subdirectory
mkdir $BASE_DIR/sub

if [[ $? -ne 0 ]]
then
  echo "Failed to create subdirectory!"
  exit 1
fi

chmod 0777 $BASE_DIR/sub

# -- create some files in subdirectory
touch $BASE_DIR/sub/epsilon
chmod 0124 $BASE_DIR/sub/epsilon || echo "chmod failed (epsilon)"

touch $BASE_DIR/sub/riemann
chmod 0654 $BASE_DIR/sub/riemann || echo "chmod failed (riemann)"

touch $BASE_DIR/sub/zeta
chmod 0432 $BASE_DIR/sub/zeta || echo "chmod failed (zeta)"


if [[ $? -ne 0 ]]
then
  echo "Failed to create test files!"
  exit 1
fi

echo "Files created successfully in $BASE_DIR!"

# name for stat file
STAT_FILE=`mktemp --dry-run --tmpdir=/tmp statfileXXXXXXXX`
# ... and file from template against which it will be compared
COMPARE_STAT_FILE=`mktemp --dry-run --tmpdir=/tmp statfile_compareXXXXXXXX`

# run test
$1 $BASE_DIR $STAT_FILE
# ...and save its exit code
TEST_EXIT_CODE=$?

SCRIPT_DIR=`dirname $0`

if [[ $TEST_EXIT_CODE -eq 0 ]]
then
  # replace placeholders in template statfile.tpl with actual values
  sed "s/USER_NAME/$USER_NAME/g" $SCRIPT_DIR/statfile.tpl | sed "s/USER_ID/$USER_ID/g" | \
  sed "s/GROUP_NAME/$GROUP_NAME/g" | sed "s/GROUP_ID/$GROUP_ID/g" > $COMPARE_STAT_FILE
  # compare both files with diff
  diff $STAT_FILE $COMPARE_STAT_FILE
  # files are identical, if return code of diff is zero
  DIFF_EXIT_CODE=$?
  if [[ $DIFF_EXIT_CODE -ne 0 ]]
  then
    echo "Error: Files are NOT identical."
    echo "Generated file:"
    cat $STAT_FILE
    echo "Template-based file:"
    cat $COMPARE_STAT_FILE
    echo "---- end of files ---"
  fi
else
  echo "Executable returned non-zero exit code ($TEST_EXIT_CODE)."
  DIFF_EXIT_CODE=2
fi

# clean up
# -- test directory
rm -rf $BASE_DIR
# -- stat file
if [[ -f $STAT_FILE ]]
then
  rm -f $STAT_FILE
fi
# -- stat file generated from template
if [[ -f $COMPARE_STAT_FILE ]]
then
  rm -f $COMPARE_STAT_FILE
fi

if [[ $TEST_EXIT_CODE -eq 0 && $DIFF_EXIT_CODE -eq 0 ]]
then
  exit 0
else
  exit 1
fi
