defmodule Bodhi.PeriodicMessages do
  use Oban.Worker,
    queue: :messages,
    max_attempts: 1

  alias Bodhi.Prompts
  alias Bodhi.Prompts.Prompt

  def create_for_new_user(type, {period, unit} = p, chat_id, lang \\ "en") do
    %{
      "message_type" => type,
      "chat_id" => chat_id,
      "peiod" => period,
      "unit" => unit,
      "lang" => lang
    }
    |> new(schedule_in: p)
    |> Oban.insert!()

  end

  @impl true
  def perform(%Oban.Job{
    args: %{
      "message_type" => type,
      "chat_id" => chat_id,
      "peiod" => period,
      "unit" => unit,
      "lang" => lang
    } = args
  }
  ) do
    %Prompt{text: text} = Prompts.get_random_prompt_by_type_and_lang(String.to_atom(type), lang)
    Telegex.send_message(chat_id, text)

    args
    |> new(schedule_in: {period, String.to_atom(unit)})
    |> Oban.insert!()

    :ok
  end
end
