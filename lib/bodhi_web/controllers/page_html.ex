defmodule BodhiWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use BodhiWeb, :html

  alias Bodhi.Pages.Page

  embed_templates "page_html/*"

  @direct_formats ~w(html text)a

  def render_format_(%Page{format: :markdown} = page, _assigns), do: 
    {:safe, MDEx.to_html!(page.content)}
  def render_format_(%Page{format: :eex} = page, assigns), do:
    {:safe, EEx.eval_string(page.content, [assigns: assigns])}
  def render_format_(%Page{format: format} = page, _assigns) when format in @direct_formats, do:
    {:safe, page.content}
end
