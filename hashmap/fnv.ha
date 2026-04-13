use strings;
use fmt;

const fnv1_offset_basis: size = 0xcbf29ce484222325;
const fnv1_prime: size = 0x100000001b3;

fn fnv1a(key: []u8) size = {
  let hash: size = fnv1_offset_basis;
  let i = 0z;
  for (let char .. key) {
    hash ^= char: size;
    hash *= fnv1_prime;
  };
  return hash;
};

@test fn fnv1a() void = {
  const key = "somekey";
  const vectors: [](str, size) = [
    ("somekey", 0x31da2f530769e478),
    ("s", 0xaf63ee4c86020b22),
    ("somethingabitlonger", 0x893a0c7ad686fabc),
    ("Nulla voluptatem et necessitatibus recusandae ut laudantium. Soluta nesciunt nihil maxime eveniet aut. Dolore maxime ut distinctio repellat porro dolorem officia voluptatem. Non laborum vel labore. Consequuntur voluptas officia harum quas repudiandae. Et ullam odit iure minus suscipit ex.", 0x8c81b27ab9026c4c)
  ];
  for (let vector .. vectors) {
    assert(fnv1a(strings::toutf8(vector.0)) == vector.1);
  };
};
