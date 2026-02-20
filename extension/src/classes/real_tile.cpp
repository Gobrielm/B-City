#include "real_tile.hpp"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void RealTile::_bind_methods() {
    ClassDB::bind_static_method(get_class_static(), D_METHOD("create", "tile"), &RealTile::create);

    ClassDB::bind_method(D_METHOD("get_tile"), &RealTile::get_tile);
    ClassDB::bind_method(D_METHOD("add_vector2i", "vector"), &RealTile::add_vector2i);
    ClassDB::bind_method(D_METHOD("subtract_vector2i", "vector"), &RealTile::subtract_vector2i);

    ClassDB::bind_method(D_METHOD("distance_to", "other"), &RealTile::distance_to);

    ClassDB::add_property(RealTile::get_class_static(),  PropertyInfo(Variant::VECTOR2I, "tile"), "", "get_tile");
}


Ref<RealTile> RealTile::create(const Vector2i& p_tile) {
    return memnew(RealTile(p_tile));
}

RealTile::RealTile(): RealTile(0, 0) {}

RealTile::RealTile(int32_t p_x, int32_t p_y): tile(Vector2i(p_x, p_y)), RefCounted() {}

RealTile::RealTile(const Vector2i& p_tile): tile(p_tile) {}


Vector2i RealTile::get_tile() const {
    return tile;
}

float RealTile::distance_to(const Ref<RealTile> other) {
    return tile.distance_to(other->tile);
}