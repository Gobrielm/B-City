#pragma once

#include <godot_cpp/variant/vector2i.hpp>
#include <godot_cpp/classes/ref_counted.hpp>

using namespace godot;

class RealTile: public RefCounted {
    GDCLASS(RealTile, RefCounted);

    Vector2i tile;

    protected:
    static void _bind_methods();

    public:
    RealTile();
    RealTile(int32_t x, int32_t y);
    RealTile(const Vector2i& tile);

    static Ref<RealTile> create(const Vector2i& tile);

    Vector2i get_tile() const;

    Ref<RealTile> add_vector2i(const Vector2i& other) { tile += other; return this; }
    Ref<RealTile> subtract_vector2i(const Vector2i& other) { tile -= other; return this; }

    float distance_to(const Ref<RealTile> other);

    bool operator==(const RealTile &other) const { return tile == other.tile; }
    bool operator!=(const RealTile &other) const { return !(*this == other); }
    bool operator<(const RealTile &other) const { return (tile < other.tile);}
    bool operator<=(const RealTile &other) const { return *this < other || *this == other; }
    bool operator>(const RealTile &other) const { return !(*this <= other); }
    bool operator>=(const RealTile &other) const { return !(*this < other); }

    RealTile operator+(const RealTile &other) const { return RealTile(tile + other.tile); }
    RealTile operator-(const RealTile &other) const { return RealTile(tile - other.tile); }

    RealTile& operator+=(const RealTile &other) { tile += other.tile; return *this; }
    RealTile& operator-=(const RealTile &other) { tile -= other.tile; return *this; }

    bool operator==(const Vector2i &other) const { return tile == other; }
    bool operator!=(const Vector2i &other) const { return tile != other; }
    bool operator<(const Vector2i &other) const { return tile < other; }
    bool operator<=(const Vector2i &other) const { return tile < other || tile == other; }
    bool operator>(const Vector2i &other) const { return !(tile <= other); }
    bool operator>=(const Vector2i &other) const { return !(tile < other); }

    RealTile operator+(const Vector2i &other) const { return RealTile(tile + other); }
    RealTile operator-(const Vector2i &other) const { return RealTile(tile - other); }

    RealTile& operator+=(const Vector2i &other) { tile += other; return *this; }
    RealTile& operator-=(const Vector2i &other) { tile -= other; return *this; }
};