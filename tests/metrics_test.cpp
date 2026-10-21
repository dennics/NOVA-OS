#include "SystemMetrics.hpp"

#include <cmath>
#include <iostream>
#include <stdexcept>

namespace {
void require(bool condition, const char *message)
{
    if (!condition) throw std::runtime_error(message);
}
}

int main()
{
    try {
        const auto cpu = nova::parseCpuStat("cpu 100 20 30 400 50 6 7 8 90 10\ncpu0 1 2 3 4\n");
        require(cpu && cpu->total == 621 && cpu->idle == 450, "guest time must not be counted twice");
        require(!nova::parseCpuStat("cpu0 1 2 3 4"), "per-core line must not impersonate aggregate CPU");
        require(!nova::parseCpuStat("cpu 1 2 3"), "truncated CPU sample must be unavailable");
        require(!nova::parseCpuStat("cpu 1 -2 3 4"), "negative counters must be rejected");
        require(!nova::parseCpuStat("cpu 18446744073709551615 1 2 3"), "counter sum must not wrap");
        const auto usage = nova::cpuUsage({100, 60}, {200, 100});
        require(usage && std::abs(*usage - 60.0) < 0.0001, "CPU usage must use differences between samples");
        require(!nova::cpuUsage({100, 60}, {100, 60}), "zero interval must not display zero utilization");
        require(!nova::cpuUsage({100, 60}, {90, 50}), "counter reset must invalidate the interval");
        require(!nova::cpuUsage({100, 60}, {110, 80}), "inconsistent idle delta must be unavailable");
        const auto memory = nova::parseMemInfo("MemTotal: 8388608 kB\nMemFree: 10 kB\nCached: 4000 kB\nMemAvailable: 6291456 kB\n");
        require(memory && memory->totalBytes == 8589934592ULL && memory->usedBytes() == 2147483648ULL,
                "memory must use MemAvailable, preserving reclaimable cache");
        require(!nova::parseMemInfo("MemTotal: 1024 kB\nMemFree: 512 kB\n"), "missing MemAvailable must not become zero");
        require(!nova::parseMemInfo("MemTotal: 1024 kB\nMemAvailable: 2048 kB\n"), "inconsistent memory data must fail");
        require(!nova::parseMemInfo("MemTotal: 1024 MB\nMemAvailable: 512 MB\n"), "unexpected units must fail");
        require(!nova::parseMemInfo("MemTotal: 18446744073709551615 kB\nMemAvailable: 1 kB\n"), "byte conversion must not wrap");
        std::cout << "CPU interval, guest accounting, reset, memory cache and malformed-source checks passed\n";
    } catch (const std::exception &error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
