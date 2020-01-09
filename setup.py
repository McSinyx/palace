#!/usr/bin/env python3
from Cython.Build import cythonize
from setuptools import setup, Extension

with open('README.md') as f:
    long_description = f.read()

setup(
    name='palace',
    version='0.0.2',
    description='Pythonic Audio Library and Codecs Environment',
    long_description=long_description,
    long_description_content_type='text/markdown',
    url='https://github.com/McSinyx/palace',
    author='Nguyễn Gia Phong',
    author_email='vn.mcsinyx@gmail.com',
    license='LGPLv3+',
    classifiers=[
        'Development Status :: 2 - Pre-Alpha',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: GNU Lesser General Public License v3 or later (LGPLv3+)',
        'Operating System :: POSIX :: Linux',
        'Programming Language :: C++',
        'Programming Language :: Cython',
        'Programming Language :: Python :: 3.6',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3 :: Only',
        'Topic :: Multimedia :: Sound/Audio',
        'Topic :: Software Development :: Libraries',
        'Typing :: Typed'],
    keywords='openal alure hrtf',
    ext_modules=cythonize(
        Extension('palace', ['palace.pyx'],
                  include_dirs=['/usr/include/AL/'],
                  libraries=['alure2'], language='c++'),
        compiler_directives=dict(
            binding=False, embedsignature=True, language_level='3str',
            c_string_type='str', c_string_encoding='utf8')),
    zip_safe=False)
