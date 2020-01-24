#!/usr/bin/env python3
import re
from distutils.dir_util import mkpath
from distutils.file_util import copy_file
from operator import methodcaller
from os.path import dirname, join
from subprocess import DEVNULL, PIPE, run

from Cython.Build import cythonize
from setuptools import setup, Extension
from setuptools.command.build_ext import build_ext


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
          Extension(name='palace', sources=['palace.pyx'], language='c++'),
          compiler_directives=dict(
              binding=False, embedsignature=True, language_level='3str',
              c_string_type='str', c_string_encoding='utf8')))
