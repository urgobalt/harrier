use strings;
use types;
use hash::siphash;
use hash;
use crypto::random;
use bytes;
use fmt;
use time;

export type value = (...types::numeric | uintptr | str | rune | bool | *opaque);
export type kv = struct {
  key: []u8,
  value: value,
};
export type hashmap = struct {
  primary_content: [](void|kv),
  secondary_content: [](void|kv),
  count: size,
  capacity: size,
  primary_hashkey: [16]u8,
  secondary_hashkey: [16]u8,
};

export const initial_capacity: size = 32;
export const max_depth: size = 8;

export fn assert_valid_hashmap(hashmap: *hashmap) void = {
  // INFO: Assert capacity is a power of 2
  assert((initial_capacity & (initial_capacity - 1)) == 0);
};

fn init_hash(hash_key: *[16]u8) void = {
  random::buffer(hash_key);
};

fn hash(siphash_key: *[16]u8, key: []u8) size = {
	let sip = siphash::siphash(2, 4, siphash_key);
  defer hash::close(&sip);
  hash::write(&sip, key);
  return siphash::sum(&sip);
};

export fn init() (hashmap|nomem) = {
  // INFO: Assert initial_capacity is a power of 2
  assert((initial_capacity & (initial_capacity - 1)) == 0);

  const hashmap = hashmap {
    primary_content = alloc([void...], initial_capacity)?,
    secondary_content = alloc([void...], initial_capacity)?,
    count = 0,
    capacity = initial_capacity,
    primary_hashkey: [16]u8 = [0...],
    secondary_hashkey: [16]u8 = [0...],
  };

  init_hash(&hashmap.primary_hashkey);
  init_hash(&hashmap.secondary_hashkey);

  return hashmap;
};

export fn deinit(hashmap: *hashmap) void = {
  free(hashmap.primary_content);
  free(hashmap.secondary_content);
};

export fn get(hashmap: *hashmap, key: []u8) (void|*value) = {
  assert_valid_hashmap(hashmap);
  const index = hash(&hashmap.primary_hashkey, key) & (hashmap.capacity - 1);
  if (hashmap.primary_content[index] is kv && bytes::equal((hashmap.primary_content[index] as kv).key, key))
    return &(hashmap.primary_content[index] as kv).value;

  const index = hash(&hashmap.secondary_hashkey, key) & (hashmap.capacity - 1);
  if (hashmap.secondary_content[index] is kv && bytes::equal((hashmap.secondary_content[index] as kv).key, key))
    return &(hashmap.secondary_content[index] as kv).value;
  return void;
};

export fn put(hashmap: *hashmap, key: []u8, _value: value) (void|nomem) = {
  assert_valid_hashmap(hashmap);

  if (hashmap.count*2 >= hashmap.capacity)
    realloc(hashmap, hashmap.capacity*2)?;

  if (get(hashmap, key) is *value)
    return;

  unsafe_put(hashmap, kv {
    key = key,
    value = _value,
  })?;
};

// WARN: This function does not reallocate when maximum size if reached.
// The put procedure will exceed the callstack if maximum size is reached.
// WARN: This function does not ensure that the hashmap is in a valid state,
// which may cause undefined behaviour.
// WARN: This function does not ensure that the value is already in the hashmap.
// This means that the key may cause infinite collisions.
export fn unsafe_put(hashmap: *hashmap, item: kv) (void|nomem) = {
  for (let i = 0z; i < max_depth; i += 1) {

    // BUG: The following match+print statement somehow fixes some bug in the
    // type checking for void or whatever.
    match (item.value) {
    case let pointer: *opaque => fmt::printf("{}, ", pointer)!;
    case let string: str => fmt::printf("\"{}\", ", string)!;
    case let other: (...types::numeric | uintptr | str | rune | bool) => fmt::printf("{}, ", other)!;
    };

    const index = hash(&hashmap.primary_hashkey, item.key) & (hashmap.capacity - 1);
    if (hashmap.primary_content[index] is void) {
      hashmap.primary_content[index] = item;
      hashmap.count += 1;
      return;
    };

    const temp = hashmap.primary_content[index]: kv;
    hashmap.primary_content[index] = item;
    item = temp;

    const index = hash(&hashmap.secondary_hashkey, item.key) & (hashmap.capacity - 1);
    if (hashmap.secondary_content[index] is void) {
      hashmap.secondary_content[index] = item;
      hashmap.count += 1;
      return;
    };

    const temp = hashmap.secondary_content[index]: kv;
    hashmap.secondary_content[index] = item;
    item = temp;
  };
  rehash(hashmap)?;
  unsafe_put(hashmap, item)?;
};

export fn pop(hashmap: *hashmap, key: []u8) (value|void) = {
  assert_valid_hashmap(hashmap);

  const index = hash(&hashmap.primary_hashkey, key) & (hashmap.capacity - 1);
  if (hashmap.primary_content[index] is kv && bytes::equal((hashmap.primary_content[index] as kv).key, key)) {
    const v = (hashmap.primary_content[index] as kv).value;
    hashmap.primary_content[index] = void;
    hashmap.count -= 1;
    return v;
  };

  const index = hash(&hashmap.secondary_hashkey, key) & (hashmap.capacity - 1);
  if (hashmap.secondary_content[index] is kv && bytes::equal((hashmap.secondary_content[index] as kv).key, key)){

    const v = (hashmap.secondary_content[index] as kv).value;
    hashmap.secondary_content[index] = void;
    hashmap.count -= 1;
    return v;
  };
  return void;
};

// BUG: Infinite recursion stuff when the function rehashes. Don't know why.
fn rehash(hashmap: *hashmap) (void|nomem) = {
  init_hash(&hashmap.primary_hashkey);
  init_hash(&hashmap.secondary_hashkey);

  realloc(hashmap, hashmap.capacity)?;
};

fn realloc(hashmap: *hashmap, capacity: size) (void|nomem) = {
  let primary_content:   [](void|kv) = alloc([void...], capacity)?;
  let secondary_content: [](void|kv) = alloc([void...], capacity)?;

  // Swap new and old hashtables

  const temp = hashmap.primary_content;
  hashmap.primary_content = primary_content;
  primary_content = temp;

  const temp = hashmap.secondary_content;
  hashmap.secondary_content = secondary_content;
  secondary_content = temp;

  hashmap.capacity = capacity;
  hashmap.count = 0;

  // Move all the values into the new tables

  for (let item .. primary_content) {
    if (item is void)
      continue;

    unsafe_put(hashmap, item: kv)?;
  };

  for (let item .. secondary_content) {
    if (item is void)
      continue;

    unsafe_put(hashmap, item: kv)?;
  };

  free(primary_content);
  free(secondary_content);
};

export fn reset(hashmap: *hashmap) void = {
  abort("Not yet implemented");
};
