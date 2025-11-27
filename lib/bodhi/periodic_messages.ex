defmodule Bodhi.PeriodicMessages do
  @moduledoc """
  Periodicc messages workflow routines
  """

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

  @spec create_for_new_user(atom(), {non_neg_integer(), atom()}, non_neg_integer()) ::
          Oban.Job.t()
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
  @spec perform(Oban.Job.t()) :: :ok | {:error, term()}
  def perform(%Oban.Job{
        args:
          %{
            "chat_id" => chat_id,
            "peiod" => period,
            "unit" => unit
          } = args
      }) do
    %Message{user_id: from_id, inserted_at: inserted_at} = Chats.get_last_message(chat_id)

    diff =
      :second
      |> DateTime.utc_now()
      |> DateTime.diff(DateTime.from_naive!(inserted_at, "Etc/UTC"), :day)

    case {from_id, diff} do
      {^chat_id, 0} -> :ok
      {^chat_id, 1} -> do_send_folloup(args)
      _ when diff >= @followup_threshold -> do_send_folloup(args)
      _ -> :ok
    end

    args
    |> new(schedule_in: {period, String.to_atom(unit)})
    |> Oban.insert!()

    :ok
  end

  defp do_send_folloup(%{
         "message_type" => type,
         "chat_id" => chat_id
       }) do
    %User{language_code: lang} = user = Users.get_by_chat!(chat_id)

    %Prompt{id: prompt_id, text: text} =
      Prompts.get_random_prompt_by_type_and_lang(String.to_atom(type), lang)

    PostHog.capture("followup_sent", %{
      distinct_id: user.id,
      locale: lang,
      "$current_url": BodhiWeb.Endpoint.host(),
      prompt_id: prompt_id
    })

    Bodhi.TgWebhookHandler.send_message(chat_id, text)
  end
end
