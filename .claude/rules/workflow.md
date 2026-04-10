# Feature Implementation Flow

- Plan the feature and ask for feedback
- Create a new branch from `main` for the feature
- Implement tests first (TDD) and ask for approve
- Implement the feature code
- Run checks and fix any issues
- If no failed checks and everything is clarifyed commit changes with clear messages
- Create a pull request and ask for review
- Address any feedback from the review

## Code Checks

- Make sure code is compilable by `mix compile` and has no warnings
- Make sure code runs in `iex -S mix` without errors
- Run all tests with `mix test` and ensure they pass
- Run `mix credo` to check for code quality issues and fix them
- Check with `mix dialyzer` for type issues
- Update documentation and AGENTS.md if needed
- Run `mix format` to ensure code style compliance
