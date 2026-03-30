defmodule Bodhi.Telegram.Formatter do
  @moduledoc """
  Converts markdown text to Telegram-compatible HTML.

  Telegram supports a limited subset of HTML:
  `<b>`, `<i>`, `<u>`, `<s>`, `<code>`, `<pre>`,
  `<pre><code class="language-X">`, `<a href="">`,
  `<blockquote>`, `<tg-spoiler>` (not yet implemented).

  Uses MDEx to parse markdown into an AST, then renders
  each node to the supported HTML subset.

  Note: Telegram counts message length in UTF-16 code
  units, not grapheme clusters. The current `@max_length`
  check uses `String.length/1` (graphemes), which is safe
  for ASCII-heavy LLM output but may under-count for
  text with many non-BMP characters.
  """

  @max_length 4096

  @parse_opts [extension: [strikethrough: true]]

  @doc """
  Formats markdown text to Telegram HTML.

  Returns `{html, [parse_mode: "HTML"]}`.
  """
  @spec format(String.t() | nil) ::
          {String.t(), [{:parse_mode, String.t()}]}
  def format(nil), do: {"", [parse_mode: "HTML"]}
  def format(""), do: {"", [parse_mode: "HTML"]}

  def format(markdown) when is_binary(markdown) do
    html =
      case MDEx.parse_document(markdown, @parse_opts) do
        {:ok, doc} ->
          doc.nodes
          |> Enum.map(&render_node/1)
          |> Enum.join("\n\n")
          |> String.trim()

        {:error, _} ->
          escape(markdown)
      end

    {html, [parse_mode: "HTML"]}
  end

  @doc """
  Formats markdown and splits into chunks safe for
  Telegram (at most 4096 characters each).

  Splits at AST block boundaries to avoid breaking
  HTML tags inside `<pre><code>` blocks.

  Returns `{[chunk], [parse_mode: "HTML"]}`.
  """
  @spec format_chunks(String.t() | nil) ::
          {[String.t()], [{:parse_mode, String.t()}]}
  def format_chunks(nil), do: {[""], [parse_mode: "HTML"]}
  def format_chunks(""), do: {[""], [parse_mode: "HTML"]}

  def format_chunks(markdown) when is_binary(markdown) do
    blocks =
      case MDEx.parse_document(markdown, @parse_opts) do
        {:ok, doc} ->
          doc.nodes
          |> Enum.map(&render_node/1)
          |> Enum.reject(&(&1 == ""))

        {:error, _} ->
          [escape(markdown)]
      end

    chunks =
      blocks
      |> chunk_blocks([])
      |> Enum.reverse()
      |> Enum.reject(&(&1 == ""))

    chunks = if chunks == [], do: [""], else: chunks
    {chunks, [parse_mode: "HTML"]}
  end

  @doc """
  Splits HTML text into chunks of at most 4096 characters.

  Splits at block boundaries (`\\n\\n`) first, then at
  line boundaries (`\\n`) if a single block exceeds the
  limit.
  """
  @spec split(String.t()) :: [String.t()]
  def split(""), do: [""]

  def split(text) when is_binary(text) do
    text
    |> String.split("\n\n")
    |> chunk_blocks([])
    |> Enum.reverse()
  end

  # -- AST rendering --

  defp render_node(%MDEx.Heading{nodes: children}) do
    "<b>" <> render_children(children) <> "</b>"
  end

  defp render_node(%MDEx.Paragraph{nodes: children}) do
    render_children(children)
  end

  defp render_node(%MDEx.Strong{nodes: children}) do
    "<b>" <> render_children(children) <> "</b>"
  end

  defp render_node(%MDEx.Emph{nodes: children}) do
    "<i>" <> render_children(children) <> "</i>"
  end

  defp render_node(%MDEx.Text{literal: text}) do
    escape(text)
  end

  defp render_node(%MDEx.Code{literal: text}) do
    "<code>" <> escape(text) <> "</code>"
  end

  defp render_node(%MDEx.CodeBlock{info: info, literal: text}) do
    lang =
      info
      |> String.split(" ", parts: 2)
      |> List.first("")

    if lang != "" do
      "<pre><code class=\"language-#{escape(lang)}\">" <>
        escape(text) <> "</code></pre>"
    else
      "<pre><code>" <> escape(text) <> "</code></pre>"
    end
  end

  defp render_node(%MDEx.Link{url: url, nodes: children}) do
    if safe_url?(url) do
      "<a href=\"#{escape(url)}\">" <>
        render_children(children) <> "</a>"
    else
      render_children(children)
    end
  end

  defp render_node(%MDEx.Image{url: url, nodes: children}) do
    if safe_url?(url) do
      "<a href=\"#{escape(url)}\">" <>
        render_children(children) <> "</a>"
    else
      render_children(children)
    end
  end

  defp render_node(%MDEx.BlockQuote{nodes: children}) do
    inner =
      children
      |> Enum.map(&render_node/1)
      |> Enum.join("\n")

    "<blockquote>" <> inner <> "</blockquote>"
  end

  defp render_node(%MDEx.List{nodes: items} = list) do
    items
    |> Enum.with_index(list.start)
    |> Enum.map(fn {item, idx} ->
      render_list_item(item, list.list_type, idx)
    end)
    |> Enum.join("\n")
  end

  defp render_node(%MDEx.Strikethrough{nodes: children}) do
    "<s>" <> render_children(children) <> "</s>"
  end

  # Raw HTML in markdown is intentionally escaped to prevent
  # injection. This means `<b>` in user markdown appears as
  # literal text, not as bold — a deliberate safety trade-off.
  defp render_node(%MDEx.HtmlInline{literal: text}) do
    escape(text)
  end

  defp render_node(%MDEx.HtmlBlock{literal: text}) do
    escape(text)
  end

  defp render_node(%MDEx.SoftBreak{}), do: "\n"
  defp render_node(%MDEx.LineBreak{}), do: "\n"
  defp render_node(%MDEx.ThematicBreak{}), do: ""

  defp render_node(_unknown), do: ""

  defp render_list_item(item, :bullet, _idx) do
    inner =
      item.nodes
      |> Enum.map(&render_node/1)
      |> Enum.join("")

    "• " <> inner
  end

  defp render_list_item(item, :ordered, idx) do
    inner =
      item.nodes
      |> Enum.map(&render_node/1)
      |> Enum.join("")

    "#{idx}. " <> inner
  end

  defp render_children(nodes) do
    Enum.map_join(nodes, "", &render_node/1)
  end

  # -- URL validation --

  @allowed_schemes ["http", "https", "tg"]

  defp safe_url?(url) do
    case URI.parse(url) do
      %URI{scheme: scheme} when not is_nil(scheme) ->
        String.downcase(scheme) in @allowed_schemes

      _ ->
        # Relative URLs or fragment-only are safe
        not String.starts_with?(url, "javascript:")
    end
  end

  # -- HTML escaping --

  defp escape(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
  end

  # -- Splitting --

  defp chunk_blocks([], acc), do: acc

  defp chunk_blocks([block | rest], []) do
    if String.length(block) <= @max_length do
      chunk_blocks(rest, [block])
    else
      chunk_blocks(rest, hard_split(block))
    end
  end

  defp chunk_blocks([block | rest], [current | done]) do
    combined = current <> "\n\n" <> block

    if String.length(combined) <= @max_length do
      chunk_blocks(rest, [combined | done])
    else
      if String.length(block) <= @max_length do
        chunk_blocks(rest, [block, current | done])
      else
        chunk_blocks(
          rest,
          hard_split(block) ++ [current | done]
        )
      end
    end
  end

  defp hard_split(text) do
    text
    |> String.split("\n")
    |> chunk_lines([])
  end

  defp chunk_lines([], acc), do: acc

  defp chunk_lines([line | rest], acc) do
    if String.length(line) > @max_length do
      chunks = split_long_line(line)
      chunk_lines(rest, chunks ++ acc)
    else
      case acc do
        [] ->
          chunk_lines(rest, [line])

        [current | done] ->
          combined = current <> "\n" <> line

          if String.length(combined) <= @max_length do
            chunk_lines(rest, [combined | done])
          else
            chunk_lines(rest, [line, current | done])
          end
      end
    end
  end

  defp split_long_line(line) do
    line
    |> String.graphemes()
    |> Enum.chunk_every(@max_length)
    |> Enum.map(&Enum.join/1)
    |> Enum.reverse()
  end
end
