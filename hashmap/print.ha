use io;
use fmt;
use strings;
use encoding::utf8;
use types;

export fn print(hashmap: *hashmap) (void|io::error) = {
  inner_print(hashmap.primary_content)?;
  inner_print(hashmap.secondary_content)?;
};

fn inner_print(content: [](void|kv)) (void|io::error) = {
  for(let item .. content) {
    if (item is void)
      continue;
    const item = item as kv;
    const key = match (strings::fromutf8(item.key)) {
    case let key: str => yield key;
    case utf8::invalid => "<invalid utf8>";
    };
    match (item.value) {
    case let pointer: *opaque => fmt::printf("[ {} ] => {}\n", key, pointer)?;
    case let string: str => fmt::printf("[ {} ] => \"{}\"\n", key, string)?;
    case let other: (...types::numeric | uintptr | str | rune | bool) => fmt::printf("[ {} ] => {}\n", key, other)?;
    };
  };
};

export fn print_values(hashmap: *hashmap) (void|io::error) = {
  fmt::printf("values:\n")?;
  fmt::printf("primary_content: ")?;
  inner_print_values(hashmap.primary_content)?;
  fmt::printf("secondary_content: ")?;
  inner_print_values(hashmap.secondary_content)?;
};

fn inner_print_values(content: [](void|kv)) (void|io::error) = {
  fmt::printf("[ ")?;
  if (content[0] is void) {
    fmt::printf("empty")?;
  } else {
    match ((content[0]: kv).value) {
    case let pointer: *opaque => fmt::printf("{}", pointer)?;
    case let string: str => fmt::printf("\"{}\"", string)?;
    case let other: (...types::numeric | uintptr | str | rune | bool) => fmt::printf("{}", other)?;
    };
  };
  let i = 1z;
  for (i < len(content); i += 1) {
    if (content[i] is void) {
      fmt::printf(", empty")?;
      continue;
    };
    match ((content[i]: kv).value) {
    case let pointer: *opaque => fmt::printf(", {}", pointer)?;
    case let string: str => fmt::printf(", \"{}\"", string)?;
    case let other: (...types::numeric | uintptr | str | rune | bool) => fmt::printf(", {}", other)?;
    };
  };
  fmt::printf(" ]\n")?;
};

export fn print_keys(hashmap: *hashmap) (void|io::error) = {
  fmt::printf("keys:\n")?;
  fmt::printf("primary_content: ")?;
  inner_print_keys(hashmap.primary_content)?;
  fmt::printf("secondary_content: ")?;
  inner_print_keys(hashmap.secondary_content)?;
};

// BUG: Keys are all void for some reason
fn inner_print_keys(content: [](void|kv)) (void|io::error) = {
  fmt::printf("[ ")?;
  if (content[0] is void) {
    fmt::printf("empty")?;
  } else {
    const key = match (strings::fromutf8((content[0]: kv).key)) {
    case let key: str => key;
    case utf8::invalid => "<invalid utf8>";
    };
    fmt::printf("{}", key)?;
  };
  let i = 1z;
  for (i < len(content); i += 1) {
    if (content[i] is void) {
      fmt::printf(", empty")?;
      continue;
    };
    const key = match (strings::fromutf8((content[i] as kv).key)) {
    case let key: str => key;
    case utf8::invalid => "<invalid utf8>";
    };
    fmt::printf(", {}", key)?;
  };
  fmt::printf(" ]\n")?;
};
