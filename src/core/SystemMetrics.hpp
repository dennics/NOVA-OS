#pragma once

#include <cstdint>
#include <optional>
#include <string_view>

namespace nova {
struct CpuTimes {
    std::uint64_t total;
    std::uint64_t idle;
};

struct Memory {
    std::uint64_t totalBytes;
    std::uint64_t availableBytes;
    [[nodiscard]] std::uint64_t usedBytes() const { return totalBytes - availableBytes; }
};

[[nodiscard]] std::optional<CpuTimes> parseCpuStat(std::string_view text);
[[nodiscard]] std::optional<Memory> parseMemInfo(std::string_view text);
[[nodiscard]] std::optional<double> cpuUsage(CpuTimes previous, CpuTimes current);
}

