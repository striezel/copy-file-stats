/*
 -------------------------------------------------------------------------------
    This file is part of an utility to copy file permissions + ownership.
    Copyright (C) 2015  Dirk Stolle

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

#ifndef MODEUTILITY_HPP
#define MODEUTILITY_HPP

#include <sys/stat.h>

class Mode
{
  public:
    static const mode_t cPermissionBitmask; /**< bitmask that includes all mode bits */


    /** \brief removes all bits from the given mode that do not have to do with permissions
     *
     * \param m  the mode_t variable
     * \return Returns @m with all non-permission bits set to zero.
     */
    static mode_t onlyPermissions(const mode_t m);
}; //class

#endif // MODEUTILITY_HPP
