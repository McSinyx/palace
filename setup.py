#!/usr/bin/env python3
# setup script
# Copyright (C) 2019, 2020  Nguyễn Gia Phong
#
# This file is part of palace.
#
# palace is free software: you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published
# by the Free Software Foundation, either version 3 of the License,
# or (at your option) any later version.
#
# palace is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with palace.  If not, see <https://www.gnu.org/licenses/>.

import re
from distutils.dir_util import mkpath
from distutils.file_util import copy_file
from operator import methodcaller
from os import environ
from os.path import dirname, join
from subprocess import DEVNULL, PIPE, run

from Cython.Build import cythonize
from setuptools import setup, Extension
from setuptools.command.build_ext import build_ext

try:
    TRACE = int(environ['CYTHON_TRACE'])
except KeyError:
    TRACE = 0
except ValueError:
    TRACE = 0


class BuildAlure2Ext(build_ext):
    """Builder of extensions linked to alure2."""
    def finalize_options(self) -> None:
        """Add alure2's and its dependencies' include directories
        and objects to Extension attributes.
        """
        super().finalize_options()
        mkpath(self.build_temp)
        copy_file(join(dirname(__file__), 'CMakeLists.txt'),
                  self.build_temp)
        cmake = run(['cmake', '.'], check=True, stdout=DEVNULL, stderr=PIPE,
                    cwd=self.build_temp, universal_newlines=True)
        for key, value in map(methodcaller('groups'),
                              re.finditer(r'^alure2_(\w*)=(.*)$',
                                          cmake.stderr, re.MULTILINE)):
            for ext in self.extensions:
                getattr(ext, key).extend(value.split(';'))


setup(cmdclass={'build_ext': BuildAlure2Ext},
      ext_modules=cythonize(
          Extension(name='palace', sources=[join('src', 'palace.pyx')],
                    define_macros=[('CYTHON_TRACE', TRACE)],
                    extra_compile_args=["-std=c++14"], language='c++'),
          compiler_directives=dict(language_level='3str', c_string_type='str',
                                   c_string_encoding='utf8', linetrace=TRACE,
                                   binding=False, embedsignature=True)))
