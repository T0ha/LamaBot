defmodule Bodhi.Factory do
  @moduledoc """
  Factory module for generating test data.
  """

  use ExMachina.Ecto, repo: Bodhi.Repo

  alias Bodhi.Chats.{Chat, LlmResponse, Message, Summary}
  alias Bodhi.LlmConfigs.LlmConfig
  alias Bodhi.Users.User
  alias Bodhi.Prompts.Prompt

  def chat_factory do
    id = Faker.random_between(1, 1_000_000)

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

  def summary_factory do
    %Summary{
      summary_text: Faker.Lorem.paragraph(),
      summary_date: Faker.Date.backward(30),
      message_count: Faker.random_between(1, 50),
      start_time: ~N[2024-01-01 08:00:00],
      end_time: ~N[2024-01-01 20:00:00],
      ai_model: "LLMMock",
      chat: build(:chat)
    }
  end

  def llm_response_factory do
    %LlmResponse{
      ai_model: "openrouter/test-model",
      prompt_tokens: Faker.random_between(10, 500),
      completion_tokens: Faker.random_between(10, 200)
    }
  end

  def prompt_factory do
    %Prompt{
      text: Faker.Lorem.sentence(),
      type: Faker.Util.pick([:start_message, :context, :followup])
    }
  end

  def llm_config_factory do
    %LlmConfig{
      name: sequence(:llm_config_name, &"config-#{&1}"),
      model:
        sequence(
          :llm_config_model,
          &"provider/model-#{&1}"
        ),
      position: sequence(:llm_config_position, & &1),
      temperature: nil,
      max_tokens: nil,
      active: false
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
