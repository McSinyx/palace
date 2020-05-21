Decoder Interface
=================

.. currentmodule:: palace

.. autofunction:: decode

.. autoclass:: Decoder
   :members:

.. autoclass:: BaseDecoder
   :members:

.. data:: decoder_factories
   :type: DecoderNamespace

   Simple object for storing decoder factories.

   User-registered factories are tried one after another
   if :py:exc:`RuntimeError` is raised, in lexicographical order.
   Internal decoder factories are always used after registered ones.

.. data:: sample_types
   :type: Tuple[str, ...]

   Names of available sample types.

.. data:: channel_configs
   :type: Tuple[str, ...]

   Names of available channel configurations.

.. autofunction:: sample_size

.. autofunction:: sample_length
