#pragma once
#include <memory>

class StaticRegistry {
public:
    static void initialize();
    static void uninitialize();
};

