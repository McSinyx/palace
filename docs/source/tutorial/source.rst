Source Manipulation
===================

.. currentmodule:: palace

We have created a source in the last section.
As said previously, its properties can be manipulated to create wanted effects.

Moving the Source
-----------------

Changing :py:attr:`Source.position` is one of the most noticeable,
but first, we have to enable spatialization via :py:attr:`Source.spatialize`.

.. code-block:: python

   from time import sleep
   from palace import Device, Context, Source, decode

   with Device() as device, Context(device) as context, Source() as source:
       source.spatialize = True
       decoder = decode('some_audio.ogg')
       decoder.play(12000, 4, source)
       while source.playing:
           sleep(0.025)
           context.update()

Now, we can set the position of the source in this virtual 3D space.
The position is a 3-tuple indicating the coordinate of the source.
The axes are aligned according to the normal coordinate system:

- The x-axis goes from left to right
- The y-axis goes from below to above
- The z-axis goes from front to back

For example, this will set the source above the listener::

   src.position = 0, 1, 0

.. note::

   For this too work for stereo, you have to have HRTF enabled.
   You can check that via :py:attr:`Device.current_hrtf`.

You can as well use a function to move the source automatically by writing
a function that generate positions.  A simple example is circular motion.

.. code-block:: python

   from itertools import takewhile, count
   ...
   for i in takewhile(src.playing, count(step=0.025)):
       source.position = sin(i), 0, cos(-i)
       ...

A more well-written example of this can be found `in our repository`_.

Speed and Pitch
---------------

Modifying :py:attr:`pitch` changes the playing speed, effectively changing
pitch.  Pitch can be any positive number.

.. code-block:: python

   src.pitch = 2    # high pitch
   src.pitch = 0.4  # low pitch

Air Absorption Factor
---------------------

:py:attr:`Source.air_absorption_factor` simulates atmospheric high-frequency
air absorption. Higher values simulate foggy air and lower values simulate
drier air.

.. code-block:: python

   src.air_absorption_factor = 9  # very high humidity
   src.air_absorption_factor = 0  # dry air (default)

.. _in our repository:
   https://github.com/McSinyx/palace/blob/master/examples/palace-hrtf.py
