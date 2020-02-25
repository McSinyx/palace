# Python object wrappers for alure
# Copyright (C) 2019, 2020  Nguyễn Gia Phong
# Copyright (C) 2020  Ngô Ngọc Đức Huy
# Copyright (C) 2020  Ngô Xuân Minh
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

"""Pythonic Audio Library and Codecs Environment

Attributes
----------
device_names : Dict[str, List[str]]
    Dictionary of available device names corresponding to each type.
device_name_default : Dict[str, str]
    Dictionary of the default device name corresponding to each type.
sample_types : FrozenSet[str]
    Set of sample types.
channel_configs : FrozenSet[str]
    Set of channel configurations.
"""

__all__ = [
    'ALC_FALSE', 'ALC_TRUE', 'ALC_HRTF_SOFT', 'ALC_HRTF_ID_SOFT',
    'device_name_default', 'device_names', 'sample_types', 'channel_configs',
    'sample_size', 'sample_length',
    'query_extension', 'current_context', 'use_context',
    'Device', 'Context', 'Buffer', 'Source', 'SourceGroup',
    'AuxiliaryEffectSlot', 'Decoder', 'BaseDecoder', 'MessageHandler']

from abc import abstractmethod, ABCMeta
from types import TracebackType
from typing import Any, Dict, FrozenSet, Iterator, List, Optional, Tuple, Type
from warnings import warn

from libc.stdint cimport uint64_t   # noqa
from libc.string cimport memcpy
from libcpp cimport bool as boolean, nullptr
from libcpp.memory cimport shared_ptr
from libcpp.string cimport string
from libcpp.utility cimport pair
from libcpp.vector cimport vector
from cpython.mem cimport PyMem_RawMalloc, PyMem_RawFree

from std cimport milliseconds
cimport alure   # noqa

# Aliases
Vector3 = Tuple[float, float, float]
getter = property   # bypass Cython property hijack
setter = lambda fset: property(fset=fset, doc=fset.__doc__)     # noqa

# Cast to Python objects
ALC_FALSE: int = alure.ALC_FALSE
ALC_TRUE: int = alure.ALC_TRUE
ALC_HRTF_SOFT: int = alure.ALC_HRTF_SOFT
ALC_HRTF_ID_SOFT: int = alure.ALC_HRTF_ID_SOFT


# Since multiple calls of DeviceManager.get_instance() will give
# the same instance, we can create module-level variable and expose
# its attributes and methods.  This also prevents the device manager
# from being garbage collected by keeping a reference to the instance.
cdef alure.DeviceManager devmgr = alure.DeviceManager.get_instance()

device_names: Dict[str, List[str]] = dict(
    basic=devmgr.enumerate(alure.DeviceEnumeration.Basic),
    full=devmgr.enumerate(alure.DeviceEnumeration.Full),
    capture=devmgr.enumerate(alure.DeviceEnumeration.Capture))
device_name_default: Dict[str, str] = dict(
    basic=devmgr.default_device_name(alure.DefaultDeviceType.Basic),
    full=devmgr.default_device_name(alure.DefaultDeviceType.Full),
    capture=devmgr.default_device_name(alure.DefaultDeviceType.Capture))

sample_types: FrozenSet[str] = frozenset({
    'Unsigned 8-bit', 'Signed 16-bit', '32-bit float', 'Mulaw'})
channel_configs: FrozenSet[str] = frozenset({
    'Mono', 'Stereo', 'Rear', 'Quadrophonic',
    '5.1 Surround', '6.1 Surround', '7.1 Surround',
    'B-Format 2D', 'B-Format 3D'})


def sample_size(length: int, channel_config: str, sample_type: str) -> int:
    """Return the size of the given number of sample frames.

    Raises
    ------
    RuntimeError
        If the byte size result too large.
    """
    return alure.frames_to_bytes(
        length, to_channel_config(channel_config), to_sample_type(sample_type))


def sample_length(size: int, channel_config: str, sample_type: str) -> int:
    """Return the number of frames stored in the given byte size."""
    return alure.bytes_to_frames(
        size, to_channel_config(channel_config), to_sample_type(sample_type))


def query_extension(name: str) -> bool:
    """Return if a non-device-specific ALC extension exists.

    See Also
    --------
    Device.query_extension : Query ALC extension on a device
    """
    return devmgr.query_extension(name)


def current_context() -> Optional[Context]:
    """Return the context that is currently used."""
    cdef Context current = Context.__new__(Context)
    current.impl = alure.Context.get_current()
    if not current:
        return None
    current.device = Device.__new__(Device)
    current.device.impl = current.impl.get_device()
    current.listener = Listener(current)
    return current


def use_context(context: Optional[Context]) -> None:
    """Make the specified context current for OpenAL operations.

    See Also
    --------
    Context : Audio environment container
    """
    if context is None:
        alure.Context.make_current(<alure.Context> nullptr)
    else:
        alure.Context.make_current((<Context> context).impl)


cdef class Device:
    """Audio mix output, which is either a system audio output stream
    or an actual audio port.

    This can be used as a context manager that calls `close` upon
    completion of the block, even if an error occurs.

    Parameters
    ----------
    name : Optional[str], optional
        The name of the playback device.  If it is `None`,
        the object is left uninitialized.
    fail_safe : bool, optional
        On failure, fallback to the default device if this is `True`,
        otherwise `RuntimeError` is raised.  Default to `False`.

    Raises
    ------
    RuntimeError
        If device creation fails.

    Warns
    -----
    RuntimeWarning
        If `fail_safe` is `True` and the device of given `name`
        cannot be opened.

    See Also
    --------
    device_names : Available device names
    device_name_default : Default device names
    """
    cdef alure.Device impl

    def __init__(self, name: Optional[str] = '',
                 fail_safe: bool = False) -> None:
        if name is None: return
        try:
            self.impl = devmgr.open_playback(name)
        except RuntimeError as exc:
            if fail_safe:
                warn(f'Failed to open device "{name}" - trying default',
                     category=RuntimeWarning)
                self.impl = devmgr.open_playback()
            else:
                raise exc

    def __enter__(self) -> Device:
        return self

    def __exit__(self, exc_type: Optional[Type[BaseException]],
                 exc_val: Optional[BaseException],
                 exc_tb: Optional[TracebackType]) -> Optional[bool]:
        self.close()

    def __lt__(self, other: Any) -> bool:
        if not isinstance(other, Device):
            return NotImplemented
        return self.impl < (<Device> other).impl

    def __le__(self, other: Any) -> bool:
        if not isinstance(other, Device):
            return NotImplemented
        return self.impl <= (<Device> other).impl

    def __eq__(self, other: Any) -> bool:
        if not isinstance(other, Device):
            return NotImplemented
        return self.impl == (<Device> other).impl

    def __ne__(self, other: Any) -> bool:
        if not isinstance(other, Device):
            return NotImplemented
        return self.impl != (<Device> other).impl

    def __gt__(self, other: Any) -> bool:
        if not isinstance(other, Device):
            return NotImplemented
        return self.impl > (<Device> other).impl

    def __ge__(self, other: Any) -> bool:
        if not isinstance(other, Device):
            return NotImplemented
        return self.impl >= (<Device> other).impl

    def __bool__(self) -> bool:
        return <boolean> self.impl

    @property
    def name(self) -> Dict[str, str]:
        """A dictionary of device name corresponding to each type."""
        return {'basic': self.impl.get_name(alure.PlaybackName.Basic),
                'full': self.impl.get_name(alure.PlaybackName.Full)}

    def query_extension(self, name: str) -> bool:
        """Return if an ALC extension exists on this device.

        See Also
        --------
        query_extension : Query non-device-specific ALC extension
        """
        return self.impl.query_extension(name)

    @property
    def alc_version(self) -> Tuple[int, int]:
        """ALC version supported by this device."""
        cdef alure.Version version = self.impl.get_alc_version()
        return version.get_major(), version.get_minor()

    @property
    def efx_version(self) -> Tuple[int, int]:
        """EFX version supported by this device.

        If the `ALC_EXT_EFX` extension is unsupported,
        this will be `(0, 0)`.
        """
        cdef alure.Version version = self.impl.get_efx_version()
        return version.get_major(), version.get_minor()

    @property
    def frequency(self) -> int:
        """Playback frequency in hertz."""
        return self.impl.get_frequency()

    @property
    def max_auxiliary_sends(self) -> int:
        """Maximum number of auxiliary source sends.

        If `ALC_EXT_EFX` is unsupported, this will be 0.
        """
        return self.impl.get_max_auxiliary_sends()

    @property
    def hrtf_names(self) -> List[str]:
        """List of available HRTF names.

        The order is retained from OpenAL, such that the index of
        a given name is the ID to use with `ALC_HRTF_ID_SOFT`.

        If the `ALC_SOFT_HRTF` extension is unavailable,
        this will be an empty list.
        """
        return self.impl.enumerate_hrtf_names()

    @property
    def hrtf_enabled(self) -> bool:
        """Whether HRTF is enabled on the device.

        If the `ALC_SOFT_HRTF` extension is unavailable,
        this will return False although there could still be
        HRTF applied at a lower hardware level.
        """
        return self.impl.is_hrtf_enabled()

    @property
    def current_hrtf(self) -> Optional[str]:
        """Name of the HRTF currently being used by this device.

        If HRTF is not currently enabled, this will be `None`.
        """
        name: str = self.impl.get_current_hrtf()
        return name or None

    def reset(self, attrs: Dict[int, int] = {}) -> None:
        """Reset the device, using the specified attributes.

        If the `ALC_SOFT_HRTF` extension is unavailable,
        this will be a no-op.
        """
        self.impl.reset(mkattrs(attrs.items()))

    def pause_dsp(self) -> None:
        """Pause device processing and stop contexts' updates.

        Multiple calls are allowed but it is not reference counted,
        so the device will resume after one `resume_dsp` call.

        This requires the `ALC_SOFT_pause_device` extension.
        """
        self.impl.pause_dsp()

    def resume_dsp(self) -> None:
        """Resume device processing and restart contexts' updates.

        Multiple calls are allowed and will no-op.
        """
        self.impl.resume_dsp()

    @property
    def clock_time(self) -> int:
        """Current clock time for the device.

        Notes
        -----
        This starts relative to the device being opened, and does not
        increment while there are no contexts nor while processing
        is paused.  Currently, this may not exactly match the rate
        that sources play at.  In the future it may utilize an OpenAL
        extension to retrieve the audio device's real clock.
        """
        return self.impl.get_clock_time().count()

    def close(self) -> None:
        """Close and free the device.

        All previously-created contexts must first be destroyed.
        """
        self.impl.close()


cdef class Context:
    """Container maintaining the entire audio environment, its settings
    and components such as sources, buffers and effects.

    This can be used as a context manager, e.g. ::

        with context:
            ...

    is equivalent to ::

        previous = current_context()
        use_context(context)
        try:
            ...
        finally:
            use_context(previous)
            context.destroy()

    Parameters
    ----------
    device : Device
        The `device` on which the context is to be created.
    attrs : Dict[int, int]
        Attributes specified for the context to be created.

    Attributes
    ----------
    device : Device
        The device this context was created from.
    listener : Listener
        The listener instance of this context.
    message_handler : MessageHandler
        Handler of some certain events.

    Raises
    ------
    RuntimeError
        If context creation fails.
    """
    cdef alure.Context impl
    cdef alure.Context previous
    cdef readonly Device device
    cdef readonly Listener listener
    cdef public MessageHandler message_handler

    def __init__(self, device: Device, attrs: Dict[int, int] = {}) -> None:
        self.impl = device.impl.create_context(mkattrs(attrs.items()))
        self.device = device
        self.listener = Listener(self)
        self.message_handler = MessageHandler()
        self.impl.set_message_handler(
            shared_ptr[alure.MessageHandler](new CppMessageHandler(self)))

    def __enter__(self) -> Context:
        self.previous = alure.Context.get_current()
        use_context(self)
        return self

    def __exit__(self, exc_type: Optional[Type[BaseException]],
                 exc_val: Optional[BaseException],
                 exc_tb: Optional[TracebackType]) -> Optional[bool]:
        alure.Context.make_current(self.previous)
        self.destroy()

    def __lt__(self, other: Any) -> bool:
        if not isinstance(other, Context):
            return NotImplemented
        return self.impl < (<Context> other).impl

    def __le__(self, other: Any) -> bool:
        if not isinstance(other, Context):
            return NotImplemented
        return self.impl <= (<Context> other).impl

    def __eq__(self, other: Any) -> bool:
        if not isinstance(other, Context):
            return NotImplemented
        return self.impl == (<Context> other).impl

    def __ne__(self, other: Any) -> bool:
        if not isinstance(other, Context):
            return NotImplemented
        return self.impl != (<Context> other).impl

    def __gt__(self, other: Any) -> bool:
        if not isinstance(other, Context):
            return NotImplemented
        return self.impl > (<Context> other).impl

    def __ge__(self, other: Any) -> bool:
        if not isinstance(other, Context):
            return NotImplemented
        return self.impl >= (<Context> other).impl

    def __bool__(self) -> bool:
        return <boolean> self.impl

    def destroy(self) -> None:
        """Destroy the context.

        The context must not be current when this is called.
        """
        self.impl.destroy()

    def is_supported(self, channel_config: str, sample_type: str) -> bool:
        """Return if the channel configuration and sample type
        are supported by the context.

        See Also
        --------
        sample_types : Set of sample types
        channel_configs : Set of channel configurations
        """
        return self.impl.is_supported(to_channel_config(channel_config),
                                      to_sample_type(sample_type))

    def update(self) -> None:
        """Update the context and all sources belonging to this context."""
        self.impl.update()


cdef class Listener:
    """Listener instance of the context, i.e each context
    will only have one listener.

    Parameters
    ----------
    context : Context
        The `context` on which the listener instance is to be created.
    """
    cdef alure.Listener impl

    def __init__(self, context: Context) -> None:
        self.impl = context.impl.get_listener()

    def __bool__(self) -> bool:
        return <boolean> self.impl

    @setter
    def gain(self, value: float) -> None:
        """Master gain for all context output."""
        self.impl.set_gain(value)

    @setter
    def position(self, value: Vector3) -> None:
        """3D position of the listener."""
        self.impl.set_position(to_vector3(value))

    @setter
    def velocity(self, value: Vector3) -> None:
        """3D velocity of the listener, in units per second.

        As with OpenAL, this does not actually alter the listener's
        position, and instead just alters the pitch as determined by
        the doppler effect.
        """
        self.impl.set_velocity(to_vector3(value))

    @setter
    def orientation(self, value: Tuple[Vector3, Vector3]) -> None:
        """3D orientation of the listener.

        Parameters
        ----------
        at : Tuple[float, float, float]
            Relative position.
        up : Tuple[float, float, float]
            Relative direction.
        """
        at, up = value
        self.impl.set_orientation(
            pair[alure.Vector3, alure.Vector3](to_vector3(at), to_vector3(up)))

    @setter
    def meters_per_unit(self, value: float) -> None:
        """Number of meters per unit.

        This is used for various effects relying on the distance
        in meters including air absorption and initial reverb decay.
        If this is changed, so should the speed of sound
        (e.g. `context.speed_of_sound = 343.3 / meters_per_unit`
        to maintain a realistic 343.3 m/s for sound propagation).
        """
        self.impl.set_meters_per_unit(value)


cdef class Buffer:
    """Buffer of preloaded PCM samples coming from a `Decoder`.

    Cached buffers must be freed using `destroy` before destroying
    `context`.  Alternatively, this can be used as a context manager
    that calls `destroy` upon completion of the block,
    even if an error occurs.

    Parameters
    ----------
    context : Context
        The context from which the buffer is to be created and cached.
    name : str
        Audio file or resource name.  Multiple calls with the same name
        will return the same buffer.

    Attributes
    ----------
    name : str
        Audio file or resource name.

    Raises
    ------
    RuntimeError
        If the buffer can't be loaded.
    """
    cdef alure.Buffer impl
    cdef Context context
    cdef readonly str name

    def __init__(self, context: Context, name: str) -> None:
        self.impl = context.impl.get_buffer(name)
        self.context, self.name = context, name

    def __enter__(self) -> Buffer:
        return self

    def __exit__(self, exc_type: Optional[Type[BaseException]],
                 exc_val: Optional[BaseException],
                 exc_tb: Optional[TracebackType]) -> Optional[bool]:
        self.destroy()

    @property
    def length(self) -> int:
        """Length of the buffer in sample frames."""
        return self.impl.get_length()

    @property
    def length_seconds(self) -> float:
        """Length of the buffer in seconds."""
        return self.length / self.frequency

    @property
    def frequency(self) -> int:
        """Buffer's frequency in hertz."""
        return self.impl.get_frequency()

    @property
    def channel_config(self) -> str:
        """Buffer's sample configuration."""
        return alure.get_channel_config_name(
            self.impl.get_channel_config())

    @property
    def sample_type(self) -> str:
        """Buffer's sample type."""
        return alure.get_sample_type_name(
            self.impl.get_sample_type())

    def play(self, source: Optional[Source] = None) -> Source:
        """Play `source` using the buffer.

        Return the source used for playing.  If `None` is given,
        create a new one.

        One buffer may be played from multiple sources simultaneously.
        """
        if source is None: source = Source(self.context)
        (<Source> source).impl.play(self.impl)
        return source

    @property
    def loop_points(self) -> Tuple[int, int]:
        """Loop points for looping sources.

        If the `AL_SOFT_loop_points` extension is not supported by the
        current context, `start = 0` and `end = length` respectively.
        Otherwise, `start < end <= length`.

        Parameters
        ----------
        start : int
            Starting point, in sample frames (inclusive).
        end : int
            Ending point, in sample frames (exclusive).

        Notes
        -----
        The buffer must not be in use when this property is set.
        """
        return self.impl.get_loop_points()

    @loop_points.setter
    def loop_points(self, value: Tuple[int, int]) -> None:
        start, end = value
        self.impl.set_loop_points(start, end)

    @property
    def sources(self) -> List[Source]:
        """`Source` objects currently playing the buffer."""
        sources = []
        for alure_source in self.impl.get_sources():
            source = Source(None)
            source.impl = alure_source
            sources.append(source)
        return sources

    @property
    def source_count(self) -> int:
        """Number of sources currently using the buffer.

        Notes:
        `Context.update` needs to be called to reliably ensure the count
        is kept updated for when sources reach their end.  This is
        equivalent to calling `len(self.sources)`.
        """
        return self.impl.get_source_count()

    def destroy(self) -> None:
        """Free the buffer's cache

        This invalidates all other `Buffer` objects with the same name.
        """
        self.context.impl.remove_buffer(self.impl)


cdef class Source:
    """Sound source for playing audio.

    There is no practical limit to the number of sources one may create.

    When the source is no longer needed, `destroy` must be called,
    unless the context manager is used, which guarantees the source's
    destructioni upon completion of the block, even if an error occurs.

    Parameters
    ----------
    context : Optional[Context]
        The context from which the source is to be created.
        If it is `None`, the object is left uninitialized.
    """
    cdef alure.Source impl

    def __init__(self, context: Optional[Context]) -> None:
        if context is None: return
        self.impl = (<Context> context).impl.create_source()

    def __enter__(self) -> Source:
        return self

    def __exit__(self, exc_type: Optional[Type[BaseException]],
                 exc_val: Optional[BaseException],
                 exc_tb: Optional[TracebackType]) -> Optional[bool]:
        self.destroy()

    # TODO: play from future buffer

    def stop(self) -> None:
        """Stop playback, releasing the buffer or decoder reference.

        Any pending playback from a future buffer is canceled.
        """
        self.impl.stop()

    def fade_out_to_stop(self, gain: float, ms: int) -> None:
        """Fade the source to `gain` over `ms` milliseconds.

        `gain` is in addition to the base gain and must be within
        the [0, 1] interval.  `ms` must be positive.

        The fading is logarithmic.  As a result, the initial drop-off
        may happen faster than expected but the fading is more
        perceptually consistant over the given duration.  It will take
        just as much time to go from -6 dB to -12 dB as it will to go
        from -40 dB to -46 dB, for example.

        Pending playback from a future buffer is not immediately
        canceled, but the fade timer starts with this call.  If the
        future buffer then becomes ready, it will start mid-fade.
        Pending playback will be canceled if the fade out completes
        before the future buffer becomes ready.

        Fading is updated during calls to `Context.update`,
        which should be called regularly (30 to 50 times per second)
        for the fading to be smooth.
        """
        self.impl.fade_out_to_stop(gain, milliseconds(ms))

    def pause(self) -> None:
        """Pause the source if it is playing."""
        self.impl.pause()

    def resume(self) -> None:
        """Resume the source if it is paused."""
        self.impl.resume()

    @property
    def pending(self) -> bool:
        """Whether the source is waiting to play a future buffer."""
        return self.impl.is_pending()

    @property
    def playing(self) -> bool:
        """Whether the source is currently playing."""
        return self.impl.is_playing()

    @property
    def paused(self) -> bool:
        """Whether the source is currently paused."""
        return self.impl.is_paused()

    @property
    def playing_or_pending(self) -> bool:
        """Whether the source is currently playing
        or waiting to play in a future buffer.
        """
        return self.impl.is_playing_or_pending()

    @property
    def group(self) -> Optional[SourceGroup]:
        """Parent group of this source.

        The parent group influences all sources that belong to it.
        A source may only be the child of one `SourceGroup` at a time,
        although that source group may belong to another source group.

        This is `None` when the source does not belong to any group.
        On the other hand, setting it to `None` removes the source
        from its current group.

        See Also
        --------
        SourceGroup : A group of `Source` references
        """
        source_group = SourceGroup(None)
        source_group.impl = self.impl.get_group()
        return source_group or None

    @group.setter
    def group(self, value: Optional[SourceGroup]) -> None:
        if value is None:
            self.impl.set_group(<alure.SourceGroup> nullptr)
        else:
            self.impl.set_group((<SourceGroup> value).impl)

    @property
    def priority(self) -> int:
        """Playback priority (natural number).

        The lowest priority sources will be forcefully stopped
        when no more mixing sources are available and higher priority
        sources are played.
        """
        return self.impl.get_priority()

    @priority.setter
    def priority(self, value: int) -> None:
        self.impl.set_priority(value)

    @property
    def offset(self) -> int:
        """Source offset in sample frames.  For streaming sources
        this will be the offset based on the decoder's read position.
        """
        return self.impl.get_sample_offset()

    @offset.setter
    def offset(self, value: int) -> None:
        self.impl.set_offset(value)

    @property
    def latency(self) -> int:
        """Source latency in nanoseconds.

        If the `AL_SOFT_source_latency` extension is unsupported,
        the latency will be 0.
        """
        return self.impl.get_sample_offset_latency().second.count()

    @property
    def offset_seconds(self) -> float:
        """Source offset in seconds.

        For streaming sources this will be the offset based on
        the decoder's read position.
        """
        return self.impl.get_sec_offset().count()

    @property
    def latency_seconds(self) -> float:
        """Source latency in seconds.

        If the `AL_SOFT_source_latency` extension is unsupported,
        the latency will be 0.
        """
        return self.impl.get_sec_offset_latency().second.count()

    @property
    def looping(self) -> bool:
        """Whether the source should loop on the Buffer or Decoder
        object's loop points.
        """
        return self.impl.get_looping()

    @looping.setter
    def looping(self, value: bool) -> None:
        self.impl.set_looping(value)

    @property
    def pitch(self) -> float:
        """Linear pitch shift base, default to 1.0.

        Raises
        ------
        ValueError
            If set to a nonpositive value.
        """
        return self.impl.get_pitch()

    @pitch.setter
    def pitch(self, value: float) -> None:
        self.impl.set_pitch(value)

    @property
    def gain(self) -> float:
        """Base linear volume gain, default to 1.0.

        Raises
        ------
        ValueError
            If set to a negative value.
        """
        return self.impl.get_gain()

    @gain.setter
    def gain(self, value: float) -> None:
        self.impl.set_gain(value)

    @property
    def gain_range(self) -> Tuple[float, float]:
        """The range which the source's gain is clamped to after
        distance and cone attenuation are applied to the gain base,
        although before the filter gain adjustements.

        Parameters
        ----------
        mingain : float
            Minimum gain, default to 0.
        maxgain : float
            Maximum gain, default to 1.

        Raises
        ------
        ValueError
            If set to a value where `mingain` is greater than `maxgain`
            or either of them is outside of the [0, 1] interval.
        """
        return self.impl.get_gain_range()

    @gain_range.setter
    def gain_range(self, value: Tuple[float, float]) -> None:
        mingain, maxgain = value
        self.impl.set_gain_range(mingain, maxgain)

    @property
    def distance_range(self) -> Tuple[float, float]:
        """Reference and maximum distance for current distance model.

        For Clamped distance models, the source's calculated
        distance is clamped to the specified range before applying
        distance-related attenuation.

        Parameters
        ----------
        refdist : float
            The distance at which the source's volume will not have
            any extra attenuation (an effective gain multiplier of 1),
            default to 0.
        maxdist : float
            The maximum distance, default to FLT_MAX, which is the
            maximum value of a single-precision floating-point variable
            (2**128 - 2**104).

        Raises
        ------
        ValueError
            If set to a value where `refdist` is greater than `maxdist`
            or either of them is outside of the [0, FLT_MAX] interval.
        """
        return self.impl.get_distance_range()

    @distance_range.setter
    def distance_range(self, value: Tuple[float, float]) -> None:
        refdist, maxdist = value
        self.impl.set_distance_range(refdist, maxdist)

    @property
    def position(self) -> Vector3:
        """3D position of the source."""
        return from_vector3(self.impl.get_position())

    @position.setter
    def position(self, value: Vector3) -> None:
        self.impl.set_position(to_vector3(value))

    @property
    def velocity(self) -> Vector3:
        """3D velocity in units per second.

        As with OpenAL, this does not actually alter the source's
        position, and instead just alters the pitch as determined
        by the doppler effect.
        """
        return from_vector3(self.impl.get_velocity())

    @velocity.setter
    def velocity(self, value: Vector3) -> None:
        self.impl.set_velocity(to_vector3(value))

    @property
    def orientation(self) -> Tuple[Vector3, Vector3]:
        """3D orientation of the source.

        Parameters
        ----------
        at : Tuple[float, float, float]
            Relative position.
        up : Tuple[float, float, float]
            Relative direction.

        Notes
        -----
        Unlike the `AL_EXT_BFORMAT` extension this property
        comes from, this also affects the facing direction.
        """
        cdef pair[alure.Vector3, alure.Vector3] o = self.impl.get_orientation()
        return from_vector3(o.first), from_vector3(o.second)

    @orientation.setter
    def orientation(self, value: Tuple[Vector3, Vector3]) -> None:
        at, up = value
        self.impl.set_orientation(
            pair[alure.Vector3, alure.Vector3](to_vector3(at), to_vector3(up)))

    @property
    def cone_angles(self) -> Tuple[float, float]:
        """Cone inner and outer angles in degrees.

        Parameters
        ----------
        inner : float
            The area within which the listener will hear the source
            without extra attenuation, default to 360.
        outer : float
            The area outside of which the listener will hear the source
            attenuated according to `outer_cone_gains`, default to 360.

        Raises
        ------
        ValueError
            If set to a value where `inner` is greater than `outer`
            or either of them is outside of the [0, 360] interval.

        Notes
        -----
        The areas follow the facing direction, so for example
        an inner angle of 180 means the entire front face of
        the source is in the inner cone.
        """
        return self.impl.get_cone_angles()

    @cone_angles.setter
    def cone_angles(self, value: Tuple[float, float]) -> None:
        inner, outer = value
        self.impl.set_cone_angles(inner, outer)

    @property
    def outer_cone_gains(self) -> Tuple[float, float]:
        """Linear gain and gainhf multiplier when the listener is
        outside of the source's outer cone area.

        Parameters
        ----------
        gain : float
            Linear gain applying to all frequencies, default to 1.
        gainhf : float
            Linear gainhf applying extra attenuation to high frequencies
            creating a low-pass effect, default to 1.  It has no effect
            without the `ALC_EXT_EFX` extension.

        Raises
        ------
        ValueError
            If either of the gains is set to a value
            outside of the [0, 1] interval.
        """
        return self.impl.get_outer_cone_gains()

    @outer_cone_gains.setter
    def outer_cone_gains(self, value: Tuple[float, float]) -> None:
        gain, gainhf = value
        self.impl.set_outer_cone_gains(gain, gainhf)

    @property
    def rolloff_factors(self) -> Tuple[float, float]:
        """Rolloff factor and room factor for the direct and send paths.

        This is effectively a distance scaling relative to
        the reference distance.

        Raises
        ------
        ValueError
            If either of rolloff factors is set to a negative value.

        Notes
        -----
        To disable distance attenuation for send paths,
        set room factor to 0.  The reverb engine will, by default,
        apply a more realistic room decay based on the reverb decay
        time and distance.
        """
        return self.impl.get_rolloff_factors()

    @rolloff_factors.setter
    def rolloff_factors(self, value: Tuple[float, float]) -> None:
        factor, room_factor = value
        self.impl.set_rolloff_factors(factor, room_factor)

    @property
    def doppler_factor(self) -> float:
        """The doppler factor for the doppler effect's pitch shift.

        This effectively scales the source and listener velocities
        for the doppler calculation.

        Raises
        ------
        ValueError
            If set to a value outside of the [0, 1] interval.
        """
        return self.impl.get_doppler_factor()

    @doppler_factor.setter
    def doppler_factor(self, value: float) -> None:
        self.impl.set_doppler_factor(value)

    @property
    def relative(self) -> bool:
        """Whether the source's position, velocity, and orientation
        are relative to the listener.
        """
        return self.impl.get_relative()

    @relative.setter
    def relative(self, value: bool) -> None:
        self.impl.set_relative(value)

    @property
    def radius(self) -> float:
        """Radius of the source, as if it is a sound-emitting sphere.

        This has no effect without the `AL_EXT_SOURCE_RADIUS` extension.

        Raises
        ------
        ValueError
            If set to a negative value.
        """
        return self.impl.get_radius()

    @radius.setter
    def radius(self, value: float) -> None:
        self.impl.set_radius(value)

    @property
    def stereo_angles(self) -> Tuple[float, float]:
        """Left and right channel angles, in radians, when playing
        a stereo buffer or stream.  The angles go counter-clockwise,
        with 0 being in front and positive values going left.

        This has no effect without the `AL_EXT_STEREO_ANGLES` extension.
        """
        return self.impl.get_stereo_angles()

    @stereo_angles.setter
    def stereo_angles(self, value: Tuple[float, float]) -> None:
        left, right = value
        self.impl.set_stereo_angles(left, right)

    @property
    def spatialize(self) -> Optional[bool]:
        """Either `True` (the source always has 3D spatialization
        features), `False` (never has 3D spatialization features),
        or `None` (spatialization is enabled based on playing
        a mono sound or not, default).

        This has no effect without
        the `AL_SOFT_source_spatialize` extension.
        """
        cdef alure.Spatialize value = self.impl.get_3d_spatialize()
        if value == alure.Spatialize.Auto: return None
        if value == alure.Spatialize.On: return True
        return False

    @spatialize.setter
    def spatialize(self, value: Optional[bool]) -> None:
        if value is None:
            self.impl.set_3d_spatialize(alure.Spatialize.Auto)
        elif value:
            self.impl.set_3d_spatialize(alure.Spatialize.On)
        else:
            self.impl.set_3d_spatialize(alure.Spatialize.Off)

    @property
    def resampler_index(self) -> int:
        """Index of the resampler to use for this source.

        The index must be nonnegative, from the resamplers returned
        by `Context.get_available_resamplers`, and has no effect
        without the `AL_SOFT_source_resampler` extension.
        """
        return self.impl.get_resampler_index()

    @resampler_index.setter
    def resampler_index(self, value: int) -> None:
        self.impl.set_resampler_index(value)

    @property
    def air_absorption_factor(self) -> float:
        """Multiplier for the amount of atmospheric high-frequency
        absorption, ranging from 0 to 10.  A factor of 1 results in
        a nominal -0.05 dB per meter, with higher values simulating
        foggy air and lower values simulating dryer air; default to 0.
        """
        return self.impl.get_air_absorption_factor()

    @air_absorption_factor.setter
    def air_absorption_factor(self, value: float) -> None:
        self.impl.set_air_absorption_factor(value)

    @property
    def gain_auto(self) -> Tuple[bool, bool, bool]:
        """Whether the direct path's high frequency gain,
        send paths' gain and send paths' high-frequency gain are
        automatically adjusted.  The default is `True` for all.
        """
        return (self.impl.get_direct_gain_hf_auto(),
                self.impl.get_send_gain_auto(),
                self.impl.get_send_gain_hf_auto())

    @gain_auto.setter
    def gain_auto(self, value: Tuple[bool, bool, bool]) -> None:
        directhf, send, sendhf = value
        self.impl.set_gain_auto(directhf, send, sendhf)

    # TODO: set direct filter
    # TODO: set send filter

    @setter
    def auxiliary_send(self, slot: AuxiliaryEffectSlot, send: int) -> None:
        """Connect the effect slot to the given send path.

        Any filter properties on the send path remain as they were.
        """
        self.impl.set_auxiliary_send(slot.impl, send)

    # TODO: set auxiliary send filter

    def destroy(self) -> None:
        """Destroy the source, stop playback and release resources."""
        self.impl.destroy()


cdef class SourceGroup:
    """A group of `Source` references.

    For instance, setting `SourceGroup.gain` to 0.5 will halve the gain
    of all sources in the group.

    This can be used as a context manager that calls `destroy` upon
    completion of the block, even if an error occurs.

    Parameters
    ----------
    context : Optional[Context]
        The context from which the source group is to be created.
        If it is `None`, the object is left uninitialized.
    """
    cdef alure.SourceGroup impl

    def __init__(self, context: Optional[Context]) -> None:
        if context is None: return
        self.impl = (<Context> context).impl.create_source_group()

    def __enter__(self) -> SourceGroup:
        return self

    def __exit__(self, exc_type: Optional[Type[BaseException]],
                 exc_val: Optional[BaseException],
                 exc_tb: Optional[TracebackType]) -> Optional[bool]:
        self.destroy()

    def __lt__(self, other: Any) -> bool:
        if not isinstance(other, SourceGroup):
            return NotImplemented
        return self.impl < (<SourceGroup> other).impl

    def __le__(self, other: Any) -> bool:
        if not isinstance(other, SourceGroup):
            return NotImplemented
        return self.impl <= (<SourceGroup> other).impl

    def __eq__(self, other: Any) -> bool:
        if not isinstance(other, SourceGroup):
            return NotImplemented
        return self.impl == (<SourceGroup> other).impl

    def __ne__(self, other: Any) -> bool:
        if not isinstance(other, SourceGroup):
            return NotImplemented
        return self.impl != (<SourceGroup> other).impl

    def __gt__(self, other: Any) -> bool:
        if not isinstance(other, SourceGroup):
            return NotImplemented
        return self.impl > (<SourceGroup> other).impl

    def __ge__(self, other: Any) -> bool:
        if not isinstance(other, SourceGroup):
            return NotImplemented
        return self.impl >= (<SourceGroup> other).impl

    def __bool__(self) -> bool:
        return <boolean> self.impl

    @property
    def parent_group(self) -> SourceGroup:
        """The source group this source group is a child of.

        Raises
        ------
        RuntimeException
            If this group is being added to its sub-group
            (i.e. it would create a circular sub-group chain).
        """
        source_group: SourceGroup = SourceGroup(None)
        source_group.impl = self.impl.get_parent_group()
        return source_group

    @parent_group.setter
    def parent_group(self, value: SourceGroup) -> None:
        self.impl.set_parent_group(value.impl)

    @property
    def gain(self) -> float:
        """Source group gain.

        This accumulates with its sources' and sub-groups' gain.
        """
        return self.impl.get_gain()

    @gain.setter
    def gain(self, value: float) -> None:
        self.impl.set_gain(value)

    @property
    def pitch(self) -> float:
        """Source group pitch.

        This accumulates with its sources' and sub-groups' pitch.
        """
        return self.impl.get_pitch()

    @pitch.setter
    def pitch(self, value: float) -> None:
        self.impl.set_pitch(value)

    @property
    def sources(self) -> List[Source]:
        """The list of sources currently in the group."""
        sources = []
        for alure_source in self.impl.get_sources():
            source = Source(None)
            source.impl = alure_source
            sources.append(source)
        return sources

    @property
    def sub_groups(self) -> List[SourceGroup]:
        """The list of subgroups currently in the group."""
        source_groups = []
        for alure_source_group in self.impl.get_sub_groups():
            source_group = SourceGroup(None)
            source_group.impl = alure_source_group
            source_groups.append(source_group)
        return source_groups

    def pause_all(self) -> None:
        """Pause all currently-playing sources that are under
        this group, including sub-groups.
        """
        self.impl.pause_all()

    def resume_all(self) -> None:
        """Resume all paused sources that are under this group,
        including sub-groups.
        """
        self.impl.resume_all()

    def stop_all(self) -> None:
        """Stop all sources that are under this group,
        including sub-groups.
        """
        self.impl.stop_all()

    def destroy(self) -> None:
        """Destroy the source group, removing all sources from it
        before being freed.
        """
        self.impl.destroy()


cdef class AuxiliaryEffectSlot:
    """An effect processor.

    It takes the output mix of zero or more sources,
    applies DSP for the desired effect (as configured
    by a given `Effect` object), then adds to the output mix.

    This can be used as a context manager that calls `destroy`
    upon completion of the block, even if an error occurs.

    Parameters
    ----------
    context : Context
        The context to create the auxiliary effect slot.

    Raises
    ------
    RuntimeError
        If the effect slot can't be created.
    """
    cdef alure.AuxiliaryEffectSlot impl

    def __init__(self, context: Context) -> None:
        self.impl = context.impl.create_auxiliary_effect_slot()

    def __enter__(self) -> AuxiliaryEffectSlot:
        return self

    def __exit__(self, exc_type: Optional[Type[BaseException]],
                 exc_val: Optional[BaseException],
                 exc_tb: Optional[TracebackType]) -> Optional[bool]:
        self.destroy()

    def __lt__(self, other: Any) -> bool:
        if not isinstance(other, AuxiliaryEffectSlot):
            return NotImplemented
        return self.impl < (<AuxiliaryEffectSlot> other).impl

    def __le__(self, other: Any) -> bool:
        if not isinstance(other, AuxiliaryEffectSlot):
            return NotImplemented
        return self.impl <= (<AuxiliaryEffectSlot> other).impl

    def __eq__(self, other: Any) -> bool:
        if not isinstance(other, AuxiliaryEffectSlot):
            return NotImplemented
        return self.impl == (<AuxiliaryEffectSlot> other).impl

    def __ne__(self, other: Any) -> bool:
        if not isinstance(other, AuxiliaryEffectSlot):
            return NotImplemented
        return self.impl != (<AuxiliaryEffectSlot> other).impl

    def __gt__(self, other: Any) -> bool:
        if not isinstance(other, AuxiliaryEffectSlot):
            return NotImplemented
        return self.impl > (<AuxiliaryEffectSlot> other).impl

    def __ge__(self, other: Any) -> bool:
        if not isinstance(other, AuxiliaryEffectSlot):
            return NotImplemented
        return self.impl >= (<AuxiliaryEffectSlot> other).impl

    def __bool__(self) -> bool:
        return <boolean> self.impl

    @setter
    def gain(self, value: float) -> None:
        """Gain of the effect slot."""
        self.impl.set_gain(value)

    @setter
    def send_auto(self, value: bool) -> None:
        """If set to `True`, the reverb effect will automatically
        apply adjustments to the source's send slot gains based
        on the effect properties.

        Has no effect when using non-reverb effects.  Default is `True`.
        """
        self.impl.set_send_auto(value)

    # TODO: apply effect

    def destroy(self) -> None:
        """Destroy the effect slot, returning it to the system.
        If the effect slot is currently set on a source send,
        it will be removed first.
        """
        return self.impl.destroy()

    @property
    def source_sends(self) -> Iterator[Tuple[Source, int]]:
        """Iterator of each `Source` object and its pairing
        send this effect slot is set on.
        """
        for source_send in self.impl.get_source_sends():
            source = Source(None)
            send = source_send.send
            source.impl = source_send.source
            yield source, send

    @property
    def use_count(self):
        """Number of source sends the effect slot
        is used by.  This is equivalent to calling
        `len(tuple(self.source_sends))`.
        """
        return self.impl.get_use_count()


cdef class Decoder:
    """Generic audio decoder.

    Parameters
    ----------
    context : Context
        The context from which the decoder is to be created.
    name : str
        Audio file or resource name.

    See Also
    --------
    Buffer : Preloaded PCM samples coming from a `Decoder`

    Notes
    -----
    Due to implementation details, while this creates decoder objects
    from filenames using contexts, it is the superclass of the ABC
    (abstract base class) `BaseDecoder`.
    """
    cdef shared_ptr[alure.Decoder] pimpl

    def __init__(self, context: Context, name: str) -> None:
        self.pimpl = context.impl.create_decoder(name)

    @property
    def frequency(self) -> int:
        """Sample frequency, in hertz, of the audio being decoded."""
        return self.pimpl.get()[0].get_frequency()

    @property
    def channel_config(self) -> str:
        """Channel configuration of the audio being decoded."""
        return alure.get_channel_config_name(
            self.pimpl.get()[0].get_channel_config())

    @property
    def sample_type(self) -> str:
        """Sample type of the audio being decoded."""
        return alure.get_sample_type_name(
            self.pimpl.get()[0].get_sample_type())

    @property
    def length(self) -> int:
        """Length of audio in sample frames, falling-back to 0.

        Notes
        -----
        Zero-length decoders may not be used to load a `Buffer`.
        """
        return self.pimpl.get()[0].get_length()

    @property
    def length_seconds(self) -> float:
        """Length of audio in seconds, falling-back to 0.0.

        Notes
        -----
        Zero-length decoders may not be used to load a `Buffer`.
        """
        return self.length / self.frequency

    def seek(self, pos: int) -> bool:
        """Seek to pos, specified in sample frames.

        Return if the seek was successful.
        """
        return self.pimpl.get()[0].seek(pos)

    @property
    def loop_points(self) -> Tuple[int, int]:
        """Loop points in sample frames.

        Parameters
        ----------
        start : int
            Inclusive starting loop point.
        end : int
            Exclusive starting loop point.

        Notes
        -----
        If `start >= end`, all available samples are included
        in the loop.
        """
        return self.pimpl.get()[0].get_loop_points()

    def read(self, count: int) -> bytes:
        """Decode and return `count` sample frames.

        If less than the requested count samples is returned,
        the end of the audio has been reached.

        See Also
        --------
        sample_length : length of samples of given size
        """
        cdef void* ptr = PyMem_RawMalloc(alure.frames_to_bytes(
            count, self.pimpl.get()[0].get_channel_config(),
            self.pimpl.get()[0].get_sample_type()))
        if ptr == NULL: raise RuntimeError('Unable to allocate memory')
        count = self.pimpl.get()[0].read(ptr, count)
        cdef string samples = string(<const char*> ptr, alure.frames_to_bytes(
            count, self.pimpl.get()[0].get_channel_config(),
            self.pimpl.get()[0].get_sample_type()))
        PyMem_RawFree(ptr)
        return samples

    def play(self, source: Source, chunk_len: int, queue_size: int) -> None:
        """Stream audio asynchronously from the decoder.

        The decoder must NOT have its `read` or `seek` called
        from elsewhere while in use.

        Parameters
        ----------
        source : Source
            The source object to play audio.
        chunk_len : int
            The number of sample frames to read for each chunk update.
            Smaller values will require more frequent updates and
            larger values will handle more data with each chunk.
        queue_size : int
            The number of chunks to keep queued during playback.
            Smaller values use less memory while larger values
            improve protection against underruns.
        """
        source.impl.play(self.pimpl, chunk_len, queue_size)


# Decoder interface
cdef class _BaseDecoder(Decoder):
    """Cython bridge for BaseDecoder.

    This class is NOT meant to be instantiated.
    """
    def __cinit__(self, *args, **kwargs) -> None:
        self.pimpl = shared_ptr[alure.Decoder](new CppDecoder(self))

    def __init__(self, *args, **kwargs) -> None:
        raise TypeError("Can't instantiate class _BaseDecoder")


class BaseDecoder(_BaseDecoder, metaclass=ABCMeta):
    """Audio decoder interface.

    Applications may derive from this, implement necessary methods,
    and use it in places the API wants a `BaseDecoder` object.

    Exceptions raised from `BaseDecoder` instances are ignored.
    """
    @abstractmethod
    def __init__(self, *args, **kwargs) -> None: pass

    @getter
    @abstractmethod
    def frequency(self) -> int:
        """Sample frequency, in hertz, of the audio being decoded."""

    @getter
    @abstractmethod
    def channel_config(self) -> str:
        """Channel configuration of the audio being decoded."""

    @getter
    @abstractmethod
    def sample_type(self) -> str:
        """Sample type of the audio being decoded."""

    @getter
    @abstractmethod
    def length(self) -> int:
        """Length of audio in sample frames, falling-back to 0.

        Notes
        -----
        Zero-length decoders may not be used to load a `Buffer`.
        """

    @abstractmethod
    def seek(self, pos: int) -> bool:
        """Seek to pos, specified in sample frames.

        Return if the seek was successful.
        """

    @getter
    @abstractmethod
    def loop_points(self) -> Tuple[int, int]:
        """Loop points in sample frames.

        Parameters
        ----------
        start : int
            Inclusive starting loop point.
        end : int
            Exclusive starting loop point.

        Notes
        -----
        If `start >= end`, all available samples are included
        in the loop.
        """

    @abstractmethod
    def read(self, count: int) -> bytes:
        """Decode and return `count` sample frames.

        If less than the requested count samples is returned,
        the end of the audio has been reached.
        """


cdef cppclass CppDecoder(alure.BaseDecoder):
    Decoder pyo

    CppDecoder(Decoder decoder):
        this.pyo = decoder

    unsigned get_frequency_() const:
        return pyo.frequency

    alure.ChannelConfig get_channel_config_() const:
        return to_channel_config(pyo.channel_config)

    alure.SampleType get_sample_type_() const:
        return to_sample_type(pyo.sample_type)

    uint64_t get_length_() const:
        return pyo.length

    boolean seek_(uint64_t pos):
        return pyo.seek(pos)

    pair[uint64_t, uint64_t] get_loop_points_() const:
        return pyo.loop_points

    # FIXME: dead-global-interpreter-lock
    # Without GIL Context.update causes segfault.
    unsigned read_(void* ptr, unsigned count) with gil:
        cdef string samples = pyo.read(count)
        memcpy(ptr, samples.c_str(), samples.size())
        return alure.bytes_to_frames(
            samples.size(), get_channel_config_(), get_sample_type_())


cdef class MessageHandler:
    """Message handler interface.

    Applications may derive from this and set an instance on a context
    to receive messages.  The base methods are no-ops, so subclasses
    only need to implement methods for relevant messages.

    Exceptions raised from `MessageHandler` instances are ignored.
    """
    def device_disconnected(self, device: Device) -> None:
        """Handle disconnected device messages.

        This is called when the given device has been disconnected and
        is no longer usable for output.  As per the `ALC_EXT_disconnect`
        specification, disconnected devices remain valid, however all
        playing sources are automatically stopped, any sources that are
        attempted to play will immediately stop, and new contexts may
        not be created on the device.

        Notes
        -----
        Connection status is checked during `Context.update` calls, so
        method must be called regularly to be notified when a device is
        disconnected.  This method may not be called if the device lacks
        support for the `ALC_EXT_disconnect` extension.
        """

    def source_stopped(self, source: Source) -> None:
        """Handle end-of-buffer/stream messages.

        This is called when the given source reaches the end of buffer
        or stream, which is detected upon a call to `Context.update`.
        """

    def source_force_stopped(self, source: Source) -> None:
        """Handle forcefully stopped sources.

        This is called when the given source was forced to stop,
        because of one of the following reasons:

        * There were no more mixing sources and a higher-priority source
          preempted it.
        * `source` is part of a `SourceGroup` (or sub-group thereof)
          that had its `SourceGroup.stop_all` method called.
        * `source` was playing a buffer that's getting removed.
        """

    def buffer_loading(self, name: str, channel_config: str, sample_type: str,
                       sample_rate: int, data: List[int]) -> None:
        """Handle messages from Buffer initialization.

        This is called when a new buffer is about to be created
        and loaded. which may be called asynchronously for buffers
        being loaded asynchronously.

        Parameters
        ----------
        name : str
            Resource name passed to `Buffer`.
        channel_config : str
            Channel configuration of the given audio data.
        sample_type : str
            Sample type of the given audio data.
        sample_rate : int
            Sample rate of the given audio data.
        data : List[int]
            The audio data that is about to be fed to the OpenAL buffer.
        """

    def resource_not_found(self, name: str) -> str:
        """Return the fallback resource for the one of the given name.

        This is called when `name` is not found, allowing substitution
        of a different resource until the returned string either points
        to a valid resource or is empty (default).

        For buffers being cached, the original name will still be used
        for the cache entry so one does not have to keep track of
        substituted resource names.
        """
        return ''


cdef cppclass CppMessageHandler(alure.BaseMessageHandler):
    Context context

    CppMessageHandler(Context ctx):
        this.context = ctx  # Will this be garbage collected?

    void device_disconnected(alure.Device alure_device):
        cdef Device device = Device(None)
        device.impl = alure_device
        context.message_handler.device_disconnected(device)

    void source_stopped(alure.Source alure_source):
        cdef Source source = Source(None)
        source.impl = alure_source
        context.message_handler.source_stopped(source)

    void source_force_stopped(alure.Source alure_source):
        cdef Source source = Source(None)
        source.impl = alure_source
        context.message_handler.source_force_stopped(source)

    void buffer_loading(string name, string channel_config, string sample_type,
                        unsigned sample_rate, vector[signed char] data):
        context.message_handler.buffer_loading(name, channel_config,
                                               sample_type, sample_rate, data)

    string resource_not_found(string name):
        return context.message_handler.resource_not_found(name)


# Helper cdef functions
cdef vector[alure.AttributePair] mkattrs(vector[pair[int, int]] attrs):
    """Convert attribute pairs from Python object to alure format."""
    cdef vector[alure.AttributePair] attributes
    cdef alure.AttributePair pair
    for attribute, value in attrs:
        pair.attribute = attribute
        pair.value = value
        attributes.push_back(pair)  # insert a copy
    pair.attribute = pair.value = 0
    attributes.push_back(pair)  # insert a copy
    return attributes


cdef vector[float] from_vector3(alure.Vector3 v):
    """Convert alure::Vector3 to std::vector of 3 floats."""
    cdef vector[float] result
    for i in range(3): result.push_back(v[i])
    return result


cdef alure.Vector3 to_vector3(vector[float] v):
    """Convert std::vector of 3 floats to alure::Vector3."""
    return alure.Vector3(v[0], v[1], v[2])


cdef alure.SampleType to_sample_type(str name) except +:
    """Return the specified sample type enumeration."""
    if name == 'Unsigned 8-bit':
        return alure.SampleType.UInt8
    elif name == 'Signed 16-bit':
        return alure.SampleType.Int16
    elif name == '32-bit float':
        return alure.SampleType.Float32
    elif name == 'Mulaw':
        return alure.SampleType.Mulaw
    raise ValueError(f'Invalid sample type name: {name}')


cdef alure.ChannelConfig to_channel_config(str name) except +:
    """Return the specified channel configuration enumeration."""
    if name == 'Mono':
        return alure.ChannelConfig.Mono
    elif name == 'Stereo':
        return alure.ChannelConfig.Stereo
    elif name == 'Rear':
        return alure.ChannelConfig.Rear
    elif name == 'Quadrophonic':
        return alure.ChannelConfig.Quad
    elif name == '5.1 Surround':
        return alure.ChannelConfig.X51
    elif name == '6.1 Surround':
        return alure.ChannelConfig.X61
    elif name == '7.1 Surround':
        return alure.ChannelConfig.X71
    elif name == 'B-Format 2D':
        return alure.ChannelConfig.BFormat2D
    elif name == 'B-Format 3D':
        return alure.ChannelConfig.BFormat3D
    raise ValueError(f'Invalid channel configuration name: {name}')
