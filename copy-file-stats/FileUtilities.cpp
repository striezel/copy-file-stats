/*
 -------------------------------------------------------------------------------
    This file is part of an utility to copy file permissions + ownership.
    Copyright (C) 2014  Dirk Stolle

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 -------------------------------------------------------------------------------
*/

#include "FileUtilities.h"
#include <iostream>
#include <cerrno>
#include <cstring>
#include <sstream>
#include <sys/stat.h>
#include <pwd.h>
#include <grp.h>
#include <unistd.h>

#if defined(_WIN32)
  //Windows includes go here
  #include <io.h>
#elif defined(__linux__) || defined(linux)
  //Linux directory entries
  #include <dirent.h>
#else
  #error "Unknown operating system!"
#endif

FileEntry::FileEntry()
: fileName(""), isDirectory(false)
{ }

std::vector<FileEntry> getDirectoryFileList(const std::string& Directory)
{
  std::vector<FileEntry> result;
  FileEntry one;
  #if defined(_WIN32)
  //Windows part
  intptr_t handle;
  struct _finddata_t sr;
  sr.attrib = _A_NORMAL | _A_RDONLY | _A_HIDDEN | _A_SYSTEM | _A_VOLID |
              _A_SUBDIR | _A_ARCH;
  handle = _findfirst(std::string(Directory+"*").c_str(),&sr);
  if (handle == -1)
  {
    std::cout << "getDirectoryFileList: ERROR: unable to open directory "
              <<"\""<<Directory<<"\". Returning empty list.\n";
    return result;
  }
  //search it
  while( _findnext(handle, &sr)==0)
  {
    one.fileName = std::string(sr.name);
    one.isDirectory = ((sr.attrib & _A_SUBDIR)==_A_SUBDIR);
    result.push_back(one);
  }//while
  _findclose(handle);
  #elif defined(__linux__) || defined(linux)
  //Linux part
  DIR * direc = opendir(Directory.c_str());
  if (direc == NULL)
  {
    std::cout << "getDirectoryFileList: ERROR: unable to open directory "
              <<"\""<<Directory<<"\". Returning empty list.\n";
    return result;
  }//if

  struct dirent* entry = readdir(direc);
  while (entry != NULL)
  {
    one.fileName = std::string(entry->d_name);
    one.isDirectory = entry->d_type==DT_DIR;
    //check for socket, pipes, block device and char device, which we don't want
    if (entry->d_type != DT_SOCK && entry->d_type != DT_FIFO && entry->d_type != DT_BLK
        && entry->d_type != DT_CHR)
    {
      result.push_back(one);
    }
    entry = readdir(direc);
  }//while
  closedir(direc);
  #else
    #error "Unknown operating system!"
  #endif
  return result;
}//function

std::string slashify(const std::string& path)
{
  if (path.empty()) return path;
  //Does it have a trailing (back)slash?
  if (path[path.length()-1]!=pathDelimiter)
  {
    return path + pathDelimiter;
  }
  return path;
}

std::string uintToString(const unsigned int value)
{
  std::ostringstream s_str;
  s_str << value;
  return s_str.str();
}

std::string getHumanReadableOwnership(const struct stat& statbuf)
{
  std::string result = "";
  struct passwd *pwd = getpwuid(statbuf.st_uid);
  if (NULL!=pwd)
    result = std::string(pwd->pw_name);
  else
    result = uintToString(statbuf.st_uid);
  result = result + ":";

  struct group * grp = getgrgid(statbuf.st_gid);
  if (NULL!=grp)
    result = result + std::string(grp->gr_name);
  else
    result = result + uintToString(statbuf.st_gid);
  return result;
}

bool copy_file_stats(const std::string& src_path, const std::string& dest_path, const bool permissions, const bool ownership, const bool verbose)
{
  if (!(permissions or ownership))
  {
    std::cout << "Hint: No stats for change!\n";
    return true;
  }
  struct stat src_statbuf;
  int ret = lstat(src_path.c_str(), &src_statbuf);
  if (0!=ret)
  {
    int errorCode = errno;
    std::cout << "Error while querying status of \"" << src_path << "\": Code " << errorCode << " (" << strerror(errorCode) << ").\n";
    return false;
  }
  struct stat dest_statbuf;
  ret = lstat(dest_path.c_str(), &dest_statbuf);
  if (ENOENT==ret)
  {
    //destination file does not exist, skip silently
    return true;
  }
  if (0!=ret)
  {
    int errorCode = errno;
    std::cout << "Error while querying status of \"" << dest_path << "\": Code " << errorCode << " (" << strerror(errorCode) << ").\n";
    return false;
  }
  //check for equivalence
  if ((dest_statbuf.st_dev == src_statbuf.st_dev) and (dest_statbuf.st_ino==src_statbuf.st_ino))
  {
    std::cout << "Error: " << src_path << " and " << dest_path << " are the same file!\n";
    return false;
  }

  // mode change allowed?
  if (permissions)
  {
    //check for required permission change
    if (dest_statbuf.st_mode != src_statbuf.st_mode)
    {
      if (verbose)
        std::cout << "Changing mode of " << dest_path << " from " << std::oct << dest_statbuf.st_mode <<  " to " << std::oct << src_statbuf.st_mode << std::dec <<"...\n";
      ret = chmod(dest_path.c_str(), src_statbuf.st_mode);
      if (0!=ret)
      {
        int errorCode = errno;
        std::cout << "Error while changing mode of \"" << dest_path << "\": Code " << errorCode << " (" << strerror(errorCode) << ").\n";
        return false;
      }
    }
  }// if permissions

  // ownership change allowed?
  if (ownership)
  {
    //change needed?
    if ((dest_statbuf.st_uid!=src_statbuf.st_uid) or (dest_statbuf.st_gid!=src_statbuf.st_gid))
    {
      if (verbose)
        std::cout << "Changing ownership of \"" << dest_path << "\" from " << getHumanReadableOwnership(dest_statbuf) << " to " << getHumanReadableOwnership(src_statbuf) << "...\n";
      ret = chown(dest_path.c_str(), src_statbuf.st_uid, src_statbuf.st_gid);
      if (0!=ret)
      {
        int errorCode = errno;
        std::cout << "Error while changing ownership of \"" << dest_path << "\": Code " << errorCode << " (" << strerror(errorCode) << ").\n";
        return false;
      }
    }
  }//if ownership
  return true;
}

bool copy_stats_recursive(const std::string& src_dir, const std::string& dest_dir, const bool permissions, const bool ownership, const bool verbose)
{
  const std::vector<FileEntry> files = getDirectoryFileList(src_dir);
  unsigned int i;
  for (i=0; i<files.size(); ++i)
  {
    if ((files[i].fileName!="..") and (files[i].fileName!="."))
    {
      //handle file/dir itself
      if (!copy_file_stats(src_dir+pathDelimiter+files[i].fileName, dest_dir+pathDelimiter+files[i].fileName, permissions, ownership, verbose))
      {
        return false;
      }
      //handle directory content, if it's a directory
      if (files[i].isDirectory)
      {
        if (!copy_stats_recursive(src_dir+pathDelimiter+files[i].fileName, dest_dir+pathDelimiter+files[i].fileName, permissions, ownership, verbose))
        {
          return false;
        }
      }
    }//if not dot or dot+dot
  }//for
  return true;
}
