defmodule Bodhi.PeriodicMessages do
  @day_in_sec 3600 * 24

  use Oban.Worker,
    queue: :messages,
    unique: [period: @day_in_sec],
    max_attempts: 1

  alias Bodhi.Prompts
  alias Bodhi.Prompts.Prompt
  alias Bodhi.Users
  alias Bodhi.Users.User

  def create_for_new_user(type, {period, unit} = p, chat_id) do
    %{
      "message_type" => type,
      "chat_id" => chat_id,
      "peiod" => period,
      "unit" => unit
    }
    |> new(schedule_in: p)
    |> Oban.insert!()
  end

  @impl true
  def perform(%Oban.Job{
        args:
          %{
            "message_type" => type,
            "chat_id" => chat_id,
            "peiod" => period,
            "unit" => unit
          } = args
      }) do
    %User{language_code: lang} = Users.get_by_chat!(chat_id)
    %Prompt{text: text} = Prompts.get_random_prompt_by_type_and_lang(String.to_atom(type), lang)
    Bodhi.TgWebhookHandler.send_message(chat_id, text)

    args
    |> new(schedule_in: {period, String.to_atom(unit)})
    |> Oban.insert!()

    :ok
  end
end
