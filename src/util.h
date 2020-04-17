// Helper functions and mappings
// Copyright (C) 2020  Nguyễn Gia Phong
// Copyright (C) 2020  Ngô Ngọc Đức Huy
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

#ifndef PALACE_UTIL_H
#define PALACE_UTIL_H

#include <string>
#include <map>
#include <utility>
#include <vector>

#include "alure2.h"
#include "efx-presets.h"

namespace palace
{
  const std::map<std::string, alure::SampleType> SAMPLE_TYPES {
    {"Unsigned 8-bit", alure::SampleType::UInt8},
    {"Signed 16-bit", alure::SampleType::Int16},
    {"32-bit float", alure::SampleType::Float32},
    {"Mulaw", alure::SampleType::Mulaw}};

  const std::map<std::string, alure::ChannelConfig> CHANNEL_CONFIGS {
    {"Mono", alure::ChannelConfig::Mono},
    {"Stereo", alure::ChannelConfig::Stereo},
    {"Rear", alure::ChannelConfig::Rear},
    {"Quadrophonic", alure::ChannelConfig::Quad},
    {"5.1 Surround", alure::ChannelConfig::X51},
    {"6.1 Surround", alure::ChannelConfig::X61},
    {"7.1 Surround", alure::ChannelConfig::X71},
    {"B-Format 2D", alure::ChannelConfig::BFormat2D},
    {"B-Format 3D", alure::ChannelConfig::BFormat3D}};

  const std::map<std::string, alure::DistanceModel> DISTANCE_MODELS {
    {"inverse clamped", alure::DistanceModel::InverseClamped},
    {"linear clamped", alure::DistanceModel::LinearClamped},
    {"exponent clamped", alure::DistanceModel::ExponentClamped},
    {"inverse", alure::DistanceModel::Inverse},
    {"linear", alure::DistanceModel::Linear},
    {"exponent", alure::DistanceModel::Exponent},
    {"none", alure::DistanceModel::None}};

  // This is ported from alure-reverb example.
  #define DECL(x) { #x, EFX_REVERB_PRESET_##x }
  const std::map<std::string, EFXEAXREVERBPROPERTIES> REVERB_PRESETS {
    DECL(GENERIC), DECL(PADDEDCELL), DECL(ROOM), DECL(BATHROOM),
    DECL(LIVINGROOM), DECL(STONEROOM), DECL(AUDITORIUM), DECL(CONCERTHALL),
    DECL(CAVE), DECL(ARENA), DECL(HANGAR), DECL(CARPETEDHALLWAY), DECL(HALLWAY),
    DECL(STONECORRIDOR), DECL(ALLEY), DECL(FOREST), DECL(CITY), DECL(MOUNTAINS),
    DECL(QUARRY), DECL(PLAIN), DECL(PARKINGLOT), DECL(SEWERPIPE),
    DECL(UNDERWATER), DECL(DRUGGED), DECL(DIZZY), DECL(PSYCHOTIC),

    DECL(CASTLE_SMALLROOM), DECL(CASTLE_SHORTPASSAGE), DECL(CASTLE_MEDIUMROOM),
    DECL(CASTLE_LARGEROOM), DECL(CASTLE_LONGPASSAGE), DECL(CASTLE_HALL),
    DECL(CASTLE_CUPBOARD), DECL(CASTLE_COURTYARD), DECL(CASTLE_ALCOVE),

    DECL(FACTORY_SMALLROOM), DECL(FACTORY_SHORTPASSAGE),
    DECL(FACTORY_MEDIUMROOM), DECL(FACTORY_LARGEROOM),
    DECL(FACTORY_LONGPASSAGE), DECL(FACTORY_HALL), DECL(FACTORY_CUPBOARD),
    DECL(FACTORY_COURTYARD), DECL(FACTORY_ALCOVE),

    DECL(ICEPALACE_SMALLROOM), DECL(ICEPALACE_SHORTPASSAGE),
    DECL(ICEPALACE_MEDIUMROOM), DECL(ICEPALACE_LARGEROOM),
    DECL(ICEPALACE_LONGPASSAGE), DECL(ICEPALACE_HALL), DECL(ICEPALACE_CUPBOARD),
    DECL(ICEPALACE_COURTYARD), DECL(ICEPALACE_ALCOVE),

    DECL(SPACESTATION_SMALLROOM), DECL(SPACESTATION_SHORTPASSAGE),
    DECL(SPACESTATION_MEDIUMROOM), DECL(SPACESTATION_LARGEROOM),
    DECL(SPACESTATION_LONGPASSAGE), DECL(SPACESTATION_HALL),
    DECL(SPACESTATION_CUPBOARD), DECL(SPACESTATION_ALCOVE),

    DECL(WOODEN_SMALLROOM), DECL(WOODEN_SHORTPASSAGE), DECL(WOODEN_MEDIUMROOM),
    DECL(WOODEN_LARGEROOM), DECL(WOODEN_LONGPASSAGE), DECL(WOODEN_HALL),
    DECL(WOODEN_CUPBOARD), DECL(WOODEN_COURTYARD), DECL(WOODEN_ALCOVE),

    DECL(SPORT_EMPTYSTADIUM), DECL(SPORT_SQUASHCOURT),
    DECL(SPORT_SMALLSWIMMINGPOOL), DECL(SPORT_LARGESWIMMINGPOOL),
    DECL(SPORT_GYMNASIUM), DECL(SPORT_FULLSTADIUM), DECL(SPORT_STADIUMTANNOY),

    DECL(PREFAB_WORKSHOP), DECL(PREFAB_SCHOOLROOM), DECL(PREFAB_PRACTISEROOM),
    DECL(PREFAB_OUTHOUSE), DECL(PREFAB_CARAVAN),

    DECL(DOME_TOMB), DECL(PIPE_SMALL), DECL(DOME_SAINTPAULS),
    DECL(PIPE_LONGTHIN), DECL(PIPE_LARGE), DECL(PIPE_RESONANT),

    DECL(OUTDOORS_BACKYARD), DECL(OUTDOORS_ROLLINGPLAINS),
    DECL(OUTDOORS_DEEPCANYON), DECL(OUTDOORS_CREEK), DECL(OUTDOORS_VALLEY),

    DECL(MOOD_HEAVEN), DECL(MOOD_HELL), DECL(MOOD_MEMORY),

    DECL(DRIVING_COMMENTATOR), DECL(DRIVING_PITGARAGE),
    DECL(DRIVING_INCAR_RACER), DECL(DRIVING_INCAR_SPORTS),
    DECL(DRIVING_INCAR_LUXURY), DECL(DRIVING_FULLGRANDSTAND),
    DECL(DRIVING_EMPTYGRANDSTAND), DECL(DRIVING_TUNNEL),

    DECL(CITY_STREETS), DECL(CITY_SUBWAY), DECL(CITY_MUSEUM),
    DECL(CITY_LIBRARY), DECL(CITY_UNDERPASS), DECL(CITY_ABANDONED),

    DECL(DUSTYROOM), DECL(CHAPEL), DECL(SMALLWATERROOM)};
  #undef DECL

  inline std::vector<std::string>
  reverb_presets() noexcept
  {
    std::vector<std::string> presets;
    for (auto const& preset : REVERB_PRESETS)
      presets.push_back (preset.first);
    return presets;
  }

  inline std::vector<alure::AttributePair>
  mkattrs (std::vector<std::pair<int, int>> attrs) noexcept
  {
    std::vector<alure::AttributePair> attributes;
    for (auto const& pair : attrs)
      attributes.push_back ({pair.first, pair.second});
    attributes.push_back (alure::AttributesEnd());
    return attributes;
  }

  inline alure::FilterParams
  make_filter (float gain, float gain_hf, float gain_lf) noexcept
  { return alure::FilterParams {gain, gain_hf, gain_lf}; }

  inline std::vector<float>
  from_vector3 (alure::Vector3 v) noexcept
  { return std::vector<float> {v[0], v[1], v[2]}; }

  inline alure::Vector3
  to_vector3 (std::vector<float> v) noexcept
  { return alure::Vector3 {v[0], v[1], v[2]}; }
} // namespace palace

#endif // PALACE_UTIL_H
