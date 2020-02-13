# Cython declarations of worked-around alure base classes
# Copyright (C) 2020  Nguyễn Gia Phong
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

from libcpp.string cimport string

from alure cimport Device, Source, MessageHandler


# GIL is needed for operations with Python objects.
cdef extern from 'bases.h' namespace 'palace':
    cdef cppclass BaseMessageHandler(MessageHandler):
        void device_disconnected(Device)
        void source_stopped(Source)
        void source_force_stopped(Source)
        string resource_not_found(string)
