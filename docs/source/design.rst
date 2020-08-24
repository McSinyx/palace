Design Principles
=================

.. currentmodule:: palace

In this section, we will discuss a few design principles in order to write
a safe, efficient, easy-to-use and extendable 3D audio library for Python,
by wrapping existing functionalities from the C++ API alure_.

This part of the documentation assumes its reader are at least familiar with
Cython, Python and C++11.

.. _impl-idiom:

The Impl Idiom
--------------

*Not to be confused with* `the pimpl idiom`_.

For memory-safety, whenever possible, we rely on Cython for allocation and
deallocation of C++ objects.  To do this, the nullary constructor needs to be
(re-)declared in Cython, e.g.

.. code-block:: cython

   cdef extern from 'foobar.h' namespace 'foobar':
       cdef cppclass Foo:
           Foo()
           float meth(size_t crack) except +
           ...

The Cython extension type can then be declared as follows

.. code-block:: cython

   cdef class Bar:
       cdef Foo impl

       def __init__(self, *args, **kwargs):
           self.impl = ...

       @staticmethod
       def from_baz(baz: Baz) -> Bar:
           bar = Bar.__new__(Bar)
           bar.impl = ...
           return bar

       def meth(self, crack: int) -> float:
           return self.impl.meth(crack)

The Modern Python
-----------------

One of the goal of palace is to create a Pythonic, i.e. intuitive and concise,
interface.  To achieve this, we try to make use of some modern Python features,
which not only allow users to adopt palace with ease, but also make their
programs more readable and less error-prone.

.. _getter-setter:

Property Attributes
^^^^^^^^^^^^^^^^^^^

A large proportion of alure API are getters/setter methods.  In Python,
it is a good practice to use property_ to abstract these calls, and thus make
the interface more natural with attribute-like referencing and assignments.

Due to implementation details, Cython has to hijack the ``@property`` decorator
to make it work for read-write properties.  Unfortunately, the Cython-generated
descriptors do not play very well with other builtin decorators, thus in some
cases, it is recommended to alias the call to ``property`` as follows

.. code-block:: python

   getter = property
   setter = lambda fset: property(fset=fset, doc=fset.__doc__)

Then ``@getter`` and ``@setter`` can be used to decorate read-only and
write-only properties, respectively, without any trouble even if other
decorators are used for the same extension type method.

Context Managers
^^^^^^^^^^^^^^^^

The alure API defines many objects that need manual tear-down in
a particular order.  Instead of trying to be clever and perform automatic
clean-ups at garbage collection, we should put the user in control.
To quote *The Zen of Python*,

   | If the implementation is hard to explain, it's a bad idea.
   | If the implementation is easy to explain, it may be a good idea.

With that being said, it does not mean we do not provide any level of
abstraction.  A simplified case in point would be

.. code-block:: cython

   cdef class Device:
       cdef alure.Device impl

       def __init__(self, name: str = '') -> None:
           self.impl = devmgr.open_playback(name)

       def __enter__(self) -> Device:
           return self

       def __exit__(self, *exc) -> Optional[bool]:
           self.close()

       def close(self) -> None:
           self.impl.close()

Now if the ``with`` statement is used, it will make sure the device
will be closed, regardless of whatever may happen within the inner block

.. code-block:: python

   with Device() as dev:
       ...

as it is equivalent to

.. code-block:: python

   dev = Device()
   try:
       ...
   finally:
       dev.close()

Other than closure/destruction of objects, typical uses of `context managers`__
also include saving and restoring various kinds of global state (as seen in
:py:class:`Context`), locking and unlocking resources, etc.

__ https://docs.python.org/3/reference/datamodel.html#context-managers

The Double Reference
--------------------

While wrapping C++ interfaces, :ref:`the impl idiom <impl-idiom>` might not
be adequate, since the derived Python methods need to be callable from C++.
Luckily, Cython can handle Python objects within C++ classes just fine,
although we'll need to handle the reference count ourselves, e.g.

.. code-block:: cython

   cdef cppclass CppDecoder(alure.BaseDecoder):
       Decoder pyo

       __init__(Decoder decoder):
           this.pyo = decoder
           Py_INCREF(pyo)

       __dealloc__():
           Py_DECREF(pyo)

       bool seek(uint64_t pos):
           return pyo.seek(pos)

With this being done, we can now write the wrapper as simply as

.. code-block:: cython

   cdef class BaseDecoder:
       cdef shared_ptr[alure.Decoder] pimpl

       def __cinit__(self, *args, **kwargs) -> None:
           self.pimpl = shared_ptr[alure.Decoder](new CppDecoder(self))

       def seek(pos: int) -> bool:
           ...

Because ``__cinit__`` is called by ``__new__``, any Python class derived
from ``BaseDecoder`` will be exposed to C++ as an attribute of ``CppDecoder``.
Effectively, this means the users can have the alure API calling their
inherited Python object as naturally as if palace is implemented in pure Python.

In practice, :py:class:`BaseDecoder` will also need to take into account
other guarding mechanisms like :py:class:`abc.ABC`.  Due to Cython limitations,
implementation as a pure Python class and :ref:`aliasing <getter-setter>` of
``@getter``/``@setter`` should be considered.

.. _alure: https://github.com/kcat/alure
.. _`the pimpl idiom`: https://wiki.c2.com/?PimplIdiom
.. _property:  https://docs.python.org/3/library/functions.html#property
