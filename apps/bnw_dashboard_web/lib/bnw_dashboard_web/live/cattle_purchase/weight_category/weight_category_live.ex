defmodule BnwDashboardWeb.CattlePurchase.WeightCategory.WeightCategoryLive do
  use BnwDashboardWeb, :live_view
  alias CattlePurchase.{
    Authorize,
    WeightCategories
  }
  alias BnwDashboardWeb.CattlePurchase.WeightCategories.ChangeWeightCategoryComponent

  defp authenticate(socket) do
    current_user = Map.get(socket.assigns, :current_user)
    cond do
      current_user && Authorize.authorize(current_user, "weight_categories") ->
        true
      true ->
        false
    end
  end

  @impl true
  def mount(_, session, socket) do
    socket =
      assign_defaults(session, socket)
      |> assign(
        page_title: "BNW Dashboard · Weight Category",
        app: "Cattle Purchase",
        weight_categories: WeightCategories.list_weight_categories(),
        modal: nil
      )
    if connected?(socket) do
      WeightCategories.subscribe()
    end
    case authenticate(socket) do
      true -> {:ok, socket}
      false -> {:ok, redirect(socket, to: "/")}
    end
  end

  @impl true
  def handle_params(_,_, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("new", _, socket) do
    changeset = WeightCategories.new_weight_category()
    socket = assign(socket, changeset: changeset, modal: :change_weight_category)
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel", _, socket) do
    socket = assign(socket, modal: nil)
    {:noreply, socket}
  end
end
