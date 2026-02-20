# Feature Implementation Flow

! Never chsnge branches or commit anything to `git` without confirmation!

1. Plan the feature and ask for feedback
2. Implement tests first (TDD) and ask for approve
3. Implement the feature code
4. Make sure code is compilable by `mix compile` and has no warnings
5. Run all tests with `mix test` and ensure they pass
6. Make sure code runs in `iex -S mix` without errors
7. Check with `mix dialyzer` for type issues
8. Update documentation and AGENTS.md if needed
9. Run `mix format` to ensure code style compliance

