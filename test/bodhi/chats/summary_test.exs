defmodule Bodhi.Chats.SummaryTest do
  use Bodhi.DataCase

  alias Bodhi.Chats.Summary

  describe "changeset/2" do
    test "valid attrs create a valid changeset" do
      chat = insert(:chat)

      attrs = %{
        chat_id: chat.id,
        summary_text: "A test summary",
        summary_date: ~D[2024-01-01],
        message_count: 5
      }

      changeset = Summary.changeset(%Summary{}, attrs)
      assert changeset.valid?
    end

    test "requires chat_id" do
      attrs = %{
        summary_text: "A test summary",
        summary_date: ~D[2024-01-01],
        message_count: 5
      }

      changeset = Summary.changeset(%Summary{}, attrs)
      assert %{chat_id: ["can't be blank"]} = errors_on(changeset)
    end

    test "requires summary_text" do
      attrs = %{
        chat_id: 1,
        summary_date: ~D[2024-01-01],
        message_count: 5
      }

      changeset = Summary.changeset(%Summary{}, attrs)

      assert %{summary_text: ["can't be blank"]} =
               errors_on(changeset)
    end

    test "requires summary_date" do
      attrs = %{
        chat_id: 1,
        summary_text: "A test summary",
        message_count: 5
      }

      changeset = Summary.changeset(%Summary{}, attrs)

      assert %{summary_date: ["can't be blank"]} =
               errors_on(changeset)
    end

    test "defaults message_count to 0" do
      attrs = %{
        chat_id: 1,
        summary_text: "A test summary",
        summary_date: ~D[2024-01-01]
      }

      changeset = Summary.changeset(%Summary{}, attrs)
      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :message_count) == 0
    end

    test "validates message_count >= 0" do
      attrs = %{
        chat_id: 1,
        summary_text: "A test summary",
        summary_date: ~D[2024-01-01],
        message_count: -1
      }

      changeset = Summary.changeset(%Summary{}, attrs)

      assert %{
               message_count: [
                 "must be greater than or equal to 0"
               ]
             } = errors_on(changeset)
    end

    test "validates summary_text min length" do
      attrs = %{
        chat_id: 1,
        summary_text: "",
        summary_date: ~D[2024-01-01],
        message_count: 5
      }

      changeset = Summary.changeset(%Summary{}, attrs)

      assert %{summary_text: [_]} = errors_on(changeset)
    end

    test "enforces unique constraint on chat_id + date" do
      chat = insert(:chat)
      date = ~D[2024-06-15]
      insert(:summary, chat: chat, summary_date: date)

      attrs = %{
        chat_id: chat.id,
        summary_text: "Duplicate",
        summary_date: date,
        message_count: 3
      }

      assert {:error, changeset} =
               %Summary{}
               |> Summary.changeset(attrs)
               |> Repo.insert()

      assert %{chat_id: ["has already been taken"]} =
               errors_on(changeset)
    end

    test "accepts optional fields" do
      chat = insert(:chat)

      attrs = %{
        chat_id: chat.id,
        summary_text: "A test summary",
        summary_date: ~D[2024-01-01],
        message_count: 5,
        start_time: ~N[2024-01-01 08:00:00],
        end_time: ~N[2024-01-01 20:00:00],
        ai_model: "Gemini"
      }

      changeset = Summary.changeset(%Summary{}, attrs)
      assert changeset.valid?
    end
  end
end
