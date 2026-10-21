#include "SystemMetrics.hpp"

#include <array>
#include <charconv>
#include <limits>
#include <sstream>
#include <string>

namespace nova {
namespace {
std::optional<std::uint64_t> unsignedNumber(std::string_view text)
{
    std::uint64_t result = 0;
    const auto parsed = std::from_chars(text.data(), text.data() + text.size(), result);
    if (parsed.ec != std::errc{} || parsed.ptr != text.data() + text.size()) {
        return std::nullopt;
    }
    return result;
}
}

std::optional<CpuTimes> parseCpuStat(std::string_view text)
{
    std::istringstream lines{std::string(text)};
    std::string line;
    if (!std::getline(lines, line)) return std::nullopt;
    std::istringstream fields{line};
    std::string label;
    fields >> label;
    if (label != "cpu") return std::nullopt;
    std::array<std::uint64_t, 8> counters{};
    std::size_t count = 0;
    std::string value;
    while (count < counters.size() && fields >> value) {
        const auto parsed = unsignedNumber(value);
        if (!parsed) return std::nullopt;
        counters[count++] = *parsed;
    }
    if (count < 4) return std::nullopt;
    CpuTimes result{0, 0};
    for (const auto counter : counters) {
        if (counter > std::numeric_limits<std::uint64_t>::max() - result.total) return std::nullopt;
        result.total += counter;
    }
    // Linux includes guest and guest_nice in user/nice already: do not add fields 9 and 10.
    result.idle = counters[3] + counters[4];
    return result;
}

std::optional<Memory> parseMemInfo(std::string_view text)
{
    std::istringstream lines{std::string(text)};
    std::optional<std::uint64_t> total;
    std::optional<std::uint64_t> available;
    std::string line;
    while (std::getline(lines, line)) {
        std::istringstream fields{line};
        std::string name, number, unit;
        fields >> name;
        if (name != "MemTotal:" && name != "MemAvailable:") continue;
        if (!(fields >> number >> unit) || unit != "kB") return std::nullopt;
        const auto parsed = unsignedNumber(number);
        if (!parsed || *parsed > std::numeric_limits<std::uint64_t>::max() / 1024) return std::nullopt;
        auto &destination = name == "MemTotal:" ? total : available;
        if (destination) return std::nullopt;
        destination = *parsed * 1024;
    }
    if (!total || !available || *total == 0 || *available > *total) return std::nullopt;
    return Memory{*total, *available};
}

std::optional<double> cpuUsage(CpuTimes previous, CpuTimes current)
{
    if (current.total <= previous.total || current.idle < previous.idle) return std::nullopt;
    const auto total = current.total - previous.total;
    const auto idle = current.idle - previous.idle;
    if (idle > total) return std::nullopt;
    return 100.0 * static_cast<double>(total - idle) / static_cast<double>(total);
}
}

