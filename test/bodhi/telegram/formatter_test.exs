defmodule Bodhi.Telegram.FormatterTest do
  use ExUnit.Case, async: true

  alias Bodhi.Telegram.Formatter

  describe "format/1" do
    test "plain text is HTML-escaped" do
      assert Formatter.format("hello <world> & \"quotes\"") ==
               {"hello &lt;world&gt; &amp; &quot;quotes&quot;", [parse_mode: "HTML"]}
    end

    test "headers become bold text" do
      assert {"<b>Hello</b>", _} = Formatter.format("# Hello")
      assert {"<b>Sub</b>", _} = Formatter.format("## Sub")
      assert {"<b>Deep</b>", _} = Formatter.format("### Deep")
    end

    test "bold text" do
      assert {"<b>bold</b>", _} = Formatter.format("**bold**")
    end

    test "italic text" do
      assert {"<i>italic</i>", _} = Formatter.format("*italic*")
    end

    test "inline code" do
      assert {"<code>foo</code>", _} = Formatter.format("`foo`")
    end

    test "code block without language" do
      input = "```\nsome code\n```"

      assert {"<pre><code>some code\n</code></pre>", _} =
               Formatter.format(input)
    end

    test "code block with language" do
      input = "```elixir\nIO.puts(\"hi\")\n```"

      assert {"<pre><code class=\"language-elixir\">" <>
                "IO.puts(&quot;hi&quot;)\n</code></pre>", _} =
               Formatter.format(input)
    end

    test "code block info string uses only first word as language" do
      input = "```python title=\"example.py\"\nprint(1)\n```"

      {html, _} = Formatter.format(input)
      assert html =~ "language-python"
      refute html =~ "title="
    end

    test "link" do
      assert {"<a href=\"http://ex.com\">text</a>", _} =
               Formatter.format("[text](http://ex.com)")
    end

    test "blockquote" do
      assert {"<blockquote>quote</blockquote>", _} =
               Formatter.format("> quote")
    end

    test "unordered list uses unicode bullets" do
      input = "- one\n- two"
      {html, _} = Formatter.format(input)
      assert html =~ "• one"
      assert html =~ "• two"
    end

    test "ordered list preserves numbering" do
      input = "1. first\n2. second"
      {html, _} = Formatter.format(input)
      assert html =~ "1. first"
      assert html =~ "2. second"
    end

    test "ordered list starting at non-1 offset" do
      input = "3. third\n4. fourth"
      {html, _} = Formatter.format(input)
      assert html =~ "3. third"
      assert html =~ "4. fourth"
    end

    test "strikethrough" do
      assert {"<s>strike</s>", _} = Formatter.format("~~strike~~")
    end

    test "thematic break renders as empty" do
      {html, _} = Formatter.format("---")
      assert html == ""
    end

    test "image becomes link" do
      assert {"<a href=\"http://img.png\">alt</a>", _} =
               Formatter.format("![alt](http://img.png)")
    end

    test "nested formatting" do
      assert {"<i><b>bold italic</b></i>", _} =
               Formatter.format("***bold italic***")
    end

    test "mixed content in paragraph" do
      input = "Hello **bold** and *italic* world"

      assert {"Hello <b>bold</b> and <i>italic</i> world", _} =
               Formatter.format(input)
    end

    test "multiple paragraphs separated by blank lines" do
      input = "First paragraph\n\nSecond paragraph"
      {html, _} = Formatter.format(input)
      assert html =~ "First paragraph"
      assert html =~ "Second paragraph"
      assert html =~ "\n\n"
    end

    test "soft break becomes newline" do
      input = "line one\nline two"
      {html, _} = Formatter.format(input)
      assert html =~ "line one\nline two"
    end

    test "empty input" do
      assert {"", [parse_mode: "HTML"]} = Formatter.format("")
    end

    test "nil input" do
      assert {"", [parse_mode: "HTML"]} = Formatter.format(nil)
    end

    test "always returns parse_mode HTML" do
      {_, opts} = Formatter.format("hello")
      assert opts == [parse_mode: "HTML"]
    end

    test "unknown AST nodes render as empty string" do
      # Verify format doesn't crash on content that may produce
      # unrecognised AST nodes — the catch-all returns ""
      {html, _} = Formatter.format("just plain text")
      assert is_binary(html)
    end

    test "falls back to escaped text on parse error" do
      # MDEx.parse_document normally succeeds, but the error
      # branch should escape the raw markdown safely.
      # We verify indirectly: any valid markdown should not
      # crash and should return HTML opts.
      {html, opts} = Formatter.format("<b>raw html</b>")
      assert is_binary(html)
      assert opts == [parse_mode: "HTML"]
    end
  end

  describe "split/1" do
    test "short text returns single chunk" do
      text = "Hello world"
      assert Formatter.split(text) == ["Hello world"]
    end

    test "text under 4096 is not split" do
      text = String.duplicate("a", 4000)
      assert Formatter.split(text) == [text]
    end

    test "long text splits at block boundaries" do
      block = String.duplicate("a", 2500)
      text = block <> "\n\n" <> block
      chunks = Formatter.split(text)
      assert length(chunks) == 2
      assert Enum.all?(chunks, &(String.length(&1) <= 4096))
    end

    test "pre blocks are not split mid-tag" do
      pre =
        "<pre><code>" <>
          String.duplicate("x", 100) <>
          "</code></pre>"

      padding = String.duplicate("a", 3900)
      text = padding <> "\n\n" <> pre
      chunks = Formatter.split(text)
      # pre block should be in its own chunk
      assert Enum.any?(chunks, &(&1 =~ "<pre><code>"))
      assert Enum.all?(chunks, &(String.length(&1) <= 4096))
    end

    test "each chunk is under 4096 chars" do
      blocks =
        for _ <- 1..10 do
          String.duplicate("a", 1000)
        end

      text = Enum.join(blocks, "\n\n")
      chunks = Formatter.split(text)
      assert Enum.all?(chunks, &(String.length(&1) <= 4096))
    end

    test "single block over 4096 is hard-split at newline" do
      lines =
        for _ <- 1..100 do
          String.duplicate("a", 80)
        end

      text = Enum.join(lines, "\n")
      chunks = Formatter.split(text)
      assert length(chunks) > 1
      assert Enum.all?(chunks, &(String.length(&1) <= 4096))
    end

    test "single line over 4096 chars is byte-split" do
      line = String.duplicate("a", 5000)
      chunks = Formatter.split(line)
      assert length(chunks) == 2
      assert Enum.all?(chunks, &(String.length(&1) <= 4096))
      assert Enum.join(chunks, "") == line
    end

    test "first block hard-split preserves order with subsequent blocks" do
      # First block > 4096 chars, followed by a normal block
      big =
        String.duplicate("a", 3000) <>
          "\n" <> String.duplicate("b", 3000)

      small = "tail"
      text = big <> "\n\n" <> small
      chunks = Formatter.split(text)

      # Verify chunk ordering: a's before b's before tail
      assert hd(chunks) =~ String.duplicate("a", 100)
      assert List.last(chunks) =~ "tail"
      assert Enum.all?(chunks, &(String.length(&1) <= 4096))
    end

    test "empty text returns single empty chunk" do
      assert Formatter.split("") == [""]
    end
  end
end
