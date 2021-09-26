defmodule BnwDashboardWeb.CattlePurchase.Purchase.PurchaseCommissionComponent do
  @moduledoc """
  ### Live view component for the add/update purchase modal.
  """
  use BnwDashboardWeb, :live_component
  alias CattlePurchase.{Commissions, Commission, Repo}
  alias BnwDashboardWeb.CattlePurchase.Purchase.PurchaseLive

  def mount(socket) do
    {:ok, socket}
  end

  def handle_event("save", %{"commission" => commission}, socket) do
    %{
      commission_changeset: commission_changeset,
      commissions_in_form: commissions_in_form,
      commission_edit_phase: commission_edit_phase,
      commissions_from_db: commissions_from_db
    } = socket.assigns

    %{"button" => button} = commission
    {purchase_id, ""} = Integer.parse(commission["purchase_id"] || 1)
    commission_changeset = Commissions.validate(commission_changeset.data, commission)
    commissions_in_form = format_commissions(commission, commissions_in_form)
    purchase = CattlePurchase.Repo.get(CattlePurchase.Purchase, purchase_id)

    if is_all_commissions_valid(commissions_in_form) do
      commissions_to_save =
        if commission_edit_phase do
          CattlePurchase.Purchase.changeset(purchase, %{commissions: commissions_in_form})
        else
          commissions_in_form
          |> remove_valid_key_add_purchase_id(purchase_id)
          |> Enum.map(fn commission -> Commissions.validate(%Commission{}, commission) end)
        end


      result =
        case commission_edit_phase do
          true ->
            CattlePurchase.Repo.update(commissions_to_save)

          false ->
            Commissions.create_or_update_multiple_commissions(
              commissions_to_save,
              commission_edit_phase
            )
        end

      case result do
        {:ok, _commission} ->
          send(socket.assigns.parent_pid, {:commission_created, button: button})

          {:noreply,
           push_patch(socket,
             to: Routes.live_path(socket, PurchaseLive)
           )}

        {:error, %Ecto.Changeset{} = changest} ->
          {:noreply,
           assign(socket, commission_changeset: changest, commissions_in_form: commissions_in_form)}
      end

      {:noreply, socket}
    else
      {:noreply,
       assign(socket,
         commission_changeset: commission_changeset,
         commissions_in_form: commissions_in_form
       )}
    end
  end

  def handle_event("validate", %{"commission" => params}, socket) do
    %{commission_changeset: commission_changeset} = socket.assigns
    %{commissions_in_form: commissions_in_form} = socket.assigns

    commission_changeset =
      commission_changeset.data
      |> Commissions.change_commission(params)
      |> Map.put(:action, :update)

    socket =
      assign(socket,
        commission_changeset: commission_changeset,
        commissions_in_form: format_commissions(params, commissions_in_form)
      )

    {:noreply, socket}
  end

  def handle_event("add_commission", _, socket) do
    %{commissions_in_form: commissions_in_form} = socket.assigns

    commissions_in_form =
      commissions_in_form ++ [%{commission_payee_id: "", commission_per_hundred: 0, valid: true}]

    socket = assign(socket, commissions_in_form: commissions_in_form)
    {:noreply, socket}
  end

  def handle_event("delete_commission", params, socket) do
    {index, ""} = Integer.parse(params["index"])
    %{commissions_in_form: commissions_in_form} = socket.assigns

    commissions_in_form =
      cond do
        length(commissions_in_form) > 1 ->
          List.delete_at(commissions_in_form, index)

        true ->
          commissions_in_form
      end

    socket = assign(socket, commissions_in_form: commissions_in_form)
    {:noreply, socket}
  end

  def handle_event("delete_commission_in_db", params, socket) do
    {index, ""} = Integer.parse(params["index"])
    %{commissions_in_form: commissions_in_form} = socket.assigns

    commission = Enum.at(commissions_in_form, index)

    Commissions.delete_commission(Repo.get(Commission, commission.id))

    commissions_in_form =
      cond do
        length(commissions_in_form) > 1 ->
          List.delete_at(commissions_in_form, index)

        true ->
          []
      end

    send(
      socket.assigns.parent_pid,
      {:delete_commission_in_db, length(commissions_in_form), socket.assigns.parent_id}
    )

    socket =
      assign(socket,
        commissions_in_form: commissions_in_form,
        commissions_from_db: commissions_in_form
      )

    {:noreply, socket}
  end

  defp format_commissions(commissions_params, commissions_in_form) do
    commissions_in_form =
      commissions_in_form
      |> Enum.with_index()
      |> Enum.map(fn {_c, i} ->
        key_id = Integer.to_string(i) <> "_id"
        key_commission_per_hundred = Integer.to_string(i) <> "_commission_per_hundred"

        commission_payee_id =
          if commissions_params[key_id] != "",
            do: elem(Integer.parse(commissions_params[key_id]), 0),
            else: ""

        commission_per_hundred =
          if commissions_params[key_commission_per_hundred] != "",
            do: elem(Float.parse(commissions_params[key_commission_per_hundred]), 0),
            else: ""

        %{
          commission_payee_id: commission_payee_id,
          commission_per_hundred: commission_per_hundred,
          valid:
            check_valid_commission(%{
              commission_payee_id: commission_payee_id,
              commission_per_hundred: commission_per_hundred
            })
        }
      end)

    commissions_in_form
  end

  defp check_valid_commission(commission) do
    if(commission.commission_payee_id != "" && commission.commission_per_hundred != "") do
      true
    else
      false
    end
  end

  defp is_all_commissions_valid(commissions) do
    commissions = Enum.filter(commissions, fn item -> !item.valid end)
    if length(commissions) >= 1, do: false, else: true
  end

  defp remove_valid_key_add_purchase_id(commissions, purchase_id) do
    Enum.map(commissions, fn item ->
      item
      |> Map.delete(:valid)
      |> Map.put(:purchase_id, purchase_id)
    end)
  end
end
