Audio Devices
=============

.. currentmodule:: palace

Device-Dependent Utilities
--------------------------

.. autoclass:: Device
   :members:

Device-Independent Utilities
----------------------------

.. data:: device_names
   :type: DeviceNames

   Read-only namespace of device names by category (``basic``, ``full`` and
   ``capture``), as tuples of strings whose first item being the default.

.. autofunction:: query_extension
