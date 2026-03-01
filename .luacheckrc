std = "lua54"

codes = true
max_line_length = false

exclude_files = {
  ".direnv/**",
}

read_globals = {
  vim = {
    other_fields = true,
  },
}

files["tests/**.lua"] = {
  globals = {
    "describe",
    "it",
    "before_each",
    "after_each",
    "setup",
    "teardown",
    "pending",
  },
}
