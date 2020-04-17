# Helper functions and mappings
# Copyright (C) 2020  Nguyễn Gia Phong
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

from libcpp.map cimport map
from libcpp.string cimport string
from libcpp.utility cimport pair
from libcpp.vector cimport vector

from alure cimport (    # noqa
    AttributePair, EFXEAXREVERBPROPERTIES, FilterParams,
    ChannelConfig, SampleType, DistanceModel, Vector3)


cdef extern from 'util.h' namespace 'palace' nogil:
    cdef const map[string, EFXEAXREVERBPROPERTIES] REVERB_PRESETS
    cdef const map[string, SampleType] SAMPLE_TYPES
    cdef const map[string, ChannelConfig] CHANNEL_CONFIGS
    cdef const map[string, DistanceModel] DISTANCE_MODELS
    cdef vector[string] reverb_presets()
    cdef vector[AttributePair] mkattrs(vector[pair[int, int]])
    cdef FilterParams make_filter(float gain, float gain_hf, float gain_lf)
    cdef vector[float] from_vector3(Vector3)
    cdef Vector3 to_vector3(vector[float])
