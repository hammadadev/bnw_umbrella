defmodule BnwDashboardWeb.CattlePurchase.PurchaseTypes.ChangePurchaseTypeComponent do
  @moduledoc """
  ### Live view component for the add/update purchase types modal.
  """
  use BnwDashboardWeb, :live_component
  alias CattlePurchase.PurchaseTypes
  alias BnwDashboardWeb.CattlePurchase.PurchaseType.PurchaseTypeLive

  def mount(socket) do
    {:ok, socket}
  end

  def handle_event("save", %{"purchase_type" => purchase_type}, socket) do
    %{changeset: changeset} = socket.assigns
    changeset = PurchaseTypes.validate(changeset.data, purchase_type)
    if changeset.valid? do
      case PurchaseTypes.create_or_update_purchase_type(changeset.data, purchase_type) do
        {:ok, _purchase_type} ->
          {:noreply, push_patch(socket, to: Routes.live_path(socket, PurchaseTypeLive))}
        {:error, %Ecto.Changeset{} = changest} ->
          {:noreply, assign(socket, changeset: changest)}
      end
      {:noreply, socket}
    else
      {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("validate", %{"purchase_type" => params}, socket) do
    %{changeset: changeset} = socket.assigns
    changeset =
      changeset.data
      |> PurchaseTypes.change_purchase_type(params)
      |> Map.put(:action, :update)
    socket = assign(socket, changeset: changeset)
    {:noreply, socket}
  end
end
