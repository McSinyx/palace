# Cython declarations of some missing C++ standard libraries
# Copyright (C) 2019, 2020  Nguyễn Gia Phong
# Copyright (C) 2020  Ngô Ngọc Đức Huy
#
# This file is part of palace.
#
# palace is free software: you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published
# by the Free Software Foundation, either version 3 of the License,
# or (at your option) any later version.
#
# palace is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with palace.  If not, see <https://www.gnu.org/licenses/>.

from libc.stdint cimport int64_t
from libcpp cimport bool as boolean


cdef extern from '<chrono>' namespace 'std::chrono' nogil:
    cdef cppclass duration[Rep, Period=*]:
        ctypedef Rep rep
        duration() except +
        duration(const rep&) except +   # ugly hack, see cython/cython#3198
        rep count() except +

    ctypedef duration[int64_t, nano] nanoseconds
    ctypedef duration[int64_t, milli] milliseconds


cdef extern from '<iostream>' namespace 'std' nogil:
    cdef cppclass istream:
        istream(streambuf*) except +


cdef extern from '<future>' namespace 'std' nogil:
    cdef cppclass shared_future[R]:
        R& get() except +
        boolean valid() const


cdef extern from '<ratio>' namespace 'std' nogil:
    cdef cppclass nano:
        pass
    cdef cppclass milli:
        pass


cdef extern from '<streambuf>' namespace 'std' nogil:
    cdef cppclass streambuf:
        void setg(char*, char*, char*) except +
