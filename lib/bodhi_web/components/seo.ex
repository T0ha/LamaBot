defmodule BodhiWeb.Components.Seo do
  @moduledoc """
  SEO and OG components.
  """
  use Phoenix.Component
  use BodhiWeb, :verified_routes

  @doc """
  Renders SEO meta tags.

  ## Examples

      <.seo
        title="Page Title"
        description="Page description"
        url="https://example.com/page"
        image="https://example.com/image.jpg"
      />
  """
  attr :title, :string, required: true
  attr :keywords, :list, required: false, default: []
  attr :description, :string, required: true
  attr :author, :string, required: false, default: nil
  attr :url, :string, required: true
  attr :image, :string, required: false, default: nil

  def seo(assigns) do
    assigns =
      assigns
      # TODO: currently for simplicity we assume @url is the domain
      |> assign_new(:domain, fn -> assigns.url end)
      |> assign_new(:image_url, fn %{domain: domain} ->
        URI.append_path(URI.parse(domain), assigns.image)
      end)

    ~H"""
    <link rel="canonical" href={@url}/>
    <meta name="description" content={@description} />

    <%= if @keywords do %>
      <meta name="keywords" content={Enum.join(@keywords, ", ")}/>
    <% end %>
    <%= if @author do %>
      <meta name="author" content={@author}/>
      <% end %>
      <meta name="robots" content="index, follow"/>

      <!-- Facebook Meta Tags -->
    <meta property="og:url" content={@url}/>
    <meta property="og:type" content="website"/>
    <meta property="og:title" content={@title} />
    <meta property="og:description" content={@description} />
    <%= if @image do %>
      <meta property="og:image" content={@image} />
    <% end %>

      <!-- Twitter Meta Tags -->
      <meta name="twitter:card" content="summary_large_image" />
      <meta property="twitter:domain" content={@domain} />
      <meta property="twitter:url" content={@url} />
      <meta name="twitter:title" content={@title} />
      <meta name="twitter:description" content={@description} />
    <%= if @image do %>
      <meta name="twitter:image" content={@image_url} />
      <% end %>
    """
  end
end
