// Base classes for Cython compatibility
// Copyright (C) 2020  Nguyễn Gia Phong
//
// This file is part of palace.
//
// palace is free software: you can redistribute it and/or modify it
// under the terms of the GNU Lesser General Public License as published
// by the Free Software Foundation, either version 3 of the License,
// or (at your option) any later version.
//
// palace is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with palace.  If not, see <https://www.gnu.org/licenses/>.

#ifndef PALACE_BASES_H
#define PALACE_BASES_H

#include <algorithm>
#include <ios>
#include <iostream>
#include <memory>
#include <streambuf>
#include <string>
#include <utility>
#include <vector>

#include "alure2.h"

namespace palace
{
  // Work around exotic standard type definitions Cython cannot handle
  class BaseStreamBuf : public std::streambuf
  {
  protected:
    virtual size_t seek (long long offset, int whence = 0) = 0;

    inline pos_type
    seekoff (off_type off, std::ios_base::seekdir way,
             std::ios_base::openmode
             which = std::ios_base::in|std::ios_base::out) override
    {
      switch (way)
        {
        case std::ios_base::beg:
          return seek (off, 0);
        case std::ios_base::cur:
          return seek (off, 1);
        case std::ios_base::end:
          return seek (off, 2);
        default:
          return off_type (-1);
        }
    }

    inline pos_type
    seekpos (pos_type sp,
             std::ios_base::openmode
             which = std::ios_base::in|std::ios_base::out) override
    { return seek (sp); }

    inline int sync() override
    {
      if (gptr() && gptr() < egptr())
        seek (gptr() - egptr(), 1);
      return 0;
    }

    inline std::streamsize showmanyc() override
    { return (underflow() == traits_type::eof()) ? -1 : egptr() - gptr(); }
  };

  // Work around throw specifier (noexcept) and exotic types
  // that cannot be handled prettily in Cython
  class BaseDecoder : public alure::Decoder
  {
  public:
    virtual unsigned get_frequency_() const = 0;
    inline ALuint
    getFrequency() const noexcept override
    { return get_frequency_(); }

    virtual alure::ChannelConfig get_channel_config_() const = 0;
    inline alure::ChannelConfig
    getChannelConfig() const noexcept override { return get_channel_config_(); }

    virtual alure::SampleType get_sample_type_() const = 0;
    inline alure::SampleType
    getSampleType() const noexcept override { return get_sample_type_(); }

    virtual uint64_t get_length_() const = 0;
    inline uint64_t
    getLength() const noexcept override { return get_length_(); }

    virtual bool seek_ (uint64_t pos) = 0;
    inline bool seek (uint64_t pos) noexcept override { return seek_ (pos); }

    virtual std::pair<uint64_t,uint64_t> get_loop_points_() const = 0;
    inline std::pair<uint64_t,uint64_t>
    getLoopPoints() const noexcept override { return get_loop_points_(); }

    virtual unsigned read_ (void* ptr, unsigned count) = 0;
    inline ALuint
    read (ALvoid* ptr, ALuint count) noexcept override
    { return read_ (ptr, count); }
  };

  // Work around throw specifier Cython cannot handle (noexcept)
  class BaseFileIOFactory : public alure::FileIOFactory
  {
  public:
    virtual std::unique_ptr<std::istream>
    open_file(const std::string &name) = 0;
    inline alure::UniquePtr<std::istream>
    openFile(const alure::String &name) noexcept override
    { return open_file (name); }
  };

  // Work around throw specifier Cython cannot handle (noexcept)
  class BaseMessageHandler : public alure::MessageHandler
  {
  public:
    virtual void device_disconnected (alure::Device& device) = 0;
    inline void
    deviceDisconnected (alure::Device device) noexcept override
    { device_disconnected (device); }

    virtual void source_stopped (alure::Source& source) = 0;
    inline void
    sourceStopped (alure::Source source) noexcept override
    { source_stopped (source); }

    virtual void source_force_stopped (alure::Source& source) = 0;
    inline void
    sourceForceStopped (alure::Source source) noexcept override
    { source_force_stopped (source); }

    virtual void buffer_loading (std::string name, std::string channel_config,
                                 std::string sample_type, unsigned sample_rate,
                                 std::vector<signed char> data) = 0;
    inline void
    bufferLoading (alure::StringView name, alure::ChannelConfig channels,
                   alure::SampleType type, ALuint samplerate,
                   alure::ArrayView<ALbyte> data) noexcept override
    {
      std::vector<signed char> std_data (data.size());
      // FIXME: This defeats the entire point of alure::ArrayView.
      std::copy (data.begin(), data.end(), std_data.begin());
      buffer_loading (name.data(), alure::GetChannelConfigName (channels),
                      alure::GetSampleTypeName (type), samplerate, std_data);
    }

    virtual std::string resource_not_found (std::string name) = 0;
    inline alure::String
    resourceNotFound (alure::StringView name) noexcept override
    { return resource_not_found (name.data()); }
  };
} // namespace palace

#endif // PALACE_BASES_H
