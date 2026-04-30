defmodule Bodhi.Telegram.Formatter do
  @moduledoc """
  Converts markdown text to Telegram-compatible HTML.

  Telegram supports a limited subset of HTML. This module
  renders to: `<b>`, `<i>`, `<s>`, `<code>`, `<pre>`,
  `<pre><code class="language-X">`, `<a href="">`,
  `<blockquote>`.

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

  defguardp safe_url?(url)
            when is_binary(url) and
                   ((byte_size(url) >= 8 and
                       binary_part(url, 0, 8) == "https://") or
                      (byte_size(url) >= 7 and
                         binary_part(url, 0, 7) == "http://") or
                      (byte_size(url) >= 3 and
                         binary_part(url, 0, 3) == "tg:"))

  @doc """
  Formats markdown text to Telegram HTML.

  Returns `{html, [parse_mode: "HTML"]}`.
  """
  @spec format(String.t() | nil) ::
          {String.t(), [{:parse_mode, String.t()}]}
  def format(nil), do: {"", [parse_mode: "HTML"]}
  def format(""), do: {"", [parse_mode: "HTML"]}

  def format(markdown) do
    html =
      case MDEx.parse_document(markdown, @parse_opts) do
        {:ok, doc} ->
          doc.nodes
          |> Enum.map_join("\n\n", &render_node/1)
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
  def format_chunks(nil), do: {[], [parse_mode: "HTML"]}
  def format_chunks(""), do: {[], [parse_mode: "HTML"]}

  def format_chunks(markdown) do
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

  def split(text) do
    text
    |> String.split("\n\n")
    |> chunk_blocks([])
    |> Enum.reverse()
    |> Enum.reject(&(&1 == ""))
    |> case do
      [] -> [""]
      chunks -> chunks
    end
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
    info
    |> String.split(" ", parts: 2)
    |> List.first("")
    |> case do
      "" ->
        "<pre><code>" <> escape(text) <> "</code></pre>"

      lang ->
        "<pre><code class=\"language-#{escape(lang)}\">" <>
          escape(text) <> "</code></pre>"
    end
  end

  defp render_node(%MDEx.Link{url: url, nodes: children})
       when safe_url?(url) do
    "<a href=\"#{escape(url)}\">" <>
      render_children(children) <> "</a>"
  end

  defp render_node(%MDEx.Link{nodes: children}) do
    render_children(children)
  end

  defp render_node(%MDEx.Image{url: url, nodes: children})
       when safe_url?(url) do
    "<a href=\"#{escape(url)}\">" <>
      render_children(children) <> "</a>"
  end

  defp render_node(%MDEx.Image{nodes: children}) do
    render_children(children)
  end

  defp render_node(%MDEx.BlockQuote{nodes: children}) do
    inner = Enum.map_join(children, "\n", &render_node/1)
    "<blockquote>" <> inner <> "</blockquote>"
  end

  defp render_node(%MDEx.List{nodes: items} = list) do
    items
    |> Enum.with_index(list.start)
    |> Enum.map_join("\n", fn {item, idx} ->
      render_list_item(item, list.list_type, idx)
    end)
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
    "• " <> Enum.map_join(item.nodes, "", &render_node/1)
  end

  defp render_list_item(item, :ordered, idx) do
    "#{idx}. " <> Enum.map_join(item.nodes, "", &render_node/1)
  end

  defp render_children(nodes) do
    Enum.map_join(nodes, "", &render_node/1)
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
    chunk_blocks(rest, split_block(block))
  end

  defp chunk_blocks([block | rest], [current | done]) do
    combined = current <> "\n\n" <> block
    combine_or_split(rest, combined, block, current, done)
  end

  defp combine_or_split(rest, combined, _block, _current, done)
       when byte_size(combined) <= @max_length do
    chunk_blocks(rest, [combined | done])
  end

  defp combine_or_split(rest, _combined, block, current, done) do
    chunk_blocks(rest, split_block(block) ++ [current | done])
  end

  defp split_block(block)
       when byte_size(block) <= @max_length do
    [block]
  end

  defp split_block(block) do
    Enum.reverse(hard_split(block))
  end

  # When splitting a rendered HTML block that contains
  # <pre><code> tags, strip the wrapper, split the inner
  # content, and re-wrap each chunk so tags stay balanced.
  defp hard_split(text) do
    case Regex.run(
           ~r/\A(<pre><code[^>]*>)(.*?)(<\/code><\/pre>)\z/s,
           text
         ) do
      [_, open, inner, close] ->
        inner
        |> String.split("\n")
        |> chunk_lines([], @max_length - tag_overhead(open, close))
        |> Enum.reverse()
        |> Enum.map(fn chunk -> open <> chunk <> close end)

      _ ->
        text
        |> String.split("\n")
        |> chunk_lines([])
        |> Enum.reverse()
    end
  end

  defp tag_overhead(open, close) do
    String.length(open) + String.length(close)
  end

  defp chunk_lines(lines, acc, max \\ @max_length)

  defp chunk_lines([], acc, _max), do: acc

  defp chunk_lines([line | rest], acc, max)
       when byte_size(line) > max do
    chunks = split_long_line(line, max)
    chunk_lines(rest, chunks ++ acc, max)
  end

  defp chunk_lines([line | rest], [], max) do
    chunk_lines(rest, [line], max)
  end

  defp chunk_lines([line | rest], [current | done], max) do
    combined = current <> "\n" <> line
    append_or_start(rest, combined, line, current, done, max)
  end

  defp append_or_start(rest, combined, _line, _current, done, max)
       when byte_size(combined) <= max do
    chunk_lines(rest, [combined | done], max)
  end

  defp append_or_start(rest, _combined, line, current, done, max) do
    chunk_lines(rest, [line, current | done], max)
  end

  defp split_long_line(line, max) do
    line
    |> String.graphemes()
    |> Enum.chunk_every(max)
    |> Enum.map(&Enum.join/1)
    |> Enum.reverse()
  end
end
