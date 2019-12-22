# cython: binding=True
# Python object wrappers for alure
# Copyright (C) 2019  Nguyễn Gia Phong
#
# This file is part of archaicy.
#
# archaicy is free software: you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published
# by the Free Software Foundation, either version 3 of the License,
# or (at your option) any later version.
#
# archaicy is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with archaicy.  If not, see <https://www.gnu.org/licenses/>.

__doc__ = 'Wrapper for Audio Library Utilities REtooled in Cython'
__all__ = ['ALC_TRUE', 'ALC_HRTF_SOFT', 'ALC_HRTF_ID_SOFT',
           'DeviceManager', 'Device', 'Context', 'Buffer', 'Source', 'Decoder']

from typing import Dict, List, Tuple

from libcpp cimport nullptr
from libcpp.memory cimport shared_ptr
from libcpp.pair cimport pair
from libcpp.vector cimport vector

cimport alure

# Cast to Python objects
ALC_TRUE = alure.ALC_TRUE
ALC_HRTF_SOFT = alure.ALC_HRTF_SOFT
ALC_HRTF_ID_SOFT = alure.ALC_HRTF_ID_SOFT


cdef vector[alure.AttributePair] mkattrs(vector[pair[int, int]] attrs):
    """Convert attribute pairs from Python object to alure format."""
    cdef vector[alure.AttributePair] attributes
    cdef alure.AttributePair pair
    for attribute, value in attrs:
        pair.mAttribute = attribute
        pair.mValue = value
        attributes.push_back(pair)  # insert a copy
    pair.mAttribute = pair.mValue = 0
    attributes.push_back(pair)  # insert a copy
    return attributes


cdef class DeviceManager:
    """Manager of Device objects and other related functionality.
    This class is a singleton, only one instance will exist in a process
    at a time.
    """
    cdef alure.DeviceManager impl

    def __init__(self):
        """Multiple calls will give the same instance as long as
        there is still a pre-existing reference to the instance,
        or else a new instance will be created.
        """
        self.impl = alure.DeviceManager.get_instance()

    def open_playback(self, name: str = None) -> Device:
        """Return the playback device given by name.

        Raise RuntimeError on failure.
        """
        device = Device()
        if name is None:
            device.impl = self.impl.open_playback()
        else:
            device.impl = self.impl.open_playback(name.encode())
        return device


cdef class Device:
    """Playback device."""
    cdef alure.Device impl

    @property
    def basic_name(self) -> str:
        """Basic name of the device."""
        return self.impl.get_name(alure.PlaybackName.Basic).decode()

    @property
    def full_name(self) -> str:
        """Full name of the device."""
        return self.impl.get_name(alure.PlaybackName.Full).decode()

    @property
    def hrtf_names(self) -> List[str]:
        """List of available HRTF names, sorted as OpenAL gives them,
        such that the index of a given name is the ID to use with
        ALC_HRTF_ID_SOFT.

        If the ALC_SOFT_HRTF extension is unavailable,
        this will be an empty list.
        """
        return [name.decode() for name in self.impl.enumerate_hrtf_names()]

    @property
    def hrtf_enabled(self) -> bool:
        """Whether HRTF is enabled on the device.

        If the ALC_SOFT_HRTF extension is unavailable,
        this will return False although there could still be
        HRTF applied at a lower hardware level.
        """
        return self.impl.is_hrtf_enabled()

    @property
    def current_hrtf(self) -> str:
        """Name of the HRTF currently being used by this device.

        If HRTF is not currently enabled, this will be None.
        """
        name = self.impl.get_current_hrtf().decode()
        return name or None

    def create_context(self, attrs: Dict[int, int] = {}) -> Context:
        """Return a newly created Context on this device,
        using the specified attributes.

        Raise RuntimeError on failure.
        """
        context = Context()
        if attrs:
            context.impl = self.impl.create_context(mkattrs(attrs.items()))
        else:
            context.impl = self.impl.create_context()
        return context

    def close(self) -> None:
        """Close and free the device.  All previously-created contexts
        must first be destroyed.
        """
        self.impl.close()


cdef class Context:
    """With statement is supported, for example

    with context:
        ...

    is equivalent to

    Context.make_current(context)
    ...
    Context.make_current()
    context.destroy()
    """
    cdef alure.Context impl

    def __enter__(self):
        Context.make_current(self)
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        Context.make_current()
        self.destroy()

    @staticmethod
    def make_current(context: Context = None) -> None:
        """Make the specified context current for OpenAL operations."""
        if context is None:
            alure.Context.make_current(<alure.Context> nullptr)
        else:
            alure.Context.make_current(context.impl)

    def destroy(self) -> None:
        """Destroy the context.  The context must not be current
        when this is called.
        """
        self.impl.destroy()

    def create_decoder(self, name: str) -> Decoder:
        """Return a Decoder instance for the given audio file
        or resource name.
        """
        decoder = Decoder()
        decoder.pimpl = self.impl.create_decoder(name.encode())
        return decoder

    def get_buffer(self, name: str) -> Buffer:
        """Create and cache a Buffer for the given audio file
        or resource name.  Multiple calls with the same name will
        return the same Buffer object.  Cached buffers must be
        freed using remove_buffer before destroying the context.

        If the buffer can't be loaded RuntimeError will be raised.
        """
        buffer = Buffer()
        buffer.impl = self.impl.get_buffer(name.encode())
        return buffer

    def remove_buffer(self, buffer: Buffer) -> None:
        """Delete the given cached buffer, invalidating all other
        Buffer objects with the same name.
        """
        self.impl.remove_buffer(buffer.impl)

    def create_source(self) -> Source:
        """Return a newly created Source for playing audio.
        There is no practical limit to the number of sources you may create.
        You must call Source.destroy when the source is no longer needed.
        """
        source = Source()
        source.impl = self.impl.create_source()
        return source

    def update(self) -> None:
        """Update the context and all sources belonging to this context."""
        self.impl.update()


cdef class Buffer:
    cdef alure.Buffer impl

    @property
    def length(self) -> int:
        """The length of the buffer in sample frames."""
        return self.impl.get_length()

    @property
    def frequency(self) -> int:
        """The buffer's frequency in hertz."""
        return self.impl.get_frequency()

    @property
    def channel_config_name(self) -> str:
        """The buffer's sample configuration name."""
        return alure.get_channel_config_name(
            self.impl.get_channel_config()).decode()

    @property
    def sample_type_name(self) -> str:
        """The buffer's sample type name."""
        return alure.get_sample_type_name(
            self.impl.get_sample_type()).decode()


cdef class Source:
    cdef alure.Source impl

    def play_from_buffer(self, buffer: Buffer) -> None:
        """Play the source using a buffer.  The same buffer
        may be played from multiple sources simultaneously.
        """
        self.impl.play(buffer.impl);

    def play_from_decoder(self, decoder: Decoder,
                          chunk_len: int, queue_size: int) -> None:
        """Plays the source by asynchronously streaming audio from
        a decoder.  The given decoder must NOT have its read or seek
        methods called from elsewhere while in use.

        Parameters
        ----------
        decoder : Decoder
            The decoder object to play audio from.
        chunk_len : int
            The number of sample frames to read for each chunk update.
            Smaller values will require more frequent updates and
            larger values will handle more data with each chunk.
        queue_size : int
            The number of chunks to keep queued during playback.
            Smaller values use less memory while larger values
            improve protection against underruns.
        """
        self.impl.play(decoder.pimpl, chunk_len, queue_size)

    @property
    def playing(self) -> bool:
        """Whether the source is currently playing."""
        return self.impl.is_playing()

    @property
    def sample_offset(self) -> int:
        """The source offset in sample frames.  For streaming sources
        this will be the offset based on the decoder's read position.
        """
        return self.impl.get_sample_offset()

    @property
    def stereo_angles(self) -> Tuple[float, float]:
        """The left and right channel angles, in radians, when playing
        a stereo buffer or stream. The angles go counter-clockwise,
        with 0 being in front and positive values going left.

        Has no effect without the AL_EXT_STEREO_ANGLES extension.
        """
        return self.impl.get_stereo_angles()

    @stereo_angles.setter
    def stereo_angles(self, angles: Tuple[float, float]):
        left, right = angles
        self.impl.set_stereo_angles(left, right)


    def destroy(self) -> None:
        """Destroy the source, stop playback and release resources."""
        self.impl.destroy()


cdef class Decoder:
    """Audio decoder interface."""
    cdef shared_ptr[alure.Decoder] pimpl

    @property
    def frequency(self) -> int:
        """The sample frequency, in hertz, of the audio being decoded."""
        return self.pimpl.get()[0].get_frequency()

    @property
    def channel_config_name(self) -> str:
        """Name of the channel configuration of the audio being decoded."""
        return alure.get_channel_config_name(
            self.pimpl.get()[0].get_channel_config()).decode()

    @property
    def sample_type_name(self) -> str:
        """Name of the sample type of the audio being decoded."""
        return alure.get_sample_type_name(
            self.pimpl.get()[0].get_sample_type()).decode()

    @property
    def length(self) -> int:
        """The total length of the audio, in sample frames,
        falling-back to 0.  Note that if the length is 0,
        the decoder may not be used to load a Buffer.
        """
        return self.pimpl.get()[0].get_length()
