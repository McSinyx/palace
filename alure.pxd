# Cython declarations of alure
# Copyright (C) 2019, 2020  Nguyễn Gia Phong
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

from libc.stdint cimport uint64_t
from libcpp cimport bool as boolean, nullptr_t
from libcpp.memory cimport shared_ptr
from libcpp.string cimport string
from libcpp.utility cimport pair
from libcpp.vector cimport vector


cdef extern from '<future>' namespace 'std' nogil:
    cdef cppclass shared_future[R]:
        pass


cdef extern from '<alc.h>' nogil:
    cdef int ALC_TRUE


cdef extern from '<AL/alure2-alext.h>' nogil:
    cdef int ALC_HRTF_SOFT
    cdef int ALC_HRTF_ID_SOFT


cdef extern from '<AL/alure2.h>' namespace 'alure' nogil:
    # Type aliases:
    # char*: string
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
        pass


    # Enum classes:
    cdef cppclass SampleType:
        pass
    # The following relies on C++ implicit conversion from char* to string.
    cdef const string get_sample_type_name 'GetSampleTypeName'(SampleType) except +

    cdef cppclass ChannelConfig:
        pass
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

    cdef cppclass DistanceModel:
        pass

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

        DeviceManager()
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

        # get_clock_time

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

        # set_async_wake_interval
        # get_async_wake_interval

        shared_ptr[Decoder] create_decoder 'createDecoder'(string) except +

        boolean is_supported 'isSupported'(ChannelConfig, SampleType) except +

        vector[string] get_available_resamplers 'getAvailableResamplers'() except +
        int get_default_resampler_index 'getDefaultResamplerIndex'() except +

        Buffer get_buffer 'getBuffer'(string) except +
        shared_future[Buffer] get_buffer_async 'getBufferAsync'(string) except +

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
        pass


    cdef cppclass Buffer:
        ctypedef BufferImpl* handle_type

        Buffer()
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
        string get_name 'getName'() except +
        size_t get_source_count 'getSourceCount'() except +
        vector[Source] get_sources 'getSources'() except +
        pair[unsigned, unsigned] get_loop_points 'getLoopPoints'() except +
        void set_loop_points 'setLoopPoints'(unsigned, unsigned) except +


    cdef cppclass Source:
        ctypedef SourceImpl* handle_type

        Source()
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
        # fade_out_to_stop
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
        # get_sample_offset_latency
        uint64_t get_sample_offset 'getSampleOffset'() except +
        # get_sec_offset_latency
        # get_sec_offset

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
        pass


    cdef cppclass AuxiliaryEffectSlot:
        pass


    cdef cppclass Effect:
        pass


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
        pass


    cdef cppclass MessageHandler:
        pass
