defmodule BodhiWeb.PageLive.Form do
  use BodhiWeb, :live_view

  alias Bodhi.Pages
  alias Bodhi.Pages.Page

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.admin flash={@flash}>
      <.header>
        {@page.title}
        <:subtitle>Use this form to manage page records in your database.</:subtitle>
      </.header>

      <.form for={@form} id="page-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:slug]} type="text" label="Slug" />
        <.input field={@form[:header]} type="checkbox" label="Header" />
        <.input field={@form[:title]} type="text" label="Title" />`
        <.input field={@form[:description]} type="text" label="Description" />
        <.input
          field={@form[:format]}
          type="select"
          label="Format"
          prompt="Choose a value"
          options={Ecto.Enum.values(Bodhi.Pages.Page, :format)}
        />
        <.input
          field={@form[:template]}
          type="select"
          label="Template"
          prompt="Choose a template"
          options={template_options()}
        />
        <.input field={@form[:content]} type="textarea" label="Content" />
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Page</.button>
          <.button navigate={return_path(@return_to, @page)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.admin>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    page = Pages.get_page!(id)

    socket
    |> assign(:page, page)
    |> assign(:form, to_form(Pages.change_page(page)))
  end

  defp apply_action(socket, :new, _params) do
    page = %Page{}

    socket
    |> assign(:page, page)
    |> assign(:form, to_form(Pages.change_page(page)))
  end

  @impl true
  def handle_event("validate", %{"page" => page_params}, socket) do
    changeset = Pages.change_page(socket.assigns.page, page_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"page" => page_params}, socket) do
    save_page(socket, socket.assigns.live_action, page_params)
  end

  defp save_page(socket, :edit, page_params) do
    case Pages.update_page(socket.assigns.page, page_params) do
      {:ok, page} ->
        {:noreply,
         socket
         |> put_flash(:info, "Page updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, page))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_page(socket, :new, page_params) do
    case Pages.create_page(page_params) do
      {:ok, page} ->
        {:noreply,
         socket
         |> put_flash(:info, "Page created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, page))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _page), do: ~p"/pages"
  defp return_path("show", page), do: ~p"/pages/#{page}"

  defp template_options do
    BodhiWeb.PageHTML.__info__(:functions)
    |> Enum.map(fn {func, _arity} -> to_string(func) end)
    |> Enum.filter(&(!String.starts_with?(&1, "__") and !String.ends_with?(&1, "_")))
  end
end
