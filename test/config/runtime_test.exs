defmodule Config.RuntimeTest do
  use ExUnit.Case, async: false

  @runtime_config_path "config/runtime.exs"

  setup do
    original_database_url = System.get_env("DATABASE_URL")

    on_exit(fn ->
      case original_database_url do
        nil -> System.delete_env("DATABASE_URL")
        value -> System.put_env("DATABASE_URL", value)
      end
    end)

    :ok
  end

  for env <- [:dev, :test] do
    test "preserves the default Bodhi.Repo config for #{env} " <>
           "when DATABASE_URL is unset" do
      System.delete_env("DATABASE_URL")

      config = read_runtime_config(unquote(env))

      assert config
             |> Keyword.get(:bodhi, [])
             |> Keyword.get(Bodhi.Repo) == nil
    end

    test "overrides the Bodhi.Repo url for #{env} " <>
           "when DATABASE_URL is set" do
      database_url = "ecto://user:pass@host/#{unquote(env)}_db"
      System.put_env("DATABASE_URL", database_url)

      config = read_runtime_config(unquote(env))

      assert config
             |> get_in([:bodhi, Bodhi.Repo, :url]) == database_url
    end

    test "keeps the compile-time Bodhi.Repo pool settings for #{env} " <>
           "once merged with the DATABASE_URL override" do
      database_url = "ecto://user:pass@host/#{unquote(env)}_db"
      System.put_env("DATABASE_URL", database_url)

      compile_time_config = read_compile_time_config(unquote(env))

      merged_repo_config =
        compile_time_config
        |> Config.Reader.merge(read_runtime_config(unquote(env)))
        |> get_in([:bodhi, Bodhi.Repo])

      compile_time_repo_config =
        get_in(compile_time_config, [:bodhi, Bodhi.Repo])

      assert merged_repo_config[:url] == database_url

      assert merged_repo_config[:pool_size] ==
               compile_time_repo_config[:pool_size]

      assert merged_repo_config[:pool] == compile_time_repo_config[:pool]
    end
  end

  defp read_runtime_config(env) do
    Config.Reader.read!(@runtime_config_path, env: env, target: :host)
  end

  defp read_compile_time_config(env) do
    config = Config.Reader.read!("config/config.exs", env: env, target: :host)

    env_config =
      Config.Reader.read!("config/#{env}.exs", env: env, target: :host)

    Config.Reader.merge(config, env_config)
  end
end
