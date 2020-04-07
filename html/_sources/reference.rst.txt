Reference
=========

.. currentmodule:: palace

Audio Devices
-------------

.. data:: device_names
   :type: DeviceNames

   Read-only namespace of device names by category (``basic``, ``full`` and
   ``capture``), as tuples of strings whose first item being the default.

.. autofunction:: query_extension

.. autoclass:: Device
   :members:

Audio Library Contexts
----------------------

.. data:: CHANNEL_CONFIG
   :type: int

   Context creation key to specify the channel configuration
   (either ``MONO``, ``STEREO``, ``QUAD``, ``X51``, ``X61`` or ``X71``).

.. data:: SAMPLE_TYPE
   :type: int

   Context creation key to specify the sample type
   (either ``[UNSIGNED_]{BYTE,SHORT,INT}`` or ``FLOAT``).

.. data:: FREQUENCY
   :type: int

   Context creation key to specify the frequency in hertz.

.. data:: MONO_SOURCES
   :type: int

   Context creation key to specify the number of mono (3D) sources.

.. data:: STEREO_SOURCES
   :type: int

   Context creation key to specify the number of stereo sources.

.. data:: MAX_AUXILIARY_SENDS
   :type: int

   Context creation key to specify the maximum number of
   auxiliary source sends.

.. data:: HRTF
   :type: int

   Context creation key to specify whether to enable HRTF
   (either ``FALSE``, ``TRUE`` or ``DONT_CARE``).

.. data:: HRTF_ID
   :type: int

   Context creation key to specify the HRTF to be used.

.. data:: OUTPUT_LIMITER
   :type: int

   Context creation key to specify whether to use a gain limiter
   (either ``FALSE``, ``TRUE`` or ``DONT_CARE``).

.. data:: distance_models
   :type: Tuple[str, ...]

   Names of available distance models.

.. autofunction:: thread_local

.. autofunction:: current_context

.. autofunction:: use_context

.. autoclass:: Context
   :members:

.. autoclass:: Listener
   :members:

.. autoclass:: MessageHandler
   :members:

Resource Caching
----------------

.. autofunction:: cache

.. autofunction:: free

.. autoclass:: Buffer
   :members:

Sources & Source Groups
-----------------------

.. autoclass:: Source
   :members:

.. autoclass:: SourceGroup
   :members:

Environmental Effects
---------------------

.. data:: reverb_preset_names
   :type: Tuple[str, ...]

   Names of predefined reverb effect presets in lexicographical order.

.. autoclass:: Effect
   :members:

Decoder Interface
-----------------

.. data:: sample_types
   :type: Tuple[str, ...]

   Names of available sample types.

.. data:: channel_configs
   :type: Tuple[str, ...]

   Names of available channel configurations.

.. data:: decoder_factories
   :type: DecoderNamespace

   Simple object for storing decoder factories.

   User-registered factories are tried one after another
   if :py:exc:`RuntimeError` is raised, in lexicographical order.
   Internal decoder factories are always used after registered ones.

.. autofunction:: decode

.. autofunction:: sample_size

.. autofunction:: sample_length

.. autoclass:: Decoder
   :members:

.. autoclass:: BaseDecoder
   :members:

File I/O Interface
------------------

.. autofunction:: current_fileio

.. autofunction:: use_fileio

.. autoclass:: FileIO
   :members:
