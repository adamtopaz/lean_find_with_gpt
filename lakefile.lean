import Lake
open Lake DSL

package «lean_find_with_gpt» {
  -- add package configuration options here
}

lean_lib «LeanFindWithGpt» {
  -- add library configuration options here
}

@[default_target]
lean_exe «lean_find_with_gpt» {
  root := `Main
}
