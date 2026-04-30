#include <moonbit.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
  uint32_t entity;
  void *value;
} MecsV3ComponentEntry;

typedef struct {
  int32_t id_len;
  uint16_t *id;
  int32_t len;
  int32_t cap;
  MecsV3ComponentEntry *entries;
} MecsV3Store;

typedef struct {
  int32_t id_len;
  uint16_t *id;
  void *value;
} MecsV3ResourceEntry;

typedef struct {
  uint32_t next_entity;
  int32_t alive_cap;
  uint8_t *alive;
  int32_t stores_len;
  int32_t stores_cap;
  MecsV3Store *stores;
  int32_t resources_len;
  int32_t resources_cap;
  MecsV3ResourceEntry *resources;
} MecsV3World;

static void mecs_v3_abort(const char *message) {
  fprintf(stderr, "mecs/v3 runtime error: %s\n", message);
  abort();
}

static int32_t mecs_v3_id_len(moonbit_string_t id) {
  return (int32_t)Moonbit_array_length(id);
}

static int mecs_v3_id_equal(uint16_t *a, int32_t a_len, moonbit_string_t b) {
  int32_t b_len = mecs_v3_id_len(b);
  return a_len == b_len && memcmp(a, b, (size_t)a_len * sizeof(uint16_t)) == 0;
}

static uint16_t *mecs_v3_id_copy(moonbit_string_t id, int32_t *len_out) {
  int32_t len = mecs_v3_id_len(id);
  uint16_t *copy = NULL;
  if (len > 0) {
    copy = (uint16_t *)malloc((size_t)len * sizeof(uint16_t));
    if (copy == NULL) {
      mecs_v3_abort("out of memory while copying type id");
    }
    memcpy(copy, id, (size_t)len * sizeof(uint16_t));
  }
  *len_out = len;
  return copy;
}

static void mecs_v3_ensure_alive_cap(MecsV3World *world, uint32_t entity) {
  if (entity < (uint32_t)world->alive_cap) {
    return;
  }
  int32_t next_cap = world->alive_cap == 0 ? 16 : world->alive_cap;
  while (entity >= (uint32_t)next_cap) {
    next_cap *= 2;
  }
  uint8_t *next = (uint8_t *)realloc(world->alive, (size_t)next_cap);
  if (next == NULL) {
    mecs_v3_abort("out of memory while growing entity table");
  }
  memset(next + world->alive_cap, 0, (size_t)(next_cap - world->alive_cap));
  world->alive = next;
  world->alive_cap = next_cap;
}

static MecsV3Store *mecs_v3_find_store(MecsV3World *world, moonbit_string_t id) {
  for (int32_t i = 0; i < world->stores_len; i++) {
    MecsV3Store *store = &world->stores[i];
    if (mecs_v3_id_equal(store->id, store->id_len, id)) {
      return store;
    }
  }
  return NULL;
}

static MecsV3Store *mecs_v3_ensure_store(MecsV3World *world, moonbit_string_t id) {
  MecsV3Store *existing = mecs_v3_find_store(world, id);
  if (existing != NULL) {
    return existing;
  }
  if (world->stores_len == world->stores_cap) {
    int32_t next_cap = world->stores_cap == 0 ? 8 : world->stores_cap * 2;
    MecsV3Store *next = (MecsV3Store *)realloc(
      world->stores,
      (size_t)next_cap * sizeof(MecsV3Store)
    );
    if (next == NULL) {
      mecs_v3_abort("out of memory while growing component stores");
    }
    world->stores = next;
    world->stores_cap = next_cap;
  }
  MecsV3Store *store = &world->stores[world->stores_len++];
  memset(store, 0, sizeof(MecsV3Store));
  store->id = mecs_v3_id_copy(id, &store->id_len);
  return store;
}

static int32_t mecs_v3_find_component_index(MecsV3Store *store, uint32_t entity) {
  for (int32_t i = 0; i < store->len; i++) {
    if (store->entries[i].entity == entity) {
      return i;
    }
  }
  return -1;
}

static void mecs_v3_store_set(MecsV3Store *store, uint32_t entity, void *value) {
  int32_t index = mecs_v3_find_component_index(store, entity);
  if (index >= 0) {
    moonbit_decref(store->entries[index].value);
    store->entries[index].value = value;
    return;
  }
  if (store->len == store->cap) {
    int32_t next_cap = store->cap == 0 ? 8 : store->cap * 2;
    MecsV3ComponentEntry *next = (MecsV3ComponentEntry *)realloc(
      store->entries,
      (size_t)next_cap * sizeof(MecsV3ComponentEntry)
    );
    if (next == NULL) {
      mecs_v3_abort("out of memory while growing component entries");
    }
    store->entries = next;
    store->cap = next_cap;
  }
  store->entries[store->len].entity = entity;
  store->entries[store->len].value = value;
  store->len++;
}

static void mecs_v3_store_remove(MecsV3Store *store, uint32_t entity) {
  int32_t index = mecs_v3_find_component_index(store, entity);
  if (index < 0) {
    return;
  }
  moonbit_decref(store->entries[index].value);
  store->entries[index] = store->entries[store->len - 1];
  store->len--;
}

static MecsV3ResourceEntry *mecs_v3_find_resource(
  MecsV3World *world,
  moonbit_string_t id
) {
  for (int32_t i = 0; i < world->resources_len; i++) {
    MecsV3ResourceEntry *resource = &world->resources[i];
    if (mecs_v3_id_equal(resource->id, resource->id_len, id)) {
      return resource;
    }
  }
  return NULL;
}

static MecsV3ResourceEntry *mecs_v3_ensure_resource(
  MecsV3World *world,
  moonbit_string_t id
) {
  MecsV3ResourceEntry *existing = mecs_v3_find_resource(world, id);
  if (existing != NULL) {
    return existing;
  }
  if (world->resources_len == world->resources_cap) {
    int32_t next_cap = world->resources_cap == 0 ? 8 : world->resources_cap * 2;
    MecsV3ResourceEntry *next = (MecsV3ResourceEntry *)realloc(
      world->resources,
      (size_t)next_cap * sizeof(MecsV3ResourceEntry)
    );
    if (next == NULL) {
      mecs_v3_abort("out of memory while growing resources");
    }
    world->resources = next;
    world->resources_cap = next_cap;
  }
  MecsV3ResourceEntry *resource = &world->resources[world->resources_len++];
  memset(resource, 0, sizeof(MecsV3ResourceEntry));
  resource->id = mecs_v3_id_copy(id, &resource->id_len);
  return resource;
}

static void mecs_v3_world_finalize(void *ptr) {
  MecsV3World *world = (MecsV3World *)ptr;
  for (int32_t i = 0; i < world->stores_len; i++) {
    MecsV3Store *store = &world->stores[i];
    for (int32_t j = 0; j < store->len; j++) {
      moonbit_decref(store->entries[j].value);
    }
    free(store->entries);
    free(store->id);
  }
  for (int32_t i = 0; i < world->resources_len; i++) {
    MecsV3ResourceEntry *resource = &world->resources[i];
    moonbit_decref(resource->value);
    free(resource->id);
  }
  free(world->stores);
  free(world->resources);
  free(world->alive);
}

MOONBIT_FFI_EXPORT
MecsV3World *mecs_v3_world_new(void) {
  MecsV3World *world = (MecsV3World *)moonbit_make_external_object(
    mecs_v3_world_finalize,
    sizeof(MecsV3World)
  );
  memset(world, 0, sizeof(MecsV3World));
  return world;
}

MOONBIT_FFI_EXPORT
uint32_t mecs_v3_world_spawn(MecsV3World *world) {
  uint32_t entity = world->next_entity++;
  mecs_v3_ensure_alive_cap(world, entity);
  world->alive[entity] = 1;
  return entity;
}

MOONBIT_FFI_EXPORT
int32_t mecs_v3_world_is_alive(MecsV3World *world, uint32_t entity) {
  return entity < (uint32_t)world->alive_cap && world->alive[entity] != 0;
}

MOONBIT_FFI_EXPORT
int32_t mecs_v3_world_despawn(MecsV3World *world, uint32_t entity) {
  if (!mecs_v3_world_is_alive(world, entity)) {
    return 0;
  }
  world->alive[entity] = 0;
  for (int32_t i = 0; i < world->stores_len; i++) {
    mecs_v3_store_remove(&world->stores[i], entity);
  }
  return 1;
}

MOONBIT_FFI_EXPORT
void mecs_v3_world_set_component(
  MecsV3World *world,
  moonbit_string_t type_id,
  uint32_t entity,
  void *value
) {
  if (!mecs_v3_world_is_alive(world, entity)) {
    moonbit_decref(value);
    return;
  }
  MecsV3Store *store = mecs_v3_ensure_store(world, type_id);
  mecs_v3_store_set(store, entity, value);
}

MOONBIT_FFI_EXPORT
int32_t mecs_v3_world_has_component(
  MecsV3World *world,
  moonbit_string_t type_id,
  uint32_t entity
) {
  MecsV3Store *store = mecs_v3_find_store(world, type_id);
  return store != NULL && mecs_v3_find_component_index(store, entity) >= 0;
}

MOONBIT_FFI_EXPORT
void *mecs_v3_world_get_component(
  MecsV3World *world,
  moonbit_string_t type_id,
  uint32_t entity
) {
  MecsV3Store *store = mecs_v3_find_store(world, type_id);
  if (store == NULL) {
    mecs_v3_abort("component store is missing");
  }
  int32_t index = mecs_v3_find_component_index(store, entity);
  if (index < 0) {
    mecs_v3_abort("component is missing");
  }
  void *value = store->entries[index].value;
  moonbit_incref(value);
  return value;
}

MOONBIT_FFI_EXPORT
void mecs_v3_world_remove_component(
  MecsV3World *world,
  moonbit_string_t type_id,
  uint32_t entity
) {
  MecsV3Store *store = mecs_v3_find_store(world, type_id);
  if (store != NULL) {
    mecs_v3_store_remove(store, entity);
  }
}

MOONBIT_FFI_EXPORT
int32_t mecs_v3_world_component_count(MecsV3World *world, moonbit_string_t type_id) {
  MecsV3Store *store = mecs_v3_find_store(world, type_id);
  return store == NULL ? 0 : store->len;
}

MOONBIT_FFI_EXPORT
uint32_t mecs_v3_world_component_entity_at(
  MecsV3World *world,
  moonbit_string_t type_id,
  int32_t index
) {
  MecsV3Store *store = mecs_v3_find_store(world, type_id);
  if (store == NULL || index < 0 || index >= store->len) {
    mecs_v3_abort("component index is out of bounds");
  }
  return store->entries[index].entity;
}

MOONBIT_FFI_EXPORT
void mecs_v3_world_set_resource(
  MecsV3World *world,
  moonbit_string_t type_id,
  void *value
) {
  MecsV3ResourceEntry *resource = mecs_v3_ensure_resource(world, type_id);
  if (resource->value != NULL) {
    moonbit_decref(resource->value);
  }
  resource->value = value;
}

MOONBIT_FFI_EXPORT
int32_t mecs_v3_world_has_resource(MecsV3World *world, moonbit_string_t type_id) {
  return mecs_v3_find_resource(world, type_id) != NULL;
}

MOONBIT_FFI_EXPORT
void *mecs_v3_world_get_resource(MecsV3World *world, moonbit_string_t type_id) {
  MecsV3ResourceEntry *resource = mecs_v3_find_resource(world, type_id);
  if (resource == NULL) {
    mecs_v3_abort("resource is missing");
  }
  moonbit_incref(resource->value);
  return resource->value;
}

MOONBIT_FFI_EXPORT
void mecs_v3_world_remove_resource(MecsV3World *world, moonbit_string_t type_id) {
  for (int32_t i = 0; i < world->resources_len; i++) {
    MecsV3ResourceEntry *resource = &world->resources[i];
    if (mecs_v3_id_equal(resource->id, resource->id_len, type_id)) {
      moonbit_decref(resource->value);
      free(resource->id);
      world->resources[i] = world->resources[world->resources_len - 1];
      world->resources_len--;
      return;
    }
  }
}
