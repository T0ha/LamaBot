defmodule Bodhi.Factory do
  @moduledoc """
  Factory module for generating test data.
  """

  use ExMachina.Ecto, repo: Bodhi.Repo

  alias Bodhi.Chats.{Chat, Message}
  alias Bodhi.Users.User
  alias Bodhi.Prompts.Prompt

  def chat_factory do
    id = Faker.random_between(1, 1000)

    %Chat{
      id: id,
      title: Faker.Lorem.sentence(),
      user: build(:user, id: id),
      type: Faker.Lorem.word()
    }
  end

  def message_factory do
    user = build(:user)

    %Message{
      text: Faker.Lorem.sentence(),
      caption: Faker.Lorem.sentence(),
      date: Faker.random_between(1_000_000_000, 2_000_000_000),
      chat: build(:chat, user: user),
      from: user
    }
  end

  def user_factory do
    %User{
      first_name: Faker.Person.first_name(),
      last_name: Faker.Person.last_name(),
      username: Faker.Internet.user_name(),
      language_code: "en"
    }
  end

  def prompt_factory do
    %Prompt{
      text: Faker.Lorem.sentence(),
      type: Faker.Util.pick([:start_message, :context, :followup])
    }
  end

  def page_factory do
    %Bodhi.Pages.Page{
      slug: Faker.Internet.slug(),
      header: false,
      title: Faker.Lorem.sentence(),
      description: Faker.Lorem.sentence(),
      template: "page",
      format: Faker.Util.pick([:markdown, :html, :text, :eex]),
      content: Faker.Lorem.paragraph()
    }
  end
end
