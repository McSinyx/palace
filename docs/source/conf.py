# Configuration file for the Sphinx documentation builder.
#
# This file only contains a selection of the most common options.
# For a full list see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# Project information
project = 'palace'
copyright = '2019, 2020  Nguyễn Gia Phong et al'
author = 'Nguyễn Gia Phong et al.'
release = '0.2.1'

# Add any Sphinx extension module names here, as strings.
# They can be extensions coming with Sphinx (named 'sphinx.ext.*')
# or your custom ones.
extensions = [
    'sphinx.ext.autodoc', 'sphinx.ext.githubpages', 'sphinx.ext.napoleon']
napoleon_google_docstring = False
default_role = 'py:obj'

# Add any paths that contain templates here, relative to this directory.
templates_path = ['templates']

# List of patterns, relative to source directory, that match
# files and directories to ignore when looking for source files.
# This pattern also affects html_static_path and html_extra_path.
exclude_patterns = []

# Options for HTML output
html_theme = 'sphinx_rtd_theme'

# Add any paths that contain custom static files (such as style sheets)
# here, relative to this directory.  They are copied after the builtin
# static files, so a file named "default.css" will overwrite the builtin
# "default.css".
html_static_path = []
