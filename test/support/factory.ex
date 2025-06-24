defmodule Bodhi.Factory do
  @moduledoc """
  Factory module for generating test data.
  """
  
  use ExMachina.Ecto, repo: Bodhi.Repo

  alias Bodhi.Chats.Message
  alias Bodhi.Users.User
  alias Bodhi.Prompts.Prompt

  def chat_factory do
    %{
      id: Faker.random_between(1, 1000),
      title: Faker.Lorem.sentence(),
      user: build(:user)
    }
  end

  def message_factory do
    user = build(:user)

    %Message{
      text: Faker.Lorem.sentence(),
      chat: build(:chat, user: user),
      from: user
    }
  end

  def user_factory do
    %User{
      username: Faker.Internet.user_name(),
      language_code: "en"
    }
  end

  def prompt_factory do
    %Prompt{
      text: Faker.Lorem.sentence()
    }
  end
end
