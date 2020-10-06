Adding an Effect
================

.. currentmodule:: palace

This section will focus on how to add effects to the audio.

There are two set of audio effects supported by palace: :py:class:`ReverbEffect`
and :py:class:`ChorusEffect`.

Reverb Effect
-------------

Reverb happens when a sound is reflected and then decay as the sound is absorbed
by the objects in the medium.  :py:class:`ReverbEffect` facilitates such effect.

Creating a reverb effect can be as simple as:

.. code-block:: python

   with ReverbEffect() as effect:
       source.sends[0].effect = effect

:py:attr:`Source.sends` is a collection of send path signals, each of which
contains `effects` and `filter` that describes it.  Here we are only concerned
about the former.

The above code would yield a *generic* reverb effect by default.
There are several other presets that you can use, which are listed
by :py:data:`reverb_preset_names`.  To use these preset, you can simply provide
the preset effect name as the first parameter for the constructor.  For example,
to use `PIPE_LARGE` preset effect, you can initialize the effect like below:

.. code-block:: python

   with ReverbEffect('PIPE_LARGE') as effect:
       source.sends[0].effect = effect

These effects can be modified via their attributes.

.. code-block:: python

   effect.gain = 0.4
   effect.diffusion = 0.65
   late_reverb_pan = 0.2, 0.1, 0.3

The list of these attributes and their constraints can be found
in the documentation of :py:class:`ReverbEffect`.

Chorus Effect
-------------

:py:class:`ChorusEffect` does not have preset effects like
:py:class:`ReverbEffect`, so you would have to initialize the effect attributes
on creation.

There are five parameters to initialize the effect, respectively: waveform,
phase, depth, feedback, and delay.

.. code-block:: python

   with ChorusEffect('sine', 20, 0.4, 0.5, 0.008) as effect:
       source.sends[0].effect = effect

For the constraints of these parameters, please refer to the documentation.
