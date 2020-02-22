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
#include <string>
#include <utility>
#include <vector>

#include "alure2.h"

// Due to the lack of support for noexcept keyword in Cython, base classes
// created to work around the looser throw specifier error in C++.
namespace palace {

class BaseDecoder : public alure::Decoder {
public:
  virtual unsigned get_frequency_() const = 0;
  inline ALuint
  getFrequency() const noexcept override
  {
    return get_frequency_();
  }

  virtual alure::ChannelConfig get_channel_config_() const = 0;
  inline alure::ChannelConfig
  getChannelConfig() const noexcept override
  {
    return get_channel_config_();
  }

  virtual alure::SampleType get_sample_type_() const = 0;
  inline alure::SampleType
  getSampleType() const noexcept override
  {
    return get_sample_type_();
  }

  virtual uint64_t get_length_() const = 0;
  inline uint64_t getLength() const noexcept override { return get_length_(); }

  virtual bool seek_ (uint64_t pos) = 0;
  inline bool seek (uint64_t pos) noexcept override { return seek_ (pos); }

  virtual std::pair<uint64_t,uint64_t> get_loop_points_() const = 0;
  inline std::pair<uint64_t,uint64_t>
  getLoopPoints() const noexcept override
  {
    return get_loop_points_();
  }

  virtual unsigned read_ (void* ptr, unsigned count) = 0;
  inline ALuint
  read (ALvoid* ptr, ALuint count) noexcept override
  {
    return read_ (ptr, count);
  }
};

class BaseMessageHandler : public alure::MessageHandler {
public:
  virtual void device_disconnected (alure::Device device) = 0;
  inline void
  deviceDisconnected (alure::Device device) noexcept override
  {
    device_disconnected (device);
  }

  virtual void source_stopped (alure::Source source) = 0;
  inline void
  sourceStopped (alure::Source source) noexcept override
  {
    source_stopped (source);
  }

  virtual void source_force_stopped (alure::Source source) = 0;
  inline void
  sourceForceStopped (alure::Source source) noexcept override
  {
    source_force_stopped (source);
  }

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
  {
    return resource_not_found (name.data());
  }
};

} // namespace palace

#endif // PALACE_BASES_H
