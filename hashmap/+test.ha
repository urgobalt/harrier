use strings;
use strconv::{ztos};
use fmt;
use types;

@test fn hashmap_basic_interactions() void = {
  const hashmap = init()!;
  const vectors: [](str, value) = [
    ("somekey", "somekey"),
    ("s", 0xaf63ee4c86020b22: size),
    ("Nulla voluptatem et necessitatibus recusandae ut laudantium. Soluta nesciunt nihil maxime eveniet aut. Dolore maxime ut distinctio repellat porro dolorem officia voluptatem. Non laborum vel labore. Consequuntur voluptas officia harum quas repudiandae. Et ullam odit iure minus suscipit ex.", 127: u8),
    ("Me, Myself and I", &hashmap),
  ];

  for (let vector .. vectors) {
    assert(get(&hashmap, strings::toutf8(vector.0)) is void);
  };

  for (let vector .. vectors) {
    put(&hashmap, strings::toutf8(vector.0), vector.1)!;
    assert(get(&hashmap, strings::toutf8(vector.0)) is *value);
  };

  assert(*(get(&hashmap, strings::toutf8(vectors[0].0)) as *value) is str);
  assert(*(get(&hashmap, strings::toutf8(vectors[1].0)) as *value) is size);
  assert(*(get(&hashmap, strings::toutf8(vectors[2].0)) as *value) is u8);
  assert(*(get(&hashmap, strings::toutf8(vectors[3].0)) as *value) is *opaque);

  assert(pop(&hashmap, strings::toutf8(vectors[0].0)) as value is str);
  assert(pop(&hashmap, strings::toutf8(vectors[1].0)) as value is size);
  assert(pop(&hashmap, strings::toutf8(vectors[2].0)) as value is u8);
  assert(pop(&hashmap, strings::toutf8(vectors[3].0)) as value is *opaque);

  assert(hashmap.count == 0);
};

@test fn hashmap_fill() void = {
  const hashmap = init()!;
  for (let i: size = 0; i < initial_capacity*2; i += 1) {
    put(&hashmap, strings::toutf8(ztos(i)), i)!;
  };

  print_values(&hashmap)!;
};
