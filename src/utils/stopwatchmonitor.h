#pragma once

#include <cmath>
#include <iostream>

#define DECL_STOPWATCH(varname) std::chrono::_V2::system_clock::time_point varname;

#define STOPWATCH_TIME_NOW(stopwatch) stopwatch = std::chrono::system_clock::now();

#define LOG_DURATION(start, end)                                                                                                                               \
    {                                                                                                                                                          \
        auto old_precision = std::cout.precision(2);                                                                                                           \
        /* Convert Nanoseconds to seconds  */                                                                                                                  \
        std::cout << "elapsed time: " << (double)((end - start).count()) / 1000000000 << "s" << std::endl;                                                     \
        std::cout.precision(old_precision);                                                                                                                    \
    }

#define LOG_DURATION_NOW(start) LOG_DURATION(start, std::chrono::system_clock::now())

#define LOG(msg) std::cout << QFileInfo(__FILE__).baseName().toStdString() << "::" << __func__ << "():line" << __LINE__ << ": " << msg << std::endl;
