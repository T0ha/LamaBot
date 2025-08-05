defmodule BodhiWeb.Layouts do
  @moduledoc """
  This module holds different layouts used by your application.

  See the `layouts` directory for all templates available.
  The "root" layout is a skeleton rendered as part of the
  application router. The "app" layout is set as the default
  layout on both `use BodhiWeb, :controller` and
  `use BodhiWeb, :live_view`.
  """
  use BodhiWeb, :html

  embed_templates "layouts/*"
end
