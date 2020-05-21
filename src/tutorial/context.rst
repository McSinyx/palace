Context Creation
================

.. currentmodule:: palace

A context is an object that allows palace to access OpenAL,
which is essential when you work with palace.  Context maintains
the audio environment and contains environment settings and components
such as sources, buffers, and effects.

Creating a Device Object
------------------------

To create a context, we must first create a device,
since it's a parameter of the context object.

To create an object, well, you just have to instantiate
the :py:class:`Device` class.

.. code-block:: python

   from palace import Device

   with Device() as dev:
       # Your code goes here

This is how you declare a :py:class:`Device` object with the default device.
There can be several devices available, which can be found
in :py:data:`device_names`.

Creating a Context
------------------

Now that we've created a device, we can create the context:

.. code-block:: python

   from palace import Device, Context

   with Device() as dev, Context(dev) as ctx:
       # Your code goes here
