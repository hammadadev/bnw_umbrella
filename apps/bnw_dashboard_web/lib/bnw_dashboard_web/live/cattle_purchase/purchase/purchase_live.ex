defmodule BnwDashboardWeb.CattlePurchase.Purchase.PurchaseLive do
  use BnwDashboardWeb, :live_view

  alias CattlePurchase.{
    Authorize,
    Purchases,
    Purchase,
    PurchaseTypes,
    PurchaseTypeFilters,
    Repo
  }

  #  alias BnwDashboardWeb.CattlePurchase.Purchases.PurchaseSearchComponent

  defp authenticate(socket) do
    current_user = Map.get(socket.assigns, :current_user)

    cond do
      current_user && Authorize.authorize(current_user, "purchases") ->
        true

      true ->
        false
    end
  end

  @impl true
  def mount(_, session, socket) do
    active_purchase_types =
      PurchaseTypes.get_active_purchase_types()
      |> Enum.map(fn item -> %{id: item.id, name: item.name, checked: false} end)

    purchase_type_filters =
      PurchaseTypeFilters.list_purchase_type_filters()
      |> Enum.map(fn item -> %{id: item.id, name: item.name, checked: false} end)

    toggle_complete = %{name: "toggle completed", checked: false}

    search_columns = [
      purchase_date: :purchase_date,
      seller: :seller,
      purchase_location: :origin,
      purchase_order: :purchase_order,
      head_count: :head_count,
      sex: :sex,
      weight: :weight,
      price: :price,
      buyer: :buyer,
      destination: :destination,
      ship_date: :estimated_ship_date,
      kill_date: :projected_out_date
    ]

    purchases = Purchases.list_purchases()

    socket =
      assign_defaults(session, socket)
      |> assign(
        page_title: "Purchase",
        app: "Cattle Purchase",
        purchases: purchases,
        active_purchase_types: active_purchase_types,
        purchase_type_filters: purchase_type_filters,
        toggle_complete: toggle_complete,
        search_columns: search_columns,
        purchase_search: %{
          column_name: "Select column for search",
          search_value: "",
          start_date: "",
          end_date: ""
        }
      )

    if connected?(socket) do
      Purchases.subscribe()
    end

    case authenticate(socket) do
      true -> {:ok, socket}
      false -> {:ok, redirect(socket, to: "/")}
    end
  end

  @impl true
  def handle_params(_, _, socket) do
    {:noreply, socket}
  end

  def handle_event(
        "handle_toggle_purchase_type",
        %{"id" => _} = params,
        socket
      ) do
    {id, ""} = Integer.parse(params["id"])

    active_purchase_types =
      socket.assigns.active_purchase_types
      |> Enum.map(fn item ->
        if(item.id == id) do
          Map.put(item, :checked, !item.checked)
        else
          item
        end
      end)

    {:noreply, assign(socket, active_purchase_types: active_purchase_types)}
  end

  def handle_event(
        "handle_toggle_purchase_type_filter",
        %{"id" => _} = params,
        socket
      ) do
    {id, ""} = Integer.parse(params["id"])

    purchase_type_filters =
      socket.assigns.purchase_type_filters
      |> Enum.map(fn item ->
        if(item.id == id) do
          Map.put(item, :checked, !item.checked)
        else
          item
        end
      end)

    {:noreply, assign(socket, purchase_type_filters: purchase_type_filters)}
  end

  def handle_event(
        "handle_toggle_completed",
        params,
        socket
      ) do
    toggle_complete =
      Map.put(socket.assigns.toggle_complete, :checked, !socket.assigns.toggle_complete.checked)

    {:noreply, assign(socket, toggle_complete: toggle_complete)}
  end

  def handle_event(
        "validate",
        %{"purchase_search" => purchase_search},
        socket
      ) do
    start_date =
      if !(String.trim(purchase_search["start_date"]) == "") &&
           purchase_search["start_date"] !=
             socket.assigns.purchase_search.start_date do
        purchase_search["start_date"]
      end

    end_date =
      if !(String.trim(purchase_search["end_date"]) == "") &&
           purchase_search["end_date"] !=
             socket.assigns.purchase_search.end_date do
        purchase_search["end_date"]
      end

    search_value =
      if !(String.trim(purchase_search["search_value"]) == "") &&
           purchase_search["search_value"] !=
             socket.assigns.purchase_search.search_value do
        purchase_search["search_value"]
      end

    column_name =
      if purchase_search["column_name"] != "" do
        purchase_search["column_name"]
      else
        "Select column for search"
      end

    socket =
      assign(socket,
        purchase_search: %{
          start_date: start_date || socket.assigns.purchase_search.start_date,
          end_date: end_date || socket.assigns.purchase_search.end_date,
          search_value: search_value || socket.assigns.purchase_search.search_value,
          column_name: column_name || socket.assigns.purchase_search.column_name
        }
      )

    {:noreply, socket}
  end

  def handle_event("search", _params, socket) do
    purchase_filters =
      Enum.reduce(socket.assigns.purchase_search, %{}, fn {k, v}, map ->
        if(String.trim(v) == "" || v == "Select column for search") do
          Map.put(map, k, nil)
        else
          Map.put(map, k, v)
        end
      end)

    purchase_types_ids =
      Enum.reduce(socket.assigns.active_purchase_types, [], fn purchase_type, list ->
        if(purchase_type.checked) do
          list ++ [purchase_type.id]
        else
          list
        end
      end)

    purchase_type_filter_ids =
      Enum.reduce(socket.assigns.purchase_type_filters, [], fn purchase_type_filter, list ->
        if(purchase_type_filter.checked) do
          list ++ [purchase_type_filter.id]
        else
          list
        end
      end)

    toggle_completed = if(socket.assigns.toggle_complete.checked, do: true, else: false)

    purchases =
      Purchases.filter_by_purhcase_types(Purchase, purchase_types_ids)
      |> Purchases.filter_by_purchase_type_filter(purchase_type_filter_ids)
      |> Purchases.get_complete_purchases(toggle_completed)
      |> Purchases.ship_date_range(purchase_filters.start_date, purchase_filters.end_date)
      |> Purchases.search(purchase_filters.column_name, purchase_filters.search_value)
      |> Repo.all()
      |> Repo.preload([:sex, :purchase_buyer, :destination_group])


    {:noreply, assign(socket, purchases: purchases)}
  end
end