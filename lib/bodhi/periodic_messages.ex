defmodule Bodhi.PeriodicMessages do
  @day_in_sec 3600 * 24
  @followup_threshold 2

  use Oban.Worker,
    queue: :messages,
    unique: [period: @day_in_sec],
    max_attempts: 1

  alias Bodhi.Chats
  alias Bodhi.Chats.Message
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
            "chat_id" => chat_id,
            "peiod" => period,
            "unit" => unit
          } = args
      }) do
    %Message{user_id: from_id, inserted_at: inserted_at} =  Chats.get_last_message(chat_id)

    now = DateTime.utc_now()
    diff =  DateTime.diff(now, inserted_at, :day)

    case {from_id, diff} do
      {^chat_id, 0} -> :ok
      {^chat_id, 1} -> do_send_folloup(args)
      {_, @followup_threshold} -> do_send_folloup(args)
      _ -> :ok
    end

    args
    |> new(schedule_in: {period, String.to_atom(unit)})
    |> Oban.insert!()

  end


  defp do_send_folloup(
          %{
            "message_type" => type,
            "chat_id" => chat_id
          }
  ) do
    %User{language_code: lang} = Users.get_by_chat!(chat_id)
    %Prompt{text: text} = Prompts.get_random_prompt_by_type_and_lang(String.to_atom(type), lang)
    Bodhi.TgWebhookHandler.send_message(chat_id, text)
  end
end
