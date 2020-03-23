# Cython declarations of alure
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

from libc.stdint cimport int64_t, uint64_t
from libcpp cimport bool as boolean, nullptr_t
from libcpp.memory cimport shared_ptr, unique_ptr
from libcpp.string cimport string
from libcpp.utility cimport pair
from libcpp.vector cimport vector

from std cimport duration, nanoseconds, milliseconds, shared_future, streambuf


# OpenAL and Alure auxiliary declarations
cdef extern from 'alc.h' nogil:
    cdef int ALC_FALSE
    cdef int ALC_TRUE

    cdef int ALC_FREQUENCY

    cdef int ALC_MONO_SOURCES
    cdef int ALC_STEREO_SOURCES


cdef extern from 'efx.h' nogil:
    cdef int ALC_MAX_AUXILIARY_SENDS


cdef extern from 'alure2-alext.h' nogil:
    cdef int ALC_FORMAT_CHANNELS_SOFT
    cdef int ALC_MONO_SOFT
    cdef int ALC_STEREO_SOFT
    cdef int ALC_QUAD_SOFT
    cdef int ALC_5POINT1_SOFT
    cdef int ALC_6POINT1_SOFT
    cdef int ALC_7POINT1_SOFT

    cdef int ALC_FORMAT_TYPE_SOFT
    cdef int ALC_BYTE_SOFT
    cdef int ALC_UNSIGNED_BYTE_SOFT
    cdef int ALC_SHORT_SOFT
    cdef int ALC_UNSIGNED_SHORT_SOFT
    cdef int ALC_INT_SOFT
    cdef int ALC_UNSIGNED_INT_SOFT
    cdef int ALC_FLOAT_SOFT

    cdef int ALC_HRTF_SOFT
    cdef int ALC_DONT_CARE_SOFT
    cdef int ALC_HRTF_ID_SOFT

    cdef int ALC_OUTPUT_LIMITER_SOFT


cdef extern from 'alure2-aliases.h' namespace 'alure' nogil:
    ctypedef duration[double] Seconds


cdef extern from 'alure2-typeviews.h' namespace 'alure' nogil:
    cdef cppclass ArrayView[T]:
        const T* begin() except +
        const T* end() except +


# Alure main module
cdef extern from 'alure2.h' nogil:
    cdef cppclass EFXEAXREVERBPROPERTIES:
        float flDensity
        float flDiffusion
        float flGain
        float flGainHF
        float flGainLF
        float flDecayTime
        float flDecayHFRatio
        float flDecayLFRatio
        float flReflectionsGain
        float flReflectionsDelay
        float flReflectionsPan[3]
        float flLateReverbGain
        float flLateReverbDelay
        float flLateReverbPan[3]
        float flEchoTime
        float flEchoDepth
        float flModulationTime
        float flModulationDepth
        float flAirAbsorptionGainHF
        float flHFReference
        float flLFReference
        float flRoomRolloffFactor
        int   iDecayHFLimit

    cdef cppclass EFXCHORUSPROPERTIES:
        int iWaveform
        int iPhase
        float flRate
        float flDepth
        float flFeedback
        float flDelay


cdef extern from 'alure2.h' namespace 'alure' nogil:
    # Type aliases:
    # char*: string
    # ALbyte: signed char
    # ALfloat: float
    # ALsizei: int
    # ALuint: unsigned
    # Vector: vector
    # ArrayView: vector
    # String: string
    # StringView: string
    # SharedPtr: shared_ptr
    # SharedFuture: shared_future

    # Structs:
    cdef cppclass AttributePair:
        int attribute 'mAttribute'
        int value 'mValue'

    cdef cppclass FilterParams:
        pass

    cdef cppclass SourceSend:
        Source source 'mSource'
        unsigned send 'mSend'

    # Enum classes:
    cdef enum SampleType:
        UInt8   'alure::SampleType::UInt8'      # Unsigned 8-bit
        Int16   'alure::SampleType::Int16'      # Signed 16-bit
        Float32 'alure::SampleType::Float32'    # 32-bit float
        Mulaw   'alure::SampleType::Mulaw'      # Mulaw

    cdef enum ChannelConfig:
        Mono        'alure::ChannelConfig::Mono'        # Mono
        Stereo      'alure::ChannelConfig::Stereo'      # Stereo
        Rear        'alure::ChannelConfig::Rear'        # Rear
        Quad        'alure::ChannelConfig::Quad'        # Quadrophonic
        X51         'alure::ChannelConfig::X51'         # 5.1 Surround
        X61         'alure::ChannelConfig::X61'         # 6.1 Surround
        X71         'alure::ChannelConfig::X71'         # 7.1 Surround
        BFormat2D   'alure::ChannelConfig::BFormat2D'   # B-Format 2D
        BFormat3D   'alure::ChannelConfig::BFormat3D'   # B-Format 3D

    # The following relies on C++ implicit conversion from char* to string.
    cdef const string get_sample_type_name 'GetSampleTypeName'(SampleType) except +
    cdef const string get_channel_config_name 'GetChannelConfigName'(ChannelConfig) except +
    cdef unsigned frames_to_bytes 'FramesToBytes'(unsigned, ChannelConfig, SampleType) except +
    cdef unsigned bytes_to_frames 'BytesToFrames'(unsigned, ChannelConfig, SampleType)

    cdef enum DeviceEnumeration:
        Basic 'alure::DeviceEnumeration::Basic'
        Full 'alure::DeviceEnumeration::Full'
        Capture 'alure::DeviceEnumeration::Capture'

    cdef enum DefaultDeviceType:
        Basic 'alure::DefaultDeviceType::Basic'
        Full 'alure::DefaultDeviceType::Full'
        Capture 'alure::DefaultDeviceType::Capture'

    cdef enum PlaybackName:
        Basic 'alure::PlaybackName::Basic'
        Full 'alure::PlaybackName::Full'

    cdef enum DistanceModel:
        InverseClamped 'alure::DistanceModel::InverseClamped'
        LinearClamped 'alure::DistanceModel::LinearClamped'
        ExponentClamped 'alure::DistanceModel::ExponentClamped'
        Inverse 'alure::DistanceModel::Inverse'
        Linear 'alure::DistanceModel::Linear'
        Exponent 'alure::DistanceModel::Exponent'
        No 'alure::DistanceModel::None'

    cdef enum Spatialize:
        Off 'alure::Spatialize::Off'
        On 'alure::Spatialize::On'
        Auto 'alure::Spatialize::Auto'

    # Helper classes
    cdef cppclass Vector3:
        Vector3()
        Vector3(float, float, float)
        float& operator[](size_t)

    cdef cppclass Version:
        unsigned get_major 'getMajor'()
        unsigned get_minor 'getMinor'()

    # Opaque class implementations:
    cdef cppclass DeviceManagerImpl:
        pass
    cdef cppclass DeviceImpl:
        pass
    cdef cppclass ContextImpl:
        pass
    cdef cppclass ListenerImpl:
        pass
    cdef cppclass BufferImpl:
        pass
    cdef cppclass SourceImpl:
        pass
    cdef cppclass SourceGroupImpl:
        pass
    cdef cppclass AuxiliaryEffectSlotImpl:
        pass
    cdef cppclass EffectImpl:
        pass

    # Available class interfaces:
    cdef cppclass DeviceManager:
        @staticmethod
        DeviceManager get_instance 'getInstance'() except +

        DeviceManager()     # nil
        DeviceManager(const DeviceManager&)
        DeviceManager(DeviceManager&&)

        boolean operator bool()

        boolean query_extension 'queryExtension'(const string&) except +

        vector[string] enumerate(DeviceEnumeration) except +
        string default_device_name 'defaultDeviceName'(DefaultDeviceType) except +

        Device open_playback 'openPlayback'() except +
        Device open_playback 'openPlayback'(const string&) except +

    cdef cppclass Device:
        ctypedef DeviceImpl* handle_type

        Device()    # nil
        Device(DeviceImpl*)
        Device(const Device&)
        Device(Device&&)

        Device& operator=(const Device&)
        Device& operator=(Device&&)

        boolean operator==(const Device&)
        boolean operator!=(const Device&)
        boolean operator<=(const Device&)
        boolean operator>=(const Device&)
        boolean operator<(const Device&)
        boolean operator>(const Device&)

        boolean operator bool()

        handle_type get_handle 'getHandle'()

        string get_name 'getName'() except +
        string get_name 'getName'(PlaybackName) except +

        boolean query_extension 'queryExtension'(const string&) except +

        Version get_alc_version 'getALCVersion'() except +
        Version get_efx_version 'getEFXVersion'() except +

        unsigned get_frequency 'getFrequency'() except +
        unsigned get_max_auxiliary_sends 'getMaxAuxiliarySends'() except +

        vector[string] enumerate_hrtf_names 'enumerateHRTFNames'() except +
        boolean is_hrtf_enabled 'isHRTFEnabled'() except +
        string get_current_hrtf 'getCurrentHRTF'() except +

        void reset(vector[AttributePair]) except +

        Context create_context 'createContext'() except +
        Context create_context 'createContext'(vector[AttributePair]) except +

        void pause_dsp 'pauseDSP'() except +
        void resume_dsp 'resumeDSP'() except +

        nanoseconds get_clock_time 'getClockTime'() except +

        void close() except +

    cdef cppclass Context:
        ctypedef ContextImpl* handle_type

        Context()   # nil
        Context(ContextImpl*)
        Context(const Context&)
        Context(Context&&)

        Context& operator=(const Context&)
        Context& operator=(Context&&)

        boolean operator==(const Context&)
        boolean operator!=(const Context&)
        boolean operator<=(const Context&)
        boolean operator>=(const Context&)
        boolean operator<(const Context&)
        boolean operator>(const Context&)

        boolean operator bool()

        handle_type get_handle 'getHandle'()

        @staticmethod
        void make_current 'MakeCurrent'(Context) except +
        @staticmethod
        Context get_current 'GetCurrent'() except +

        @staticmethod
        void make_thread_current 'MakeThreadCurrent'(Context) except +
        @staticmethod
        Context get_thread_current 'GetThreadCurrent'() except +

        void destroy() except +

        Device get_device 'getDevice'() except +

        void start_batch 'startBatch'() except +
        void end_batch 'endBatch'() except +

        Listener get_listener 'getListener'() except +

        shared_ptr[MessageHandler] set_message_handler 'setMessageHandler'(shared_ptr[MessageHandler]) except +
        shared_ptr[MessageHandler] get_message_handler 'getMessageHandler'() except +

        void set_async_wake_interval 'setAsyncWakeInterval'(milliseconds) except +
        milliseconds get_async_wake_interval 'getAsyncWakeInterval'() except +

        shared_ptr[Decoder] create_decoder 'createDecoder'(string) except +

        boolean is_supported 'isSupported'(ChannelConfig, SampleType) except +

        ArrayView[string] get_available_resamplers 'getAvailableResamplers'() except +
        int get_default_resampler_index 'getDefaultResamplerIndex'() except +

        void precache_buffers_async 'precacheBuffersAsync'(vector[string]) except +

        Buffer create_buffer_from 'createBufferFrom'(string, shared_ptr[Decoder]) except +
        shared_future[Buffer] create_buffer_async_from 'createBufferAsyncFrom'(string, shared_ptr[Decoder]) except +

        Buffer find_buffer 'findBuffer'(string) except +
        shared_future[Buffer] find_buffer_async 'findBufferAsync'(string) except +

        void remove_buffer 'removeBuffer'(string) except +
        void remove_buffer 'removeBuffer'(Buffer) except +

        Source create_source 'createSource'() except +
        AuxiliaryEffectSlot create_auxiliary_effect_slot 'createAuxiliaryEffectSlot'() except +
        Effect create_effect 'createEffect'() except +
        SourceGroup create_source_group 'createSourceGroup'() except +

        void set_doppler_factor 'setDopplerFactor'(float) except +
        void set_speed_of_sound 'setSpeedOfSound'(float) except +
        void set_distance_model 'setDistanceModel'(DistanceModel) except +

        void update() except +

    cdef cppclass Listener:
        ctypedef ListenerImpl* handle_type

        Listener()  # nil
        Listener(ListenerImpl*)
        Listener(const Listener&)
        Listener(Listener&&)

        Listener& operator=(const Listener&)
        Listener& operator=(Listener&&)

        boolean operator==(const Listener&)
        boolean operator!=(const Listener&)
        boolean operator<=(const Listener&)
        boolean operator>=(const Listener&)
        boolean operator<(const Listener&)
        boolean operator>(const Listener&)

        boolean operator bool()

        handle_type get_handle 'getHandle'()

        float set_gain 'setGain'(float) except +
        float set_3d_parameters 'set3DParameters'(const Vector3&, const Vector3&, const Vector3&) except +
        void set_position 'setPosition'(const Vector3 &) except +
        void set_position 'setPosition'(const float*) except +

        void set_velocity 'setVelocity'(const Vector3&) except +
        void set_velocity 'setVelocity'(const float*) except +

        void set_orientation 'setOrientation'(const pair[Vector3, Vector3]&) except +
        void set_orientation 'setOrientation'(const float*, const float*) except +
        void set_orientation 'setOrientation'(const float*) except +

        void set_meters_per_unit 'setMetersPerUnit'(float) except +

    cdef cppclass Buffer:
        ctypedef BufferImpl* handle_type

        Buffer()    # nil
        Buffer(BufferImpl*)
        Buffer(const Buffer&)
        Buffer(Buffer&&)

        Buffer& operator=(const Buffer&)
        Buffer& operator=(Buffer&&)

        boolean operator==(const Buffer&)
        boolean operator!=(const Buffer&)
        boolean operator<=(const Buffer&)
        boolean operator>=(const Buffer&)
        boolean operator<(const Buffer&)
        boolean operator>(const Buffer&)

        boolean operator bool()

        handle_type get_handle 'getHandle'()

        unsigned get_length 'getLength'() except +
        unsigned get_frequency 'getFrequency'() except +
        ChannelConfig get_channel_config 'getChannelConfig'() except +
        SampleType get_sample_type 'getSampleType'() except +
        unsigned get_size 'getSize'() except +
        size_t get_source_count 'getSourceCount'() except +
        vector[Source] get_sources 'getSources'() except +
        # name is implemented as a read-only attribute in Cython
        pair[unsigned, unsigned] get_loop_points 'getLoopPoints'() except +
        void set_loop_points 'setLoopPoints'(unsigned, unsigned) except +

    cdef cppclass Source:
        ctypedef SourceImpl* handle_type

        Source()    # nil
        Source(SourceImpl*)
        Source(const Source&)
        Source(Source&&)

        Source& operator=(const Source&)
        Source& operator=(Source&&)

        boolean operator==(const Source&)
        boolean operator!=(const Source&)
        boolean operator<=(const Source&)
        boolean operator>=(const Source&)
        boolean operator<(const Source&)
        boolean operator>(const Source&)

        boolean operator bool()

        handle_type get_handle 'getHandle'()

        void play(Buffer) except +
        void play(shared_ptr[Decoder], int, int) except +
        void play(shared_future[Buffer]) except +

        void stop() except +
        void fade_out_to_stop 'fadeOutToStop'(float, milliseconds) except +
        void pause() except +
        void resume() except +

        boolean is_pending 'isPending'() except +
        boolean is_playing 'isPlaying'() except +
        boolean is_paused 'isPaused'() except +
        boolean is_playing_or_pending 'isPlayingOrPending'() except +

        void set_group 'setGroup'(SourceGroup) except +
        SourceGroup get_group 'getGroup'() except +

        void set_priority 'setPriority'(unsigned) except +
        unsigned get_priority 'getPriority'() except +

        void set_offset 'setOffset'(uint64_t) except +
        pair[uint64_t, nanoseconds] get_sample_offset_latency 'getSampleOffsetLatency'() except +
        uint64_t get_sample_offset 'getSampleOffset'() except +
        pair[Seconds, Seconds] get_sec_offset_latency 'getSecOffsetLatency'() except +
        Seconds get_sec_offset 'getSecOffset'() except +

        void set_looping 'setLooping'(boolean) except +
        boolean get_looping 'getLooping'() except +

        void set_pitch 'setPitch'(float) except +
        float get_pitch 'getPitch'() except +

        void set_gain 'setGain'(float) except +
        float get_gain 'getGain'() except +
        void set_gain_range 'setGainRange'(float, float) except +
        pair[float, float] get_gain_range 'getGainRange'() except +
        float get_min_gain 'getMinGain'() except +
        float get_max_gain 'getMaxGain'() except +

        void set_distance_range 'setDistanceRange'(float, float) except +
        pair[float, float] get_distance_range 'getDistanceRange'() except +
        float get_reference_distance 'getReferenceDistance'() except +
        float get_max_distance 'getMaxDistance'() except +

        void set_3d_parameters 'set3DParameters'(const Vector3&, const Vector3&, const Vector3&) except +
        void set_3d_parameters 'set3DParameters'(const Vector3&, const Vector3&, const pair[Vector3, Vector3]&) except +

        void set_position 'setPosition'(const Vector3&) except +
        void set_position 'setPosition'(const float*) except +
        Vector3 get_position 'getPosition'() except +

        void set_velocity 'setVelocity'(const Vector3&) except +
        void set_velocity 'setVelocity'(const float*) except +
        Vector3 get_velocity 'getVelocity'() except +

        void set_direction 'setDirection'(const Vector3&) except +
        void set_direction 'setDirection'(const float*) except +
        Vector3 get_direction 'getDirection'() except +

        void set_orientation 'setOrientation'(const pair[Vector3, Vector3]&) except +
        void set_orientation 'setOrientation'(const float*, const float*) except +
        void set_orientation 'setOrientation'(const float*) except +
        pair[Vector3, Vector3] get_orientation 'getOrientation'() except +

        void set_cone_angles 'setConeAngles'(float, float) except +
        pair[float, float] get_cone_angles 'getConeAngles'() except +
        float get_inner_cone_angle 'getInnerConeAngle'() except +
        float get_outer_cone_angle 'getOuterConeAngle'() except +

        void set_outer_cone_gains 'setOuterConeGains'(float) except +
        void set_outer_cone_gains 'setOuterConeGains'(float, float) except +
        pair[float, float] get_outer_cone_gains 'getOuterConeGains'() except +
        float get_outer_cone_gain 'getOuterConeGain'() except +
        float get_outer_cone_gainhf 'getOuterConeGainHF'() except +

        void set_rolloff_factors 'setRolloffFactors'(float) except +
        void set_rolloff_factors 'setRolloffFactors'(float, float) except +
        pair[float, float] get_rolloff_factors 'getRolloffFactors'() except +
        float get_rolloff_factor 'getRolloffFactor'() except +
        float get_room_rolloff_factor 'getRoomRolloffFactor'() except +

        void set_doppler_factor 'setDopplerFactor'(float) except +
        float get_doppler_factor 'getDopplerFactor'() except +

        void set_relative 'setRelative'(boolean) except +
        boolean get_relative 'getRelative'() except +

        void set_radius 'setRadius'(float) except +
        float get_radius 'getRadius'() except +

        void set_stereo_angles 'setStereoAngles'(float, float) except +
        pair[float, float] get_stereo_angles 'getStereoAngles'() except +

        void set_3d_spatialize 'set3DSpatialize'(Spatialize) except +
        Spatialize get_3d_spatialize 'get3DSpatialize'() except +

        void set_resampler_index 'setResamplerIndex'(int) except +
        int get_resampler_index 'getResamplerIndex'() except +

        void set_air_absorption_factor 'setAirAbsorptionFactor'(float) except +
        float get_air_absorption_factor 'getAirAbsorptionFactor'() except +

        void set_gain_auto 'setGainAuto'(boolean, boolean, boolean) except +
        # get_gain_auto
        boolean get_direct_gain_hf_auto 'getDirectGainHFAuto'() except +
        boolean get_send_gain_auto 'getSendGainAuto'() except +
        boolean get_send_gain_hf_auto 'getSendGainHFAuto'() except +

        void set_direct_filter 'setDirectFilter'(const FilterParams&) except +
        void set_send_filter 'setSendFilter'(unsigned, const FilterParams&) except +
        void set_auxiliary_send 'setAuxiliarySend'(AuxiliaryEffectSlot, int) except +
        void set_auxiliary_send_filter 'setAuxiliarySendFilter'(AuxiliaryEffectSlot, int, const FilterParams&) except +

        void destroy() except +

    cdef cppclass SourceGroup:
        ctypedef SourceImpl* handle_type

        SourceGroup()   # nil
        SourceGroup(SourceGroupImpl*)
        SourceGroup(const SourceGroup&)
        SourceGroup(SourceGroup&&)

        SourceGroup& operator=(const SourceGroup&)
        SourceGroup& operator=(SourceGroup&&)

        boolean operator==(const SourceGroup&)
        boolean operator!=(const SourceGroup&)
        boolean operator<=(const SourceGroup&)
        boolean operator>=(const SourceGroup&)
        boolean operator<(const SourceGroup&)
        boolean operator>(const SourceGroup&)

        boolean operator bool()

        handle_type get_handle 'getHandle'()
        void set_parent_group 'setParentGroup'(SourceGroup) except +
        SourceGroup get_parent_group 'getParentGroup'() except +

        vector[Source] get_sources 'getSources'() except +
        vector[SourceGroup] get_sub_groups 'getSubGroups'() except +

        void set_gain 'setGain'(float) except +
        float get_gain 'getGain'() except +

        void set_pitch 'setPitch'(float) except +
        float get_pitch 'getPitch'() except +

        void pause_all 'pauseAll'() except +
        void resume_all 'resumeAll'() except +
        void stop_all 'stopAll'() except +

        void destroy() except +

    cdef cppclass AuxiliaryEffectSlot:
        ctypedef AuxiliaryEffectSlotImpl* handle_type

        AuxiliaryEffectSlot()  # nil
        AuxiliaryEffectSlot(AuxiliaryEffectSlotImpl*)
        AuxiliaryEffectSlot(const AuxiliaryEffectSlot&)
        AuxiliaryEffectSlot(AuxiliaryEffectSlot&&)

        AuxiliaryEffectSlot& operator=(const AuxiliaryEffectSlot&)
        AuxiliaryEffectSlot& operator=(AuxiliaryEffectSlot&&)

        boolean operator==(const AuxiliaryEffectSlot&)
        boolean operator!=(const AuxiliaryEffectSlot&)
        boolean operator<=(const AuxiliaryEffectSlot&)
        boolean operator>=(const AuxiliaryEffectSlot&)
        boolean operator<(const AuxiliaryEffectSlot&)
        boolean operator>(const AuxiliaryEffectSlot&)

        boolean operator bool()

        handle_type get_handle 'getHandle'()

        void set_gain 'setGain'(float) except +
        void set_send_auto 'setSendAuto'(bool) except +
        void apply_effect 'applyEffect'(Effect) except +
        void destroy() except +

        vector[SourceSend] get_source_sends 'getSourceSends'() except +
        size_t get_use_count 'getUseCount'() except +

    cdef cppclass Effect:
        ctypedef EffectImpl* handle_type

        Effect()    # nil
        Effect(EffectImpl*)
        Effect(const Effect&)
        Effect(Effect&&)

        Effect& operator=(const Effect&)
        Effect& operator=(Effect&&)

        boolean operator==(const Effect&)
        boolean operator!=(const Effect&)
        boolean operator<=(const Effect&)
        boolean operator>=(const Effect&)
        boolean operator<(const Effect&)
        boolean operator>(const Effect&)

        boolean operator bool()

        handle_type get_handle 'getHandle'()

        void set_reverb_properties 'setReverbProperties'(const EFXEAXREVERBPROPERTIES&) except +
        void set_chorus_properties 'setChorusProperties'(const EFXCHORUSPROPERTIES&) except +

        void destroy() except +

    cdef cppclass Decoder:
        int get_frequency 'getFrequency'()
        ChannelConfig get_channel_config 'getChannelConfig'()
        SampleType get_sample_type 'getSampleType'()

        uint64_t get_length 'getLength'()
        boolean seek(uint64_t)

        pair[uint64_t, uint64_t] get_loop_points 'getLoopPoints'()

        int read(void*, int)

    cdef cppclass DecoderFactory:
        pass

    cdef cppclass FileIOFactory:
        @staticmethod
        unique_ptr[FileIOFactory] set(unique_ptr[FileIOFactory])
        @staticmethod
        FileIOFactory& get()

    cdef cppclass MessageHandler:
        pass


# GIL is needed for operations with Python objects.
cdef extern from 'bases.h' namespace 'palace':
    cdef cppclass BaseStreamBuf(streambuf):
        pass
    cdef cppclass BaseDecoder(Decoder):
        pass
    cdef cppclass BaseFileIOFactory(FileIOFactory):
        pass
    cdef cppclass BaseMessageHandler(MessageHandler):
        pass
