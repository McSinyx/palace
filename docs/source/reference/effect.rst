Environmental Effects
=====================

.. currentmodule:: palace

For the sake of brevity, we only document the constraints of each effect's
properties.  Further details can be found at OpenAL's `Effect Extension Guide`_
which specifies the purpose and usage of each value.

Base Effect
-----------

.. autoclass:: BaseEffect
   :members:

Chorus Effect
-------------

.. autoclass:: ChorusEffect
   :members:

Reverb Effect
-------------

.. data:: reverb_preset_names
   :type: Tuple[str, ...]

   Names of predefined reverb effect presets in lexicographical order.

.. autoclass:: ReverbEffect
   :members:

.. _Effect Extension Guide:
   https://kcat.strangesoft.net/misc-downloads/Effects%20Extension%20Guide.pdf
