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

from std cimport duration, nanoseconds, milliseconds, streambuf


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

    cdef cppclass StringView:
        StringView(string) except +


# Alure main module
cdef extern from 'alure2.h' nogil:
    cdef cppclass EFXEAXREVERBPROPERTIES:
        float density 'flDensity'
        float diffusion 'flDiffusion'
        float gain 'flGain'
        float gain_hf 'flGainHF'
        float gain_lf 'flGainLF'
        float decay_time 'flDecayTime'
        float decay_hf_ratio 'flDecayHFRatio'
        float decay_lf_ratio 'flDecayLFRatio'
        float reflections_gain 'flReflectionsGain'
        float reflections_delay 'flReflectionsDelay'
        float reflections_pan 'flReflectionsPan'[3]
        float late_reverb_gain 'flLateReverbGain'
        float late_reverb_delay 'flLateReverbDelay'
        float late_reverb_pan 'flLateReverbPan'[3]
        float echo_time 'flEchoTime'
        float echo_depth 'flEchoDepth'
        float modulation_time 'flModulationTime'
        float modulation_depth 'flModulationDepth'
        float air_absorption_gain_hf 'flAirAbsorptionGainHF'
        float hf_reference 'flHFReference'
        float lf_reference 'flLFReference'
        float room_rolloff_factor 'flRoomRolloffFactor'
        int decay_hf_limit 'iDecayHFLimit'

    cdef cppclass EFXCHORUSPROPERTIES:
        int waveform 'iWaveform'
        int phase 'iPhase'
        float rate 'flRate'
        float depth 'flDepth'
        float feedback 'flFeedback'
        float delay 'flDelay'


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

    # Structs:
    cdef cppclass AttributePair:
        pass
    cdef cppclass FilterParams:
        pass

    cdef cppclass SourceSend:
        Source source 'mSource'
        unsigned send 'mSend'

    # Enum classes:
    cdef enum SampleType:
        pass
    cdef enum ChannelConfig:
        pass

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
        DeviceManager()     # nil
        boolean operator bool()

        boolean query_extension 'queryExtension'(const string&) except +
        vector[string] enumerate(DeviceEnumeration) except +
        string default_device_name 'defaultDeviceName'(DefaultDeviceType) except +
        Device open_playback 'openPlayback'(const string&) except +

    cdef cppclass Device:
        Device()    # nil
        boolean operator==(const Device&)
        boolean operator!=(const Device&)
        boolean operator<=(const Device&)
        boolean operator>=(const Device&)
        boolean operator<(const Device&)
        boolean operator>(const Device&)
        boolean operator bool()

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
        Context()   # nil
        boolean operator==(const Context&)
        boolean operator!=(const Context&)
        boolean operator<=(const Context&)
        boolean operator>=(const Context&)
        boolean operator<(const Context&)
        boolean operator>(const Context&)
        boolean operator bool()

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

        void precache_buffers_async 'precacheBuffersAsync'(vector[StringView]) except +
        Buffer create_buffer_from 'createBufferFrom'(string, shared_ptr[Decoder]) except +
        Buffer find_buffer 'findBuffer'(string) except +
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
        Listener()  # nil
        boolean operator bool()

        float set_gain 'setGain'(float) except +
        void set_position 'setPosition'(const Vector3 &) except +
        void set_velocity 'setVelocity'(const Vector3&) except +
        void set_orientation 'setOrientation'(const pair[Vector3, Vector3]&) except +
        void set_meters_per_unit 'setMetersPerUnit'(float) except +

    cdef cppclass Buffer:
        Buffer()    # nil
        boolean operator==(const Buffer&)
        boolean operator!=(const Buffer&)
        boolean operator<=(const Buffer&)
        boolean operator>=(const Buffer&)
        boolean operator<(const Buffer&)
        boolean operator>(const Buffer&)
        boolean operator bool()

        unsigned get_length 'getLength'() except +
        unsigned get_frequency 'getFrequency'() except +
        ChannelConfig get_channel_config 'getChannelConfig'() except +
        SampleType get_sample_type 'getSampleType'() except +
        unsigned get_size 'getSize'() except +
        size_t get_source_count 'getSourceCount'() except +
        vector[Source] get_sources 'getSources'() except +
        pair[unsigned, unsigned] get_loop_points 'getLoopPoints'() except +
        void set_loop_points 'setLoopPoints'(unsigned, unsigned) except +

    cdef cppclass Source:
        Source()    # nil
        boolean operator==(const Source&)
        boolean operator!=(const Source&)
        boolean operator<=(const Source&)
        boolean operator>=(const Source&)
        boolean operator<(const Source&)
        boolean operator>(const Source&)
        boolean operator bool()

        void play(Buffer) except +
        void play(shared_ptr[Decoder], int, int) except +

        void stop() except +
        void fade_out_to_stop 'fadeOutToStop'(float, milliseconds) except +
        void pause() except +
        void resume() except +

        boolean is_playing 'isPlaying'() except +
        boolean is_paused 'isPaused'() except +

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

        void set_distance_range 'setDistanceRange'(float, float) except +
        pair[float, float] get_distance_range 'getDistanceRange'() except +

        void set_position 'setPosition'(const Vector3&) except +
        Vector3 get_position 'getPosition'() except +

        void set_velocity 'setVelocity'(const Vector3&) except +
        Vector3 get_velocity 'getVelocity'() except +

        void set_direction 'setDirection'(const Vector3&) except +
        Vector3 get_direction 'getDirection'() except +

        void set_orientation 'setOrientation'(const pair[Vector3, Vector3]&) except +
        pair[Vector3, Vector3] get_orientation 'getOrientation'() except +

        void set_cone_angles 'setConeAngles'(float, float) except +
        pair[float, float] get_cone_angles 'getConeAngles'() except +

        void set_outer_cone_gains 'setOuterConeGains'(float, float) except +
        pair[float, float] get_outer_cone_gains 'getOuterConeGains'() except +

        void set_rolloff_factors 'setRolloffFactors'(float, float) except +
        pair[float, float] get_rolloff_factors 'getRolloffFactors'() except +

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
        SourceGroup()   # nil
        boolean operator==(const SourceGroup&)
        boolean operator!=(const SourceGroup&)
        boolean operator<=(const SourceGroup&)
        boolean operator>=(const SourceGroup&)
        boolean operator<(const SourceGroup&)
        boolean operator>(const SourceGroup&)
        boolean operator bool()

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
        AuxiliaryEffectSlot()  # nil
        boolean operator==(const AuxiliaryEffectSlot&)
        boolean operator!=(const AuxiliaryEffectSlot&)
        boolean operator<=(const AuxiliaryEffectSlot&)
        boolean operator>=(const AuxiliaryEffectSlot&)
        boolean operator<(const AuxiliaryEffectSlot&)
        boolean operator>(const AuxiliaryEffectSlot&)
        boolean operator bool()

        void set_gain 'setGain'(float) except +
        void set_send_auto 'setSendAuto'(bool) except +
        void apply_effect 'applyEffect'(Effect) except +
        void destroy() except +

        vector[SourceSend] get_source_sends 'getSourceSends'() except +
        size_t get_use_count 'getUseCount'() except +

    cdef cppclass Effect:
        Effect()    # nil
        boolean operator==(const Effect&)
        boolean operator!=(const Effect&)
        boolean operator<=(const Effect&)
        boolean operator>=(const Effect&)
        boolean operator<(const Effect&)
        boolean operator>(const Effect&)
        boolean operator bool()

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
