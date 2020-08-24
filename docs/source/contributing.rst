Getting Involved
================

.. note:: The development of palace is carried out on GitHub_.
   Since GitHub is not free software, we fully understand
   if one does not want to register an account just to participate
   in our development.  Therefore, we also welcome patches
   and bug reports sent via email.

First of all, thank you for using and contributing to palace!  We welcome
all forms of contribution, and `the mo the merier`_.  By saying this, we also
mean that we much prefer receiving many small and self-contained bug reports,
feature requests and patches than a giant one.  There is no limit for
the number of contributions one may or should make.  While it may seem
appealing to be able to dump all thoughts and feelings into one ticket,
it would be more difficult for us to keep track of the progress.

Reporting a Bug
---------------

Before filing a bug report, please make sure that the bug has not been
already reported by searching our GitHub Issues_ tracker.

To facilitate the debugging process, a bug report should at least contain
the following information:

#. The platform, the CPython version and the compiler used to build it.
   These can be obtained from :py:func:`platform.platform`,
   :py:func:`platform.python_version` and :py:func:`platform.python_compiler`,
   respectively.
#. The version of palace and how you installed it.
   The earlier is usually provided by ``pip show palace``.
#. Detailed instructions on how to reproduce the bug,
   for example a short Python script would be appreciated.

Requesting a Feature
--------------------

Prior to filing a feature request, please make sure that the feature
has not been already reported by searching our GitHub Issues_ tracker.

Please only ask for features that you (or an incapacitated friend
you can personally talk to) require.  Do not request features because
they seem like a good idea.  If they are really useful, they will be
requested by someone who requires them.

Submitting a Patch
------------------

We accept all kinds of patches, from documentation and CI/CD setup
to bug fixes, feature implementations and tests.  These are hosted on GitHub
and one may create a local repository by running::

   git clone https://github.com/McSinyx/palace

While the patch can be submitted via email, it is preferable to file
a pull request on GitHub against the ``master`` branch to allow more people
to review it, since we do not have any mail list.  Either way, contributors
must have legal permission to distribute the code and it must be available
under `LGPLv3+`_.  Furthermore, each contributor retains the copyrights
of their patch, to ensure that the licence can never be revoked even if
others wants to.  It is advisable that the author list per legal name
under the copyright header of each source file they modify, like so::

   Copyright (C) 2038  Foo Bar

Using GitHub
^^^^^^^^^^^^

#. Create a fork_ of our repository on GitHub.
#. Checkout the source code and (optionally) add the ``upstream`` remote::

      git clone https://github.com/YOUR_GITHUB_USERNAME/palace
      cd palace
      git remote add upstream https://github.com/McSinyx/palace

#. Start working on your patch and make sure your code complies with
   the `Style Guidelines`_ and passes the test suit run by tox_.
#. Add relevant tests to the patch and work on it until they all pass.
   In case one is only modifying tests, perse may install palace using
   ``CYTHON_TRACE=1 pip install .`` then run pytest_ directly to avoid
   having to build the extension module multiple times.
#. Update the copyright notices of the files you modified.
   Palace is collectively licensed under `LGPLv3+`_,
   and to protect the freedom of the users,
   copyright holders need to be properly documented.
#. Add_, commit_ with `a great message`_ then push_ the result.
#. Finally, `create a pull request`_.  We will then review and merge it.

It is recommended to create a new branch in your fork
(``git checkout -c what-you-are-working-on``) instead of working directly
on ``master``.  This way one can still sync per fork with our ``master`` branch
and ``git pull --rebase upstream master`` to avoid integration issues.

Via Email
^^^^^^^^^

#. Checkout the source code::

      git clone https://github.com/McSinyx/palace
      cd palace

#. Work on your patch with tests and copyright notice included
   as described above.
#. `git-format-patch`_ and send it to one of the maintainers
   (our emails addresses are available under ``git log``).
   We will then review and merge it.

In any case, thank you very much for your contributions!

Making a Release
----------------

While this is meant for developers doing a palace release, contributors wishing
to improve the CI/CD may find it helpful.

#. Under the local repository, checkout the ``master`` branch
   and sync with the one on GitHub using ``git pull``.
#. Bump the version in ``setup.cfg`` and push to GitHub.
#. Create a source distribution by running ``setup.py sdist``.
   The distribution generated by this command is now referred to as ``sdist``.
#. Using twine_, upload the ``sdist`` to PyPI via ``twine upload $sdist``.
#. On GitHub, tag a new release with the ``sdist`` attached.
   In the release note, make sure to include all user-facing changes
   since the previous release.  This will trigger the CD services
   to build the wheels and publish them to PyPI.
#. Wait for the wheel for your platform to arrive to PyPI and install it.
   Play around with it for a little to make sure that everything is OK.

Style Guidelines
----------------

Python and Cython
^^^^^^^^^^^^^^^^^

Generally, palace follows :pep:`8` and :pep:`257`,
with the following preferences and exceptions:

* Hanging indentation is *always* preferred,
  where continuation lines are indented by 4 spaces.
* Comments and one-line docstrings are limited to column 79
  instead of 72 like for multi-line docstrings.
* Cython extern declarations need not follow the 79-character limit.
* Break long lines before a binary operator.
* Use form feeds sparingly to break long modules
  into pages of relating functions and classes.
* Prefer single-quoted strings over double-quoted strings,
  unless the string contains single quote characters.
* Avoid trailing commas at all costs.
* Line breaks within comments and docstrings should not cut a phrase in half.
* Everything deserves a docstring.  Palace follows numpydoc_ which support
  documenting attributes as well as constants and module-level variables.
  In additional to docstrings, type annotations should be employed
  for all public names.
* Use numpydoc_ markups moderately to keep docstrings readable as plain text.

C++
^^^

C++ codes should follow GNU style, which is best documented at Octave_.

reStructuredText
^^^^^^^^^^^^^^^^

In order for reStructuredText to be rendered correctly, the body of
constructs beginning with a marker (lists, hyperlink targets, comments, etc.)
must be aligned relative to the marker.  For this reason, it is convenient
to set your editor indentation level to 3 spaces, since most constructs
starts with two dots and a space.  However, be aware of that bullet items
require 2-space alignment and other exceptions.

Limit all lines to a maximum of 79 characters.  Similar to comments
and docstrings, phrases should not be broken in the middle.
The source code of this guide itself is a good example on how line breaks
should be handled.  Additionally, two spaces should also be used
after a sentence-ending period in multi-sentence paragraph,
except after the final sentence.

.. _GitHub: https://github.com/McSinyx/palace
.. _the mo the merier:
   https://www.phrases.org.uk/meanings/the-more-the-merrier.html
.. _Issues: https://github.com/McSinyx/palace/issues
.. _LGPLv3+: https://www.gnu.org/licenses/lgpl-3.0.en.html
.. _fork: https://github.com/McSinyx/palace/fork
.. _tox: https://tox.readthedocs.io/en/latest/
.. _pytest: https://docs.pytest.org/en/latest/
.. _Add: https://git-scm.com/docs/git-add
.. _commit: https://git-scm.com/docs/git-commit
.. _a great message: https://chris.beams.io/posts/git-commit/#seven-rules
.. _push: https://git-scm.com/docs/git-push
.. _create a pull request:
   https://help.github.com/articles/creating-a-pull-request
.. _git-format-patch: https://git-scm.com/docs/git-format-patch
.. _twine: https://twine.readthedocs.io/en/latest/
.. _numpydoc: https://numpydoc.readthedocs.io/en/latest/format.html
.. _Octave: https://wiki.octave.org/C%2B%2B_style_guide
