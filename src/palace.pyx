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
CHANNEL_CONFIG : int
    Context creation key to specify the channel configuration
    (either `MONO`, `STEREO`, `QUAD`, `X51`, `X61` or `X71`).
SAMPLE_TYPE : int
    Context creation key to specify the sample type
    (either `[UNSIGNED_]{BYTE,SHORT,INT}` or `FLOAT`).
FREQUENCY : int
    Context creation key to specify the frequency in hertz.
MONO_SOURCES : int
    Context creation key to specify the number of mono (3D) sources.
STEREO_SOURCES : int
    Context creation key to specify the number of stereo sources.
MAX_AUXILIARY_SENDS : int
    Context creation key to specify the maximum number of
    auxiliary source sends.
HRTF : int
    Context creation key to specify whether to enable HRTF
    (either `FALSE`, `TRUE` or `DONT_CARE`).
HRTF_ID : int
    Context creation key to specify the HRTF to be used.
OUTPUT_LIMITER : int
    Context creation key to specify whether to use a gain limiter
    (either `FALSE`, `TRUE` or `DONT_CARE`).
sample_types : Tuple[str, ...]
    Names of available sample types.
channel_configs : Tuple[str, ...]
    Names of available channel configurations.
device_names : DeviceNames
    Read-only namespace of device names by category (basic, full and
    capture), as tuples of strings whose first item being the default.
distance_models : Tuple[str, ...]
    Names of available distance models.
reverb_preset_names : Tuple[str, ...]
    Names of predefined reverb effect presets in lexicographical order.
decoder_factories : DecoderNamespace
    Simple object for storing decoder factories.

    User-registered factories are tried one after another
    if `RuntimeError` is raised, in lexicographical order.
    Internal decoder factories are always used after registered ones.
"""

__all__ = [
    'FALSE', 'TRUE', 'DONT_CARE', 'FREQUENCY',
    'MONO_SOURCES', 'STEREO_SOURCES', 'MAX_AUXILIARY_SENDS', 'OUTPUT_LIMITER',
    'CHANNEL_CONFIG', 'MONO', 'STEREO', 'QUAD', 'X51', 'X61', 'X71',
    'SAMPLE_TYPE', 'BYTE', 'UNSIGNED_BYTE', 'SHORT', 'UNSIGNED_SHORT',
    'INT', 'UNSIGNED_INT', 'FLOAT', 'HRTF', 'HRTF_ID',
    'sample_types', 'channel_configs', 'device_names',
    'reverb_preset_names', 'decoder_factories', 'distance_models',
    'current_fileio', 'use_fileio', 'query_extension',
    'thread_local', 'current_context', 'use_context',
    'cache', 'free', 'decode', 'sample_size', 'sample_length',
    'Device', 'Context', 'Listener', 'Buffer', 'Source', 'SourceGroup',
    'BaseEffect', 'ReverbEffect', 'ChorusEffect',
    'Decoder', 'BaseDecoder', 'FileIO', 'MessageHandler']

from abc import abstractmethod, ABCMeta
from contextlib import contextmanager
from enum import Enum, auto
from contextlib import contextmanager
from io import DEFAULT_BUFFER_SIZE
from operator import itemgetter
from types import TracebackType
from typing import (Any, Callable, Dict, Iterable, Iterator,
                    List, Optional, Sequence, Tuple, Type)
from warnings import catch_warnings, simplefilter, warn

try:    # Python 3.8+
    from typing import Protocol
except ImportError:
    from abc import ABC as Protocol

from libc.stdint cimport uint64_t   # noqa
from libc.stdio cimport EOF
from libc.string cimport memcpy

from libcpp cimport bool as boolean, nullptr
from libcpp.memory cimport (make_unique, unique_ptr,    # noqa
                            shared_ptr, static_pointer_cast)
from libcpp.string cimport string
from libcpp.utility cimport pair
from libcpp.vector cimport vector
from std cimport istream, milliseconds, streambuf

from cpython.mem cimport PyMem_RawMalloc, PyMem_RawFree
from cpython.ref cimport Py_INCREF, Py_DECREF
from cython.view cimport array

cimport alure   # noqa
from util cimport (     # noqa
    REVERB_PRESETS, SAMPLE_TYPES, CHANNEL_CONFIGS, DISTANCE_MODELS,
    reverb_presets, mkattrs, make_filter, from_vector3, to_vector3)


# Aliases
getter = property   # bypass Cython property hijack
setter = lambda fset: property(fset=fset, doc=fset.__doc__)     # noqa
Vector3: Type = Tuple[float, float, float]

# Cast to Python objects
FALSE: int = alure.ALC_FALSE
TRUE: int = alure.ALC_TRUE
DONT_CARE: int = alure.ALC_DONT_CARE_SOFT

FREQUENCY: int = alure.ALC_FREQUENCY
MONO_SOURCES: int = alure.ALC_MONO_SOURCES
STEREO_SOURCES: int = alure.ALC_STEREO_SOURCES
MAX_AUXILIARY_SENDS: int = alure.ALC_MAX_AUXILIARY_SENDS
OUTPUT_LIMITER: int = alure.ALC_OUTPUT_LIMITER_SOFT

CHANNEL_CONFIG: int = alure.ALC_FORMAT_CHANNELS_SOFT
MONO: int = alure.ALC_MONO_SOFT
STEREO: int = alure.ALC_STEREO_SOFT
QUAD: int = alure.ALC_QUAD_SOFT
X51: int = alure.ALC_5POINT1_SOFT
X61: int = alure.ALC_6POINT1_SOFT
X71: int = alure.ALC_7POINT1_SOFT

SAMPLE_TYPE: int = alure.ALC_FORMAT_TYPE_SOFT
BYTE: int = alure.ALC_BYTE_SOFT
UNSIGNED_BYTE: int = alure.ALC_UNSIGNED_BYTE_SOFT
SHORT: int = alure.ALC_SHORT_SOFT
UNSIGNED_SHORT: int = alure.ALC_UNSIGNED_SHORT_SOFT
INT: int = alure.ALC_INT_SOFT
UNSIGNED_INT: int = alure.ALC_UNSIGNED_INT_SOFT
FLOAT: int = alure.ALC_FLOAT_SOFT

HRTF: int = alure.ALC_HRTF_SOFT
HRTF_ID: int = alure.ALC_HRTF_ID_SOFT

sample_types: Tuple[str, ...] = (
    'Unsigned 8-bit', 'Signed 16-bit', '32-bit float', 'Mulaw')
channel_configs: Tuple[str, ...] = (
    'Mono', 'Stereo', 'Rear', 'Quadrophonic',
    '5.1 Surround', '6.1 Surround', '7.1 Surround',
    'B-Format 2D', 'B-Format 3D')
distance_models: Tuple[str, ...] = (
    'inverse clamped', 'linear clamped', 'exponent clamped',
    'inverse', 'linear', 'exponent', 'none')

# Since multiple calls of DeviceManager.get_instance() will give
# the same instance, we can create module-level variable and expose
# its attributes and methods.  This also prevents the device manager
# from being garbage collected by keeping a reference to the instance.
cdef alure.DeviceManager devmgr = alure.DeviceManager.get_instance()
device_names: DeviceNames = DeviceNames()
cdef boolean _thread = False

reverb_preset_names: Tuple[str, ...] = tuple(reverb_presets())
decoder_factories: DecoderNamespace = DecoderNamespace()
cdef object fileio_factory = None   # type: Optional[Callable[[str], FileIO]]


def sample_size(length: int, channel_config: str, sample_type: str) -> int:
    """Return the size of the given number of sample frames.

    Raises
    ------
    ValueError
        If either channel_config or sample_type is invalid.
    RuntimeError
        If the byte size result too large.
    """
    cdef alure.ChannelConfig alure_channel_config
    cdef alure.SampleType alure_sample_type
    try:
        alure_channel_config = CHANNEL_CONFIGS.at(channel_config)
    except IndexError:
        raise ValueError(f'invalid channel config: {channel_config}') from None
    try:
        alure_sample_type = SAMPLE_TYPES.at(sample_type)
    except IndexError:
        raise ValueError(f'invalid sample type: {sample_type}') from None
    return alure.frames_to_bytes(
        length, alure_channel_config, alure_sample_type)


def sample_length(size: int, channel_config: str, sample_type: str) -> int:
    """Return the number of frames stored in the given byte size.

    Raises
    ------
    ValueError
        If either channel_config or sample_type is invalid.
    """
    cdef alure.ChannelConfig alure_channel_config
    cdef alure.SampleType alure_sample_type
    try:
        alure_channel_config = CHANNEL_CONFIGS.at(channel_config)
    except IndexError:
        raise ValueError(f'invalid channel config: {channel_config}') from None
    try:
        alure_sample_type = SAMPLE_TYPES.at(sample_type)
    except IndexError:
        raise ValueError(f'invalid sample type: {sample_type}') from None
    return alure.bytes_to_frames(size, alure_channel_config, alure_sample_type)


def query_extension(name: str) -> bool:
    """Return if a non-device-specific ALC extension exists.

    See Also
    --------
    Device.query_extension : Query ALC extension on a device
    """
    return devmgr.query_extension(name)


@contextmanager
def thread_local(state: bool) -> Iterator[None]:
    """Return a context manager controlling preference of local thread.

    Effectively, it sets the fallback value for the `thread` argument
    for `current_context` and `use_context`.

    Initially, globally current `Context` is preferred.
    """
    global _thread
    previous, _thread = _thread, state
    try:
        yield
    finally:
        _thread = previous


def current_context(thread: Optional[bool] = None) -> Optional[Context]:
    """Return the context that is currently used.

    If `thread` is set to `True`, return the thread-specific context
    used for OpenAL operations.  This requires the non-device-specific
    as well as the context's device `ALC_EXT_thread_local_context`
    extension to be available.

    In case `thread` is not specified, fallback to preference made by
    `thread_local`.
    """
    cdef Context current = Context.__new__(Context)
    if thread is None: thread = _thread
    if thread:
        current.impl = alure.Context.get_thread_current()
    else:
        current.impl = alure.Context.get_current()
    if not current: return None
    current.device = Device.__new__(Device)
    current.device.impl = current.impl.get_device()
    current.listener = Listener(current)
    return current


def use_context(context: Optional[Context],
                thread: Optional[bool] = None) -> None:
    """Make the specified context current for OpenAL operations.

    This fails silently if the given context has been destroyed.
    In case `thread` is not specified, fallback to preference made by
    `thread_local`.

    If `thread` is `True`, make the context current
    for OpenAL operations on the calling thread only.
    This requires the non-device-specific as well as the context's
    device `ALC_EXT_thread_local_context` extension to be available.
    """
    cdef alure.Context alure_context = <alure.Context> nullptr
    if context: alure_context = (<Context> context).impl
    if thread is None: thread = _thread
    if thread:
        alure.Context.make_thread_current(alure_context)
    else:
        alure.Context.make_current(alure_context)


def cache(names: Iterable[str], context: Optional[Context] = None) -> None:
    """Cache given audio resources asynchronously.

    Duplicate names and buffers already cached are ignored.
    Cached buffers must be freed before destroying the context.

    The resources will be scheduled for caching asynchronously,
    and should be retrieved later when needed by initializing
    `Buffer` corresponding objects.  Resources that cannot be
    loaded, for example due to an unsupported format, will be
    ignored and a later `Buffer` initialization will raise
    an exception.

    If `context` is not given, `current_context()` will be used.

    Raises
    ------
    RuntimeError
        If there is neither any context specified nor current.

    See Also
    --------
    free : Free cached audio resources given their names
    Buffer.destroy : Free the buffer's cache
    """
    cdef vector[string] std_names = list(names)
    cdef vector[alure.StringView] alure_names
    for name in std_names: alure_names.push_back(<alure.StringView> name)
    if context is None: context = current_context()
    if not context: raise RuntimeError('there is no context current')
    (<Context> context).impl.precache_buffers_async(alure_names)


def free(names: Iterable[str], context: Optional[Context] = None) -> None:
    """Free cached audio resources given their names.

    If `context` is not given, `current_context()` will be used.

    Raises
    ------
    RuntimeError
        If there is neither any context specified nor current.
    """
    if context is None: context = current_context()
    if not context: raise RuntimeError('there is no context current')
    cdef alure.Context alure_context = (<Context> context).impl
    # Cython cannot infer collection types yet.
    cdef vector[string] std_names = list(names)
    for name in std_names: alure_context.remove_buffer(name)


def decode(name: str, context: Optional[Context] = None) -> Decoder:
    """Return the decoder created from the given resource name.

    This first tries user-registered decoder factories in
    lexicographical order, then fallback to the internal ones.

    Raises
    ------
    RuntimeError
        If there is neither any context specified nor current.

    See Also
    --------
    decoder_factories : Simple object for storing decoder factories
    """
    def find_resource(name, subst):
        if not name: raise RuntimeError('failed to open file')
        try:
            if fileio_factory is None:
                return open(name, 'rb')
            else:
                return fileio_factory(name)
        except FileNotFoundError:
            return find_resource(subst(name), subst)

    if context is None: context = current_context()
    if not context: raise RuntimeError('there is no context current')
    resource = find_resource(
        name, context.message_handler.resource_not_found)
    for decoder_factory in decoder_factories:
        resource.seek(0)
        try:
            return decoder_factory(resource)
        except RuntimeError:
            continue
    return Decoder(name, context)


def current_fileio() -> Optional[Callable[[str], 'FileIO']]:
    """Return the file I/O factory currently in used by audio decoders.

    If the default is being used, return `None`.
    """
    return fileio_factory


def use_fileio(factory: Optional[Callable[[str], 'FileIO']],
               buffer_size: int = DEFAULT_BUFFER_SIZE) -> None:
    """Set the file I/O factory instance to be used by audio decoders.

    If `factory=None` is provided, revert to the default.
    """
    global fileio_factory
    fileio_factory = factory
    if fileio_factory is None:
        alure.FileIOFactory.set(unique_ptr[alure.FileIOFactory]())
    else:
        alure.FileIOFactory.set(unique_ptr[alure.FileIOFactory](
            new CppFileIOFactory(fileio_factory, buffer_size)))


cdef class DeviceNames:
    """Read-only namespace of device names by category.

    Attributes
    ----------
    basic : Tuple[str, ...]
        Basic device names, with the first one being the default.
    full : Tuple[str, ...]
        Full device names, with the first one being the default.
    capture : Tuple[str, ...]
        Capture device names, with the first one being the default.
    """
    cdef readonly tuple basic
    cdef readonly tuple full
    cdef readonly tuple capture

    def __cinit__(self) -> None:
        cdef list basic = devmgr.enumerate(alure.DeviceEnumeration.Basic)
        default: int = basic.index(devmgr.default_device_name(
            alure.DefaultDeviceType.Basic))
        basic[0], basic[default] = basic[default], basic[0]
        self.basic = tuple(basic)

        cdef list full = devmgr.enumerate(alure.DeviceEnumeration.Full)
        default: int = full.index(devmgr.default_device_name(
            alure.DefaultDeviceType.Full))
        full[0], full[default] = full[default], full[0]
        self.full = tuple(full)

        cdef list capture = devmgr.enumerate(alure.DeviceEnumeration.Capture)
        default: int = capture.index(devmgr.default_device_name(
            alure.DefaultDeviceType.Capture))
        capture[0], capture[default] = capture[default], capture[0]
        self.capture = tuple(capture)

    def __repr__(self) -> str:
        return (f'{self.__class__.__name__}(basic={self.basic},'
                f' full={self.full}, capture={self.capture})')


cdef class Device:
    """Audio mix output, via either a system stream or a hardware port.

    This can be used as a context manager that calls `close` upon
    completion of the block, even if an error occurs.

    Parameters
    ----------
    name : str, optional
        The name of the playback device.
    fallback : Iterable[str], optional
        Device names to fallback to, default to an empty tuple.

    Raises
    ------
    RuntimeError
        If device creation fails.

    Warns
    -----
    RuntimeWarning
        Before each fallback.

    See Also
    --------
    device_names : Available device names
    """
    cdef alure.Device impl

    def __init__(self, name: str = '', fallback: Iterable[str] = ()) -> None:
        names: Tuple[str] = name, *fallback
        message: Optional[str] = None
        for name in names:
            if message is not None:
                with catch_warnings():
                    simplefilter('always')
                    warn(message, category=RuntimeWarning)
            try:
                self.impl = devmgr.open_playback(name)
            except RuntimeError:
                message = f'failed to open device: {name}'
            else:
                return
        raise RuntimeError(message)

    def __enter__(self) -> Device: return self
    def __exit__(self, *exc) -> Optional[bool]: self.close()

    def __lt__(self, other: Any) -> bool:
        if not isinstance(other, Device): return NotImplemented
        return self.impl < (<Device> other).impl

    def __le__(self, other: Any) -> bool:
        if not isinstance(other, Device): return NotImplemented
        return self.impl <= (<Device> other).impl

    def __eq__(self, other: Any) -> bool:
        if not isinstance(other, Device): return NotImplemented
        return self.impl == (<Device> other).impl

    def __ne__(self, other: Any) -> bool:
        if not isinstance(other, Device): return NotImplemented
        return self.impl != (<Device> other).impl

    def __gt__(self, other: Any) -> bool:
        if not isinstance(other, Device): return NotImplemented
        return self.impl > (<Device> other).impl

    def __ge__(self, other: Any) -> bool:
        if not isinstance(other, Device): return NotImplemented
        return self.impl >= (<Device> other).impl

    def __bool__(self) -> bool: return <boolean> self.impl

    def __repr__(self) -> str:
        return f'{self.__class__.__name__}({self.name!r})'

    @getter
    def name(self) -> str:
        """Name of the device."""
        return self.impl.get_name(alure.PlaybackName.Full)

    @getter
    def basic_name(self) -> str:
        """Basic name of the device."""
        return self.impl.get_name(alure.PlaybackName.Basic)

    def query_extension(self, name: str) -> bool:
        """Return if an ALC extension exists on this device.

        See Also
        --------
        query_extension : Query non-device-specific ALC extension
        """
        return self.impl.query_extension(name)

    @getter
    def alc_version(self) -> Tuple[int, int]:
        """ALC version supported by this device."""
        cdef alure.Version version = self.impl.get_alc_version()
        return version.get_major(), version.get_minor()

    @getter
    def efx_version(self) -> Tuple[int, int]:
        """EFX version supported by this device.

        If the `ALC_EXT_EFX` extension is unsupported,
        this will be `(0, 0)`.
        """
        cdef alure.Version version = self.impl.get_efx_version()
        return version.get_major(), version.get_minor()

    @getter
    def frequency(self) -> int:
        """Playback frequency in hertz."""
        return self.impl.get_frequency()

    @getter
    def max_auxiliary_sends(self) -> int:
        """Maximum number of auxiliary source sends.

        If `ALC_EXT_EFX` is unsupported, this will be 0.
        """
        return self.impl.get_max_auxiliary_sends()

    @getter
    def hrtf_names(self) -> List[str]:
        """List of available HRTF names.

        The order is retained from OpenAL, such that the index of
        a given name is the ID to use with `ALC_HRTF_ID_SOFT`.

        If the `ALC_SOFT_HRTF` extension is unavailable,
        this will be an empty list.
        """
        return self.impl.enumerate_hrtf_names()

    @getter
    def hrtf_enabled(self) -> bool:
        """Whether HRTF is enabled on the device.

        If the `ALC_SOFT_HRTF` extension is unavailable,
        this will return False although there could still be
        HRTF applied at a lower hardware level.
        """
        return self.impl.is_hrtf_enabled()

    @getter
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

    @getter
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
    """Container maintaining the audio environment.

    Context contains the environment's settings and components
    such as sources, buffers and effects.

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

    Raises
    ------
    RuntimeError
        If context creation fails.
    """
    cdef alure.Context impl
    cdef alure.Context previous
    cdef readonly Device device
    cdef readonly Listener listener

    def __init__(self, device: Device, attrs: Dict[int, int] = {}) -> None:
        self.impl = device.impl.create_context(mkattrs(attrs.items()))
        self.device = device
        self.listener = Listener(self)
        self.impl.set_message_handler(shared_ptr[alure.MessageHandler](
            new CppMessageHandler(MessageHandler())))

    def __enter__(self) -> Context:
        self.previous = alure.Context.get_current()
        use_context(self)
        return self

    def __exit__(self, *exc) -> Optional[bool]:
        alure.Context.make_current(self.previous)
        self.destroy()

    def __lt__(self, other: Any) -> bool:
        if not isinstance(other, Context): return NotImplemented
        return self.impl < (<Context> other).impl

    def __le__(self, other: Any) -> bool:
        if not isinstance(other, Context): return NotImplemented
        return self.impl <= (<Context> other).impl

    def __eq__(self, other: Any) -> bool:
        if not isinstance(other, Context): return NotImplemented
        return self.impl == (<Context> other).impl

    def __ne__(self, other: Any) -> bool:
        if not isinstance(other, Context): return NotImplemented
        return self.impl != (<Context> other).impl

    def __gt__(self, other: Any) -> bool:
        if not isinstance(other, Context): return NotImplemented
        return self.impl > (<Context> other).impl

    def __ge__(self, other: Any) -> bool:
        if not isinstance(other, Context): return NotImplemented
        return self.impl >= (<Context> other).impl

    def __bool__(self) -> bool: return <boolean> self.impl

    def destroy(self) -> None:
        """Destroy the context.

        The context must not be current when this is called.
        """
        self.impl.destroy()

    def start_batch(self) -> None:
        """Suspend the context to start batching."""
        self.impl.start_batch()

    def end_batch(self) -> None:
        """Continue processing the context and end batching."""
        self.impl.end_batch()

    @property
    def message_handler(self) -> MessageHandler:
        """Handler of some certain events."""
        return static_pointer_cast[CppMessageHandler, alure.MessageHandler](
            self.impl.get_message_handler()).get()[0].pyo

    @message_handler.setter
    def message_handler(self, message_handler: MessageHandler) -> None:
        static_pointer_cast[CppMessageHandler, alure.MessageHandler](
            self.impl.get_message_handler()).get()[0].pyo = message_handler

    @property
    def async_wake_interval(self) -> int:
        """Current interval used for waking up the background thread."""
        return self.impl.get_async_wake_interval().count()

    @async_wake_interval.setter
    def async_wake_interval(self, value: int) -> None:
        self.impl.set_async_wake_interval(milliseconds(value))

    def is_supported(self, channel_config: str, sample_type: str) -> bool:
        """Return if the channel config and sample type is supported.

        This method require the context to be current.

        See Also
        --------
        sample_types : Set of sample types
        channel_configs : Set of channel configurations
        """
        cdef alure.ChannelConfig alure_channel_config
        cdef alure.SampleType alure_sample_type
        try:
            alure_channel_config = CHANNEL_CONFIGS.at(channel_config)
        except IndexError:
            raise ValueError('invalid channel config: '
                             + str(channel_config)) from None
        try:
            alure_sample_type = SAMPLE_TYPES.at(sample_type)
        except IndexError:
            raise ValueError(f'invalid sample type: {sample_type}') from None
        return self.impl.is_supported(alure_channel_config, alure_sample_type)

    @getter
    def available_resamplers(self) -> List[str]:
        """The list of resamplers supported by the context.

        If the `AL_SOFT_source_resampler` extension is unsupported
        this will be an empty list, otherwise there would be
        at least one entry.

        This method require the context to be current.
        """
        cdef alure.ArrayView[string] resamplers
        resamplers = self.impl.get_available_resamplers()
        return [resampler for resampler in resamplers]

    @getter
    def default_resampler_index(self) -> int:
        """The context's default resampler index.

        If the `AL_SOFT_source_resampler` extension is unsupported
        the resampler list will be empty and this will return 0.

        If you try to access the resampler list with this index
        without extension, undefined behavior will occur
        (accessing an out of bounds array index).

        This method require the context to be current.
        """
        return self.impl.get_default_resampler_index()

    @setter
    def doppler_factor(self, value: float) -> None:
        """Factor to apply to all source's doppler calculations."""
        self.impl.set_doppler_factor(value)

    @setter
    def speed_of_sound(self, value: float) -> None:
        """The speed of sound propagation in units per second.

        It is used to calculate the doppler effect along with other
        distance-related time effects.

        The default is 343.3 units per second (a realistic speed
        assuming 1 meter per unit). If this is adjusted for a
        different unit scale, `Listener.meters_per_unit` should
        also be adjusted.
        """
        self.impl.set_speed_of_sound(value)

    @setter
    def distance_model(self, value: str) -> None:
        """The model for source attenuation based on distance.

        The default, 'inverse clamped', provides a realistic l/r
        reduction in volume (that is, every doubling of distance
        cause the gain to reduce by half).

        The clamped distance models restrict the source distance for
        the purpose of distance attenuation, so a source won't sound
        closer than its reference distance or farther than its max
        distance.

        Raises
        ------
        ValueError
            If set to a preset cannot be found in `distance_models`.
        """
        try:
            self.impl.set_distance_model(DISTANCE_MODELS.at(value))
        except IndexError:
            raise ValueError(f'invalid distance model: {value}') from None

    def update(self) -> None:
        """Update the context and all sources belonging to this context."""
        self.impl.update()
        # source_stopped is called outside of alure::Context::update
        # to allow applications to destroy the source on this message.
        handler: MessageHandler = self.message_handler
        while handler.stopped_sources:
            handler.source_stopped(handler.stopped_sources.pop())


cdef class Listener:
    """Listener instance of the given context.

    It is recommended that applications access the listener via
    `Context.listener`, which avoid the overhead caused by the
    creation of the wrapper object.

    Parameters
    ----------
    context : Optional[Context], optional
        The context on which the listener instance is to be created.
        By default `current_context()` is used.

    Raises
    ------
    RuntimeError
        If there is neither any context specified nor current.
    """
    cdef alure.Listener impl

    def __init__(self, context: Optional[Context] = None) -> None:
        if context is None: context = current_context()
        self.impl = (<Context> context).impl.get_listener()

    def __bool__(self) -> bool: return <boolean> self.impl

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
    name : str
        Audio file or resource name.  Multiple calls with the same name
        will return the same buffer.
    context : Optional[Context], optional
        The context from which the buffer is to be created and cached.
        By default `current_context()` is used.

    Attributes
    ----------
    name : str
        Audio file or resource name.

    Raises
    ------
    RuntimeError
        If there is neither any context specified nor current.
    """
    cdef alure.Buffer impl
    cdef Context context
    cdef readonly str name

    def __init__(self, name: str, context: Optional[Context] = None) -> None:
        if context is None: context = current_context()
        if not context: raise RuntimeError('there is no context current')
        self.context, self.name = context, name
        self.impl = self.context.impl.find_buffer(self.name)
        if not self:
            decoder: Decoder = decode(self.name, self.context)
            self.impl = self.context.impl.create_buffer_from(
                self.name, decoder.pimpl)

    def __enter__(self) -> Buffer: return self
    def __exit__(self, *exc) -> Optional[bool]: self.destroy()

    def __lt__(self, other: Any) -> bool:
        if not isinstance(other, Buffer): return NotImplemented
        return self.impl < (<Buffer> other).impl

    def __le__(self, other: Any) -> bool:
        if not isinstance(other, Buffer): return NotImplemented
        return self.impl <= (<Buffer> other).impl

    def __eq__(self, other: Any) -> bool:
        if not isinstance(other, Buffer): return NotImplemented
        return self.impl == (<Buffer> other).impl

    def __ne__(self, other: Any) -> bool:
        if not isinstance(other, Buffer): return NotImplemented
        return self.impl != (<Buffer> other).impl

    def __gt__(self, other: Any) -> bool:
        if not isinstance(other, Buffer): return NotImplemented
        return self.impl > (<Buffer> other).impl

    def __ge__(self, other: Any) -> bool:
        if not isinstance(other, Buffer): return NotImplemented
        return self.impl >= (<Buffer> other).impl

    def __bool__(self) -> bool: return <boolean> self.impl

    def __repr__(self) -> str:
        return f'{self.__class__.__name__}({self.name!r})'

    @staticmethod
    def from_decoder(decoder: Decoder, name: str,
                     context: Optional[Context] = None) -> Buffer:
        """Return a buffer created by reading the given decoder.

        Parameters
        ----------
        decoder : Decoder
            The decoder from which the buffer is to be cached.
        name : str
            The name to give to the buffer.  It may alias an audio file,
            but it must not currently exist in the buffer cache.
        context : Optional[Context], optional
            The context from which the buffer is to be created.
            By default `current_context()` is used.

        Raises
        ------
        RuntimeError
            If there is neither any context specified nor current;
            or if `name` is already used for another buffer.
        """
        if context is None: context = current_context()
        buffer: Buffer = Buffer.__new__(Buffer)
        buffer.context, buffer.name = context, name
        buffer.impl = buffer.context.impl.create_buffer_from(
            buffer.name, decoder.pimpl)
        return buffer

    @getter
    def length(self) -> int:
        """Length of the buffer in sample frames."""
        return self.impl.get_length()

    @getter
    def length_seconds(self) -> float:
        """Length of the buffer in seconds."""
        return self.length / self.frequency

    @getter
    def frequency(self) -> int:
        """Buffer's frequency in hertz."""
        return self.impl.get_frequency()

    @getter
    def channel_config(self) -> str:
        """Buffer's sample configuration."""
        return alure.get_channel_config_name(
            self.impl.get_channel_config())

    @getter
    def sample_type(self) -> str:
        """Buffer's sample type."""
        return alure.get_sample_type_name(
            self.impl.get_sample_type())

    @getter
    def size(self) -> int:
        """Storage size used by the buffer, in bytes.

        Notes
        -----
        The size in bytes may not be what you expect from the length,
        as it may take more space internally than the `channel_config`
        and `sample_type` suggest.
        """
        return self.impl.get_size()

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

    @getter
    def sources(self) -> List[Source]:
        """`Source` objects currently playing the buffer."""
        sources = []
        for alure_source in self.impl.get_sources():
            source: Source = Source.__new__(Source)
            source.impl = alure_source
            sources.append(source)
        return sources

    @getter
    def source_count(self) -> int:
        """Number of sources currently using the buffer.

        Notes
        -----
        `Context.update` needs to be called to reliably ensure the count
        is kept updated for when sources reach their end.  This is
        equivalent to calling `len(self.sources)`.
        """
        return self.impl.get_source_count()

    def destroy(self) -> None:
        """Free the buffer's cache.

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
    context : Optional[Context], optional
        The context from which the source is to be created.
        By default `current_context()` is used.

    Raises
    ------
    RuntimeError
        If there is neither any context specified nor current.
    """
    cdef alure.Source impl

    def __init__(self, context: Optional[Context] = None) -> None:
        if context is None: context = current_context()
        if not context: raise RuntimeError('there is no context current')
        self.impl = (<Context> context).impl.create_source()

    def __enter__(self) -> Source: return self
    def __exit__(self, *exc) -> Optional[bool]: self.destroy()

    def __lt__(self, other: Any) -> bool:
        if not isinstance(other, Source): return NotImplemented
        return self.impl < (<Source> other).impl

    def __le__(self, other: Any) -> bool:
        if not isinstance(other, Source): return NotImplemented
        return self.impl <= (<Source> other).impl

    def __eq__(self, other: Any) -> bool:
        if not isinstance(other, Source): return NotImplemented
        return self.impl == (<Source> other).impl

    def __ne__(self, other: Any) -> bool:
        if not isinstance(other, Source): return NotImplemented
        return self.impl != (<Source> other).impl

    def __gt__(self, other: Any) -> bool:
        if not isinstance(other, Source): return NotImplemented
        return self.impl > (<Source> other).impl

    def __ge__(self, other: Any) -> bool:
        if not isinstance(other, Source): return NotImplemented
        return self.impl >= (<Source> other).impl

    def __bool__(self) -> bool: return <boolean> self.impl

    def stop(self) -> None:
        """Stop playback, releasing the buffer or decoder reference."""
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

    @getter
    def playing(self) -> bool:
        """Whether the source is currently playing."""
        return self.impl.is_playing()

    @getter
    def paused(self) -> bool:
        """Whether the source is currently paused."""
        return self.impl.is_paused()

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
        source_group: SourceGroup = SourceGroup.__new__(SourceGroup)
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

    @getter
    def latency(self) -> int:
        """Source latency in nanoseconds.

        If the `AL_SOFT_source_latency` extension is unsupported,
        the latency will be 0.
        """
        return self.impl.get_sample_offset_latency().second.count()

    @getter
    def offset_seconds(self) -> float:
        """Source offset in seconds.

        For streaming sources this will be the offset based on
        the decoder's read position.
        """
        return self.impl.get_sec_offset().count()

    @getter
    def latency_seconds(self) -> float:
        """Source latency in seconds.

        If the `AL_SOFT_source_latency` extension is unsupported,
        the latency will be 0.
        """
        return self.impl.get_sec_offset_latency().second.count()

    @property
    def looping(self) -> bool:
        """Whether the source should loop.

        The loop points are determined by the playing buffer or decoder.
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
        """The range which the source's gain is clamped to.

        This is used after distance and cone attenuation are applied
        to the gain base and before the adjustments of the filter gain.

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
        """Gain when listener is out of the source's outer cone area.

        Parameters
        ----------
        gain : float
            Linear gain applying to all frequencies, default to 1.
        gain_hf : float
            Linear gain applying extra attenuation to high frequencies
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
        gain, gain_hf = value
        self.impl.set_outer_cone_gains(gain, gain_hf)

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
        """Whether the source's 3D parameters are relative to listener.

        The affected parameters includes `position`, `velocity`,
        and `orientation`.
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
        """Left and right channel angles, in radians.

        The angles go counter-clockwise, with 0 being in front
        and positive values going left.

        This is only used for stereo playback and has no effect
        without the `AL_EXT_STEREO_ANGLES` extension.
        """
        return self.impl.get_stereo_angles()

    @stereo_angles.setter
    def stereo_angles(self, value: Tuple[float, float]) -> None:
        left, right = value
        self.impl.set_stereo_angles(left, right)

    @property
    def spatialize(self) -> Optional[bool]:
        """Whether to enable 3D spatialization.

        Either `True` (the source always has 3D spatialization
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
        """Multiplier for atmospheric high-frequency absorption

        Its value ranging from 0 to 10.  A factor of 1 results in
        a nominal -0.05 dB per meter, with higher values simulating
        foggy air and lower values simulating dryer air; default to 0.
        """
        return self.impl.get_air_absorption_factor()

    @air_absorption_factor.setter
    def air_absorption_factor(self, value: float) -> None:
        self.impl.set_air_absorption_factor(value)

    @property
    def gain_auto(self) -> Tuple[bool, bool, bool]:
        """Whether automatically adjust gains.

        Respectively for direct path's high frequency gain,
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

    @getter
    def sends(self) -> AuxiliarySends:
        """Collection of send path signals.

        Send paths can be retrieved using a nonnegative index, which has
        no effect if not less than the device's `max_auxiliary_sends`.

        Each send path has two write-only descriptors,
        `effect` and `filter`.

        Examples
        --------
        >>> source.sends[0].effect = effect
        >>> source.sends[1].filter = 1, 0.6, 0.9
        """
        return AuxiliarySends(self)

    @setter
    def filter(self, value: Vector3) -> None:
        """Linear gains on the direct path signal, clamped to [0, 1].

        Parameters
        ----------
        gain : float
            Linear gain applying to all frequencies, default to 1.
        gain_hf : float
            Linear gain applying to high frequencies, default to 1.
        gain_lf : float
            Linear gain applying to low frequencies, default to 1.
        """
        gain, gain_hf, gain_lf = value
        self.impl.set_direct_filter(make_filter(gain, gain_hf, gain_lf))

    def destroy(self) -> None:
        """Destroy the source, stop playback and release resources."""
        self.impl.destroy()


cdef class SendPath:
    """Container of write-only descriptors of a send path signal."""
    cdef alure.Source source
    cdef unsigned send

    def __init__(self, source: Source, send: int) -> None:
        self.source = source.impl
        self.send = send

    @setter
    def filter(self, value: Vector3) -> None:
        """Linear gains on the send path signal, clamped to [0, 1].

        Parameters
        ----------
        gain : float
            Linear gain applying to all frequencies, default to 1.
        gain_hf : float
            Linear gain applying to high frequencies, default to 1.
        gain_lf : float
            Linear gain applying to low frequencies, default to 1.
        """
        gain, gain_hf, gain_lf = value
        self.source.set_send_filter(
            self.send, make_filter(gain, gain_hf, gain_lf))

    @setter
    def effect(self, value: BaseEffect) -> None:
        """Effect applied to the send path signal."""
        self.source.set_auxiliary_send(value.slot, self.send)


cdef class AuxiliarySends:
    """Collection of SendPath.

    It is recommended that applications access instances of
    this class via `Source.sends`.  From there, one can get a `SendPath`
    by indexing the object with a nonnegative integer less than
    the device's `max_auxiliary_sends`.
    """
    cdef Source source

    def __init__(self, source: Source) -> None:
        self.source = source

    def __getitem__(self, key: int) -> SendPath:
        if not isinstance(key, int):
            raise TypeError(
                f'integer key expected, got {key.__class__.__name__}')
        try:
            return SendPath(self.source, key)
        except OverflowError:
            raise IndexError(f'index out of range: {key}') from None


cdef class SourceGroup:
    """A group of `Source` references.

    For instance, setting `SourceGroup.gain` to 0.5 will halve the gain
    of all sources in the group.

    This can be used as a context manager that calls `destroy` upon
    completion of the block, even if an error occurs.

    Parameters
    ----------
    context : Optional[Context], optional
        The context from which the source group is to be created.
        By default `current_context()` is used.

    Raises
    ------
    RuntimeError
        If there is neither any context specified nor current.
    """
    cdef alure.SourceGroup impl

    def __init__(self, context: Optional[Context] = None) -> None:
        if context is None: context = current_context()
        if not context: raise RuntimeError('there is no context current')
        self.impl = (<Context> context).impl.create_source_group()

    def __enter__(self) -> SourceGroup: return self
    def __exit__(self, *exc) -> Optional[bool]: self.destroy()

    def __lt__(self, other: Any) -> bool:
        if not isinstance(other, SourceGroup):
            return NotImplemented
        return self.impl < (<SourceGroup> other).impl

    def __le__(self, other: Any) -> bool:
        if not isinstance(other, SourceGroup): return NotImplemented
        return self.impl <= (<SourceGroup> other).impl

    def __eq__(self, other: Any) -> bool:
        if not isinstance(other, SourceGroup): return NotImplemented
        return self.impl == (<SourceGroup> other).impl

    def __ne__(self, other: Any) -> bool:
        if not isinstance(other, SourceGroup): return NotImplemented
        return self.impl != (<SourceGroup> other).impl

    def __gt__(self, other: Any) -> bool:
        if not isinstance(other, SourceGroup): return NotImplemented
        return self.impl > (<SourceGroup> other).impl

    def __ge__(self, other: Any) -> bool:
        if not isinstance(other, SourceGroup): return NotImplemented
        return self.impl >= (<SourceGroup> other).impl

    def __bool__(self) -> bool: return <boolean> self.impl

    @property
    def parent_group(self) -> SourceGroup:
        """The source group this source group is a child of.

        Raises
        ------
        RuntimeException
            If this group is being added to its sub-group
            (i.e. it would create a circular sub-group chain).
        """
        source_group: SourceGroup = SourceGroup.__new__(SourceGroup)
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

    @getter
    def sources(self) -> List[Source]:
        """Sources under this group."""
        sources = []
        for alure_source in self.impl.get_sources():
            source: Source = Source.__new__(Source)
            source.impl = alure_source
            sources.append(source)
        return sources

    @getter
    def sub_groups(self) -> List[SourceGroup]:
        """Source groups under this group."""
        source_groups = []
        for alure_source_group in self.impl.get_sub_groups():
            source_group: SourceGroup = SourceGroup.__new__(SourceGroup)
            source_group.impl = alure_source_group
            source_groups.append(source_group)
        return source_groups

    def pause_all(self) -> None:
        """Pause all currently-playing sources under this group.

        This is done recursively, including sub-groups.
        """
        self.impl.pause_all()

    def resume_all(self) -> None:
        """Resume all currently-playing sources under this group.

        This is done recursively, including sub-groups.
        """
        self.impl.resume_all()

    def stop_all(self) -> None:
        """Stop all currently-playing sources under this group.

        This is done recursively, including sub-groups.
        """
        self.impl.stop_all()

    def destroy(self) -> None:
        """Destroy the source group, remove and free all sources."""
        self.impl.destroy()


cdef class BaseEffect:
    """Base effect processor.

    Instances of this class has no effect (pun intended).

    It takes the output mix of zero or more sources,
    applies DSP for the desired effect, then adds to the output mix.

    This can be used as a context manager that calls `destroy`
    upon completion of the block, even if an error occurs.

    Parameters
    ----------
    context : Optional[Context], optional
        The context from which the effect is to be created.
        By default `current_context()` is used.

    Raises
    ------
    RuntimeError
        If there is neither any context specified nor current.

    See Also
    --------
    ReverbEffect : EAXReverb effect
    ChorusEffect : Chorus effect
    """
    cdef alure.AuxiliaryEffectSlot slot
    cdef alure.Effect impl

    def __init__(self, context: Optional[Context] = None) -> None:
        if context is None: context = current_context()
        if not context: raise RuntimeError('there is no context current')
        cdef alure.Context alure_context = (<Context> context).impl
        self.slot = alure_context.create_auxiliary_effect_slot()
        self.impl = alure_context.create_effect()

    def __enter__(self) -> BaseEffect: return self
    def __exit__(self, *exc) -> Optional[bool]: self.destroy()

    def __lt__(self, other: Any) -> bool:
        if not isinstance(other, BaseEffect): return NotImplemented
        cdef BaseEffect fx = <BaseEffect> other
        return self.slot < fx.slot and self.impl < fx.impl

    def __le__(self, other: Any) -> bool:
        if not isinstance(other, BaseEffect): return NotImplemented
        cdef BaseEffect fx = <BaseEffect> other
        return self.slot <= fx.slot and self.impl <= fx.impl

    def __eq__(self, other: Any) -> bool:
        if not isinstance(other, BaseEffect): return NotImplemented
        cdef BaseEffect fx = <BaseEffect> other
        return self.slot == fx.slot and self.impl == fx.impl

    def __ne__(self, other: Any) -> bool:
        if not isinstance(other, BaseEffect): return NotImplemented
        cdef BaseEffect fx = <BaseEffect> other
        return self.slot != fx.slot and self.impl != fx.impl

    def __gt__(self, other: Any) -> bool:
        if not isinstance(other, BaseEffect): return NotImplemented
        cdef BaseEffect fx = <BaseEffect> other
        return self.slot > fx.slot and self.impl > fx.impl

    def __ge__(self, other: Any) -> bool:
        if not isinstance(other, BaseEffect): return NotImplemented
        cdef BaseEffect fx = <BaseEffect> other
        return self.slot >= fx.slot and self.impl >= fx.impl

    def __bool__(self) -> bool:
        return <boolean> self.slot and <boolean> self.impl

    @setter
    def slot_gain(self, value: float) -> None:
        """Gain of the effect slot."""
        self.slot.set_gain(value)

    @getter
    def source_sends(self) -> List[Tuple[Source, int]]:
        """List of sources using this effect and their pairing sends."""
        source_sends = []
        for source_send in self.slot.get_source_sends():
            source: Source = Source.__new__(Source)
            send = source_send.send
            source.impl = source_send.source
            source_sends.append((source, send))
        return source_sends

    @getter
    def use_count(self):
        """Number of source sends the effect slot is used by.

        This is equivalent to calling `len(self.source_sends)`.
        """
        return self.slot.get_use_count()

    def destroy(self) -> None:
        """Destroy the effect slot, returning it to the system.

        If the effect slot is currently set on a source send,
        it will be removed first.
        """
        self.slot.destroy()
        self.impl.destroy()


cdef class ReverbEffect(BaseEffect):
    """EAXReverb effect.

    It will automatically downgrade to the Standard Reverb effect
    if EAXReverb effect is not supported.

    Parameters
    ----------
    preset : str, optional
        The initial preset to start with, falling back to GENERIC.
    context : Optional[Context], optional
        The context from which the effect is to be created.
        By default `current_context()` is used.

    Raises
    ------
    ValueError
        If the specified preset cannot be found in `reverb_preset_names`.
    RuntimeError
        If there is neither any context specified nor current.
    """
    cdef alure.EFXEAXREVERBPROPERTIES properties

    def __init__(self, preset: str = 'GENERIC',
                 context: Optional[Context] = None) -> None:
        super().__init__(context)
        try:
            self.properties = REVERB_PRESETS.at(preset.upper())
        except IndexError:
            raise ValueError(f'invalid preset name: {preset}') from None
        else:
            self.impl.set_reverb_properties(self.properties)
            self.slot.apply_effect(self.impl)

    @setter
    def send_auto(self, value: bool) -> None:
        """Whether to automatically adjust send slot gains."""
        self.slot.set_send_auto(value)

    @property
    def density(self) -> float:
        """Density, from 0.0 to 1.0."""
        return self.properties.density

    @density.setter
    def density(self, value: float) -> None:
        if value < 0.0 or value > 1.0:
            raise ValueError(f'invalid density: {value}')
        self.properties.density = value
        self.impl.set_reverb_properties(self.properties)
        self.slot.apply_effect(self.impl)

    @property
    def diffusion(self) -> float:
        """Diffusion, from 0.0 to 1.0."""
        return self.properties.diffusion

    @diffusion.setter
    def diffusion(self, value: float) -> None:
        if value < 0.0 or value > 1.0:
            raise ValueError(f'invalid diffusion: {value}')
        self.properties.diffusion = value
        self.impl.set_reverb_properties(self.properties)
        self.slot.apply_effect(self.impl)

    @property
    def gain(self) -> float:
        """Gain, from 0.0 to 1.0."""
        return self.properties.gain

    @gain.setter
    def gain(self, value: float) -> None:
        if value < 0.0 or value > 1.0:
            raise ValueError(f'invalid gain: {value}')
        self.properties.gain = value
        self.impl.set_reverb_properties(self.properties)
        self.slot.apply_effect(self.impl)

    @property
    def gain_hf(self) -> float:
        """High frequency gain, from 0.0 to 1.0."""
        return self.properties.gain_hf

    @gain_hf.setter
    def gain_hf(self, value: float) -> None:
        if value < 0.0 or value > 1.0:
            raise ValueError(f'invalid high frequency gain : {value}')
        self.properties.gain_hf = value
        self.impl.set_reverb_properties(self.properties)
        self.slot.apply_effect(self.impl)

    @property
    def gain_lf(self) -> float:
        """Low frequency gain, from 0.0 to 1.0."""
        return self.properties.gain_lf

    @gain_lf.setter
    def gain_lf(self, value: float) -> None:
        if value < 0.0 or value > 1.0:
            raise ValueError(f'invalid low frequency gain: {value}')
        self.properties.gain_lf = value
        self.impl.set_reverb_properties(self.properties)
        self.slot.apply_effect(self.impl)

    @property
    def decay_time(self) -> float:
        """Decay time, from 0.1 to 20.0."""
        return self.properties.decay_time

    @decay_time.setter
    def decay_time(self, value: float) -> None:
        if value < 0.1 or value > 20.0:
            raise ValueError(f'invalid decay time: {value}')
        self.properties.decay_time = value
        self.impl.set_reverb_properties(self.properties)
        self.slot.apply_effect(self.impl)

    @property
    def decay_hf_ratio(self) -> float:
        """High frequency decay ratio, from 0.1 to 20.0."""
        return self.properties.decay_hf_ratio

    @decay_hf_ratio.setter
    def decay_hf_ratio(self, value: float) -> None:
        if value < 0.1 or value > 20.0:
            raise ValueError(f'invalid high frequency decay ratio: {value}')
        self.properties.decay_hf_ratio = value
        self.impl.set_reverb_properties(self.properties)
        self.slot.apply_effect(self.impl)

    @property
    def decay_lf_ratio(self) -> float:
        """Low frequency decay ratio, from 0.1 to 20.0."""
        return self.properties.decay_lf_ratio

    @decay_lf_ratio.setter
    def decay_lf_ratio(self, value: float) -> None:
        if value < 0.1 or value > 20.0:
            raise ValueError(f'invalid low frequency decay ratio: {value}')
        self.properties.decay_lf_ratio = value
        self.impl.set_reverb_properties(self.properties)
        self.slot.apply_effect(self.impl)

    @property
    def reflections_gain(self) -> float:
        """Reflections gain, from 0.0 to 3.16."""
        return self.properties.reflections_gain

    @reflections_gain.setter
    def reflections_gain(self, value: float) -> None:
        if value < 0.0 or value > 3.16:
            raise ValueError(f'invalid reflections gain: {value}')
        self.properties.reflections_gain = value
        self.impl.set_reverb_properties(self.properties)
        self.slot.apply_effect(self.impl)

    @property
    def reflections_delay(self) -> float:
        """Reflections delay, from 0.0 to 0.3."""
        return self.properties.reflections_delay

    @reflections_delay.setter
    def reflections_delay(self, value: float) -> None:
        if value < 0.0 or value > 0.3:
            raise ValueError(f'invalid reflections delay: {value}')
        self.properties.reflections_delay = value
        self.impl.set_reverb_properties(self.properties)
        self.slot.apply_effect(self.impl)

    @property
    def reflections_pan(self) -> Vector3:
        """Reflections as 3D vector of magnitude between 0 and 1."""
        return self.properties.reflections_pan

    @reflections_pan.setter
    def reflections_pan(self, value: Vector3) -> None:
        x, y, z = value
        magnitude = x*x + y*y + z*z
        if magnitude < 0 or magnitude > 1:
            raise ValueError(f'invalid reflections pan: {value}')
        self.properties.reflections_pan[0] = x
        self.properties.reflections_pan[1] = y
        self.properties.reflections_pan[2] = z
        self.impl.set_reverb_properties(self.properties)
        self.slot.apply_effect(self.impl)

    @property
    def late_reverb_gain(self) -> float:
        """Late reverb gain, from 0.0 to 10.0."""
        return self.properties.late_reverb_gain

    @late_reverb_gain.setter
    def late_reverb_gain(self, value: float) -> None:
        if value < 0.0 or value > 10.0:
            raise ValueError(f'invalid late reverb gain: {value}')
        self.properties.late_reverb_gain = value
        self.impl.set_reverb_properties(self.properties)
        self.slot.apply_effect(self.impl)

    @property
    def late_reverb_delay(self) -> float:
        """Late reverb delay, from 0.0 to 0.1."""
        return self.properties.late_reverb_delay

    @late_reverb_delay.setter
    def late_reverb_delay(self, value: float) -> None:
        if value < 0.0 or value > 0.1:
            raise ValueError(f'invalid late reverb delay: {value}')
        self.properties.late_reverb_delay = value
        self.impl.set_reverb_properties(self.properties)
        self.slot.apply_effect(self.impl)

    @property
    def late_reverb_pan(self) -> Vector3:
        """Late reverb as 3D vector of magnitude between 0 and 1."""
        return self.properties.late_reverb_pan

    @late_reverb_pan.setter
    def late_reverb_pan(self, value: Vector3) -> None:
        x, y, z = value
        magnitude = x*x + y*y + z*z
        if magnitude < 0 or magnitude > 1:
            raise ValueError(f'invalid late reverb pan: {value}')
        self.properties.late_reverb_pan[0] = x
        self.properties.late_reverb_pan[1] = y
        self.properties.late_reverb_pan[2] = z
        self.impl.set_reverb_properties(self.properties)
        self.slot.apply_effect(self.impl)

    @property
    def echo_time(self) -> float:
        """Echo time, from 0.075 to 0.25."""
        return self.properties.echo_time

    @echo_time.setter
    def echo_time(self, value: float) -> None:
        if value < 0.075 or value > 0.25:
            raise ValueError(f'invalid echo time: {value}')
        self.properties.echo_time = value
        self.impl.set_reverb_properties(self.properties)
        self.slot.apply_effect(self.impl)

    @property
    def echo_depth(self) -> float:
        """Echo depth, from 0.0 to 1.0."""
        return self.properties.echo_depth

    @echo_depth.setter
    def echo_depth(self, value: float) -> None:
        if value < 0.0 or value > 1.0:
            raise ValueError(f'invalid echo depth: {value}')
        self.properties.echo_depth = value
        self.impl.set_reverb_properties(self.properties)
        self.slot.apply_effect(self.impl)

    @property
    def modulation_time(self) -> float:
        """Modulation time, from 0.004 to 4.0."""
        return self.properties.modulation_time

    @modulation_time.setter
    def modulation_time(self, value: float) -> None:
        if value < 0.004 or value > 4.0:
            raise ValueError(f'invalid modulation time: {value}')
        self.properties.modulation_time = value
        self.impl.set_reverb_properties(self.properties)
        self.slot.apply_effect(self.impl)

    @property
    def modulation_depth(self) -> float:
        """Modulation depth, from 0.0 to 1.0."""
        return self.properties.modulation_depth

    @modulation_depth.setter
    def modulation_depth(self, value: float) -> None:
        if value < 0.0 or value > 1.0:
            raise ValueError(f'invalid modulation depth: {value}')
        self.properties.modulation_depth = value
        self.impl.set_reverb_properties(self.properties)
        self.slot.apply_effect(self.impl)

    @property
    def air_absorption_gain_hf(self) -> float:
        """High frequency air absorption gain, from 0.892 to 1.0."""
        return self.properties.air_absorption_gain_hf

    @air_absorption_gain_hf.setter
    def air_absorption_gain_hf(self, value: float) -> None:
        if value < 0.892 or value > 1.0:
            raise ValueError(f'invalid high frequency air absorption gain: {value}')
        self.properties.air_absorption_gain_hf = value
        self.impl.set_reverb_properties(self.properties)
        self.slot.apply_effect(self.impl)

    @property
    def hf_reference(self) -> float:
        """High frequency reference, from 1000.0 to 20000.0."""
        return self.properties.hf_reference

    @hf_reference.setter
    def hf_reference(self, value: float) -> None:
        if value < 1000.0 or value > 20000.0:
            raise ValueError(f'invalid high frequency reference: {value}')
        self.properties.hf_reference = value
        self.impl.set_reverb_properties(self.properties)
        self.slot.apply_effect(self.impl)

    @property
    def lf_reference(self) -> float:
        """Low frequency reference, from 20.0 to 1000.0."""
        return self.properties.lf_reference

    @lf_reference.setter
    def lf_reference(self, value: float) -> None:
        if value < 20.0 or value > 1000.0:
            raise ValueError(f'invalid low frequency reference: {value}')
        self.properties.lf_reference = value
        self.impl.set_reverb_properties(self.properties)
        self.slot.apply_effect(self.impl)

    @property
    def room_rolloff_factor(self) -> float:
        """Room rolloff factor, from 0.0 to 10.0."""
        return self.properties.room_rolloff_factor

    @room_rolloff_factor.setter
    def room_rolloff_factor(self, value: float) -> None:
        if value < 0.0 or value > 10.0:
            raise ValueError(f'invalid room rolloff factor: {value}')
        self.properties.room_rolloff_factor = value
        self.impl.set_reverb_properties(self.properties)
        self.slot.apply_effect(self.impl)

    @property
    def decay_hf_limit(self) -> bool:
        """High frequency decay limit."""
        return bool(self.properties.decay_hf_limit)

    @decay_hf_limit.setter
    def decay_hf_limit(self, value: bool) -> None:
        self.properties.decay_hf_limit = bool(value)
        self.impl.set_reverb_properties(self.properties)
        self.slot.apply_effect(self.impl)


cdef class ChorusEffect(BaseEffect):
    """Chorus effect.

    Parameters
    ----------
    waveform : str
        Either 'sine' or 'triangle'.
    phase : int
        From -180 to 180.
    depth : float
        From 0.0 to 1.0.
    feedback : float
        From -1.0 to 1.0.
    delay : float
        From 0.0 to 0.016.
    context : Optional[Context], optional
        The context from which the effect is to be created.
        By default `current_context()` is used.

    Raises
    ------
    RuntimeError
        If there is neither any context specified nor current.
    """
    cdef alure.EFXCHORUSPROPERTIES properties

    def __init__(self, waveform: str = 'triangle',
                 phase: int = 90, depth: float = 0.1,
                 feedback: float = 0.25, delay: float = 0.016,
                 context: Optional[Context] = None) -> None:
        super().__init__(context)
        self.waveform = waveform
        self.phase = phase
        self.depth = depth
        self.feedback = feedback
        self.delay = delay
        self.impl.set_chorus_properties(self.properties)
        self.slot.apply_effect(self.impl)

    @property
    def waveform(self) -> str:
        """Waveform, either 'sine' or 'triangle'."""
        return 'triangle' if self.properties.waveform else 'sine'

    @waveform.setter
    def waveform(self, value: str) -> None:
        if value == 'triangle':
            self.properties.waveform = 1
        elif value == 'sine':
            self.properties.waveform = 0
        else:
            raise ValueError(f'invalid waveform: {value}')
        self.impl.set_chorus_properties(self.properties)
        self.slot.apply_effect(self.impl)

    @property
    def phase(self) -> int:
        """Phase, from -180 to 180."""
        return self.properties.phase

    @phase.setter
    def phase(self, value: int) -> None:
        if value < -180 or value > 180:
            raise ValueError(f'invalid phase: {value}')
        self.properties.phase = value
        self.impl.set_chorus_properties(self.properties)
        self.slot.apply_effect(self.impl)

    @property
    def depth(self) -> float:
        """Depth, from 0.0 to 1.0."""
        return self.properties.depth

    @depth.setter
    def depth(self, value: float) -> None:
        if value < 0.0 or value > 1.0:
            raise ValueError(f'invalid depth: {value}')
        self.properties.depth = value
        self.impl.set_chorus_properties(self.properties)
        self.slot.apply_effect(self.impl)

    @property
    def feedback(self) -> float:
        """Feedback, from -1.0 to 1.0."""
        return self.properties.feedback

    @feedback.setter
    def feedback(self, value: float) -> None:
        if value < -1.0 or value > 1.0:
            raise ValueError(f'invalid feedback: {value}')
        self.properties.feedback = value
        self.impl.set_chorus_properties(self.properties)
        self.slot.apply_effect(self.impl)

    @property
    def delay(self) -> float:
        """Delay, from 0.0 to 0.016."""
        return self.properties.delay

    @delay.setter
    def delay(self, value: float) -> None:
        if value < 0.0 or value > 0.016:
            raise ValueError(f'invalid delay: {value}')
        self.properties.delay = value
        self.impl.set_chorus_properties(self.properties)
        self.slot.apply_effect(self.impl)


cdef class Decoder:
    """Generic audio decoder.

    Parameters
    ----------
    name : str
        Audio file or resource name.
    context : Optional[Context], optional
        The context from which the decoder is to be created.
        By default `current_context()` is used.

    Raises
    ------
    RuntimeError
        If there is neither any context specified nor current.

    See Also
    --------
    Buffer : Preloaded PCM samples coming from a `Decoder`

    Notes
    -----
    Due to implementation details, while this creates decoder objects
    from filenames using contexts, it is the superclass of the ABC
    (abstract base class) `BaseDecoder`.  Because of this, `Decoder`
    may only initialize an internal one.  To use registered factories,
    please call the module-level `decode` function instead.
    """
    cdef shared_ptr[alure.Decoder] pimpl

    def __init__(self, name: str, context: Optional[Context] = None) -> None:
        if context is None: context = current_context()
        if not context: raise RuntimeError('there is no context current')
        self.pimpl = (<Context> context).impl.create_decoder(name)

    @getter
    def frequency(self) -> int:
        """Sample frequency, in hertz, of the audio being decoded."""
        return self.pimpl.get()[0].get_frequency()

    @getter
    def channel_config(self) -> str:
        """Channel configuration of the audio being decoded."""
        return alure.get_channel_config_name(
            self.pimpl.get()[0].get_channel_config())

    @getter
    def sample_type(self) -> str:
        """Sample type of the audio being decoded."""
        return alure.get_sample_type_name(
            self.pimpl.get()[0].get_sample_type())

    @getter
    def length(self) -> int:
        """Length of audio in sample frames, falling-back to 0.

        Notes
        -----
        Zero-length decoders may not be used to load a `Buffer`.
        """
        return self.pimpl.get()[0].get_length()

    @getter
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

    @getter
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
        if ptr == NULL: raise RuntimeError('unable to allocate memory')
        count = self.pimpl.get()[0].read(ptr, count)
        cdef string samples = string(<const char*> ptr, alure.frames_to_bytes(
            count, self.pimpl.get()[0].get_channel_config(),
            self.pimpl.get()[0].get_sample_type()))
        PyMem_RawFree(ptr)
        return samples

    def play(self, chunk_len: int, queue_size: int,
             source: Optional[Source] = None) -> Source:
        """Stream audio asynchronously from the decoder.

        The decoder must NOT have its `read` or `seek` called
        from elsewhere while in use.

        Parameters
        ----------
        chunk_len : int
            The number of sample frames to read for each chunk update.
            Smaller values will require more frequent updates and
            larger values will handle more data with each chunk.
        queue_size : int
            The number of chunks to keep queued during playback.
            Smaller values use less memory while larger values
            improve protection against underruns.
        source : Optional[Source], optional
            The source object to play audio.  If `None` is given,
            a new one will be created from the current context.

        Returns
        -------
        The source used for playing.
        """
        if source is None: source = Source()
        (<Source> source).impl.play(self.pimpl, chunk_len, queue_size)


cdef class _BaseDecoder(Decoder):
    """Cython bridge for BaseDecoder.

    This class is NOT meant to be instantiated.
    """
    def __cinit__(self, *args, **kwargs) -> None:
        self.pimpl = shared_ptr[alure.Decoder](new CppDecoder(self))

    def __init__(self, *args, **kwargs) -> None:
        raise TypeError("cannot instantiate class _BaseDecoder")


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

    __init__(Decoder decoder):
        this.pyo = decoder
        Py_INCREF(pyo)

    __dealloc__():
        Py_DECREF(pyo)

    unsigned get_frequency_() const:
        return pyo.frequency

    alure.ChannelConfig get_channel_config_() const:
        return CHANNEL_CONFIGS.at(pyo.channel_config)

    alure.SampleType get_sample_type_() const:
        return SAMPLE_TYPES.at(pyo.sample_type)

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


cdef class DecoderNamespace:
    """Simple object for storing decoder factories."""
    cdef dict __dict__

    def __repr__(self) -> str:
        decoders: str = ', '.join(
            f'{k}={v}' for k, v in sorted(vars(self).items()))
        return f'{self.__class__.__name__}({decoders})'

    def __iter__(self) -> Iterator[Callable[[FileIO], BaseDecoder]]:
        return map(itemgetter(1), sorted(vars(self).items()))


class FileIO(Protocol):
    """File I/O protocol.

    This static duck type defines methods required to be used by
    palace decoders.  Despite its name, a `FileIO` is not necessarily
    created from a file, but any seekable finite input stream.

    Many classes defined in the standard library module `io`
    are compatible with this protocol.

    Notes
    -----
    Since PEP 544 is only implemented in Python 3.8+, type checking
    for this on earlier Python version might not work as expected.
    """
    @abstractmethod
    def read(self, size: int) -> bytes:
        """Read at most size bytes, returned as bytes."""

    @abstractmethod
    def seek(self, offset: int, whence: int = 0) -> int:
        """Move to new file position and return the file position.

        Parameters
        ----------
        offset : int
            A byte count.
        whence : int, optional
            Either 0 (default, move relative to start of file),
            1 (move relative to current position)
            or 2 (move relative to end of file).
        """

    @abstractmethod
    def close(self) -> None:
        """Close the file."""


cdef cppclass CppStreamBuf(alure.BaseStreamBuf):
    size_t buffer_size
    object pyo  # type: FileIO
    string buffer

    __init__(object fileio, size_t bufsize):
        this.buffer_size = bufsize
        this.pyo = fileio
        Py_INCREF(pyo)

    __dealloc__():
        pyo.close()
        Py_DECREF(pyo)

    size_t seek(long long offset, int whence):
        cdef size_t result = pyo.seek(offset, whence)
        underflow()
        return result

    int underflow():
        this.buffer = pyo.read(buffer_size)
        cdef char* p = <char*> buffer.c_str()
        cdef size_t n = buffer.size()
        setg(p, p, p+n)
        return p[0] if n else EOF


cdef cppclass CppFileIOFactory(alure.BaseFileIOFactory):
    size_t buffer_size
    object pyo  # type: Callable[[str], FileIO]

    __init__(object factory, size_t bufsize):
        this.buffer_size = bufsize
        this.pyo = factory
        Py_INCREF(pyo)

    __dealloc__():
        Py_DECREF(pyo)

    unique_ptr[istream] open_file(const string& name):
        return make_unique[istream](new CppStreamBuf(pyo(name), buffer_size))


cdef class MessageHandler:
    """Message handler interface.

    Applications may derive from this and set an instance on a context
    to receive messages.  The base methods are no-ops, so subclasses
    only need to implement methods for relevant messages.

    Exceptions raised from `MessageHandler` instances are ignored.
    """
    cdef list stopped_sources

    def __cinit__(self, *args, **kwargs) -> None:
        self.stopped_sources = []

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
                       sample_rate: int, data: Sequence[int]) -> None:
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
        data : MutableSequence[int]
            The audio data that is about to be fed to the OpenAL buffer.

            It is a mutable memory array of signed 8-bit integers,
            following Python buffer protocol.
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
    MessageHandler pyo

    __init__(MessageHandler message_handler):
        this.pyo = message_handler
        Py_INCREF(pyo)

    __dealloc__():
        Py_DECREF(pyo)

    void device_disconnected(alure.Device& alure_device):
        cdef Device device = Device.__new__(Device)
        device.impl = alure_device
        pyo.device_disconnected(device)

    void source_stopped(alure.Source& alure_source):
        cdef Source source = Source.__new__(Source)
        source.impl = alure_source
        pyo.stopped_sources.append(source)

    void source_force_stopped(alure.Source& alure_source):
        cdef Source source = Source.__new__(Source)
        source.impl = alure_source
        pyo.source_force_stopped(source)

    void buffer_loading(
        string name, string channel_config, string sample_type,
        unsigned sample_rate, const signed char* data, size_t size) with gil:
        cdef array a = array(shape=(size,), itemsize=sizeof(signed char),
                             format="b", allocate_buffer=False)
        a.data = <char*> data
        pyo.buffer_loading(name, channel_config, sample_type, sample_rate, a)

    string resource_not_found(string name):
        return pyo.resource_not_found(name)
