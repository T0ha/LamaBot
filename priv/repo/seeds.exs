# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Bodhi.Repo.insert!(%Bodhi.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

{:ok, bot_user} = Telegex.get_me()
Bodhi.Users.create_or_update_user(bot_user)
