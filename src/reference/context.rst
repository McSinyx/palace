Audio Library Contexts
======================

.. currentmodule:: palace

Context and Auxiliary Classes
-----------------------------

.. autoclass:: Context
   :members:

.. autoclass:: Listener
   :members:

.. autoclass:: MessageHandler
   :members:

Using Contexts
--------------

.. autofunction:: use_context

.. autofunction:: current_context

.. autofunction:: thread_local

Context Creation Attributes
---------------------------

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
