# copy-file-stats

copy-file-stats is a small program to "copy" file stats from one files in one
directory and its subdirectories to another directory and its subdirectories.
The "stats" mean file ownership (both user and group) and/or permissions.
The program works on Linux (or similar POSIX-compatible OS) only, a Windows
port neither exists nor is it planned.

The program expects three parameters: path to the source directory and path of
the destination directory, in that order. Third parameter should be either
`--dry-run` or `--force`, depending on whether you just want to show, what would
be changed or whether you want to perform those changes.

After copy-file-stats is done, files in the destination directory will have the
same owner and permissions as the corresponding files in the source directory.
This basically requires that source and destination directory have more or less
the same file and directory structure. Files that are present in the source
directory but not in the destination directory will not be touched. The same
applies to files that are present in the destination but not in the source
directory.

copy-file-stats also has a save and a restore mode of operation, which is
invoked via the option `--save` and `--restore`, respectively. When invoked with
the `--save` parameter, the second parameter shall not be the source directory,
but the name of a file which shall be created. That file will then be used to
store (or save) the current stats of the source directory. Such a file can
later be used in restore mode. Restore mode is triggered when the program is
invoked with the `--restore` parameter. In restore mode, an existing stat file
is expected instead of a source directory. The stats from that file will then
be applied to the destination directory, that is the previously saved stats
will be restored.
To avoid any confusion the `--save` and `--restore` options are mutually
exclusive.

copy-file-stats is a command-line only program. There is no GUI, because I did
not need a GUI.


## Command line options:

copy-file-stats supports several command line options.

```
copy-file-stats [options] SOURCE_DIR DESTINATION_DIR
copy-file-stats [options] --save SOURCE_DIR STAT_FILE
copy-file-stats [options] --restore STAT_FILE DESTINATION_DIR

  --help           - displays a help message and quits
  -?               - same as --help
  --version        - displays the version of the programme and quits
  -v               - same as --version
  --license, -l    - show license information and quit
  --silent         - produces less output about ongoing changes
  --no-ownership   - do not change file ownership
  --no-chown       - alias for --no-ownership
  --no-permissions - do not change file permissions
  --no-chmod       - alias for --no-permissions
  --dry-run, -n    - only show what would be done, but don't do it
  --simulate, -s   - alias for --dry-run
  --force, -f      - force change of file permissions and/or ownership.
                     Either -f or -n have to be given to run this programme.
                     The only exception is --save, the programme always tries
                     to perform a save, there is no dry run for that.
  --save           - indicates that stats shall just be copied to a file and
                     not be applied to a source directory. Mutually exclusive
                     with --restore.
  --restore        - indicates that stats shall be retrieved from a stat file
                     and not from a source directory.
                     Mutually exclusive with --save.
  SOURCE_DIR       - set source directory (i.e. reference directory) to
                     SOURCE_DIR
  DESTINATION_DIR  - set destination directory to DESTINATION_DIR
  STAT_FILE        - when used with --save name of the file that will be used
                     to save the stats of the source directory.
                     When used with --restore name of the file that will be
                     used to restore stats of the destination directory.
```


## Build copy-file-stats from source

The source repository of copy-file-stats contains a CMakeLists.txt file that
is suitable for use with CMake. CMake version 2.4 or later should be sufficient
to build the program, but it has only been tested with CMake 2.8.
To build the program, just type the following two commands in the directory
that contains the source code:

    cmake ./
    make copy-file-stats

If you prefer an "out of source" build, you can create a build directory and
then do the same, e.g.:

    mkdir ./build
    cd ./build
    cmake ../
    make copy-file-stats

This should do the trick, as long as CMake and a C++ compiler are installed on
your machine. Any recent (and not so recent) C++ compiler should work, because
copy-file-stats itself does NOT use new any language constructs from C++11 or
C++14.


## Test suite

This repository also contains a test suite for copy-file-stats (see directory
tests/). To build this test suite, you can type the following commands in the
directory that contains the source code:

    cmake ./
    make
    ctest

The test suite consists of some shell scripts (written for Bash) and a bit of
C++ code. Unlike the program code, the C++ code in the test suite uses some
features from C++11, so make sure your compiler supports that. g++ 4.7.2 or
later should be enough to compile the test suite (and the program).


## Copyright and license

Copyright 2014-2015 Dirk Stolle

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
