defmodule BnwDashboardWeb.PlugsApp.Template.TemplateLive do

  use BnwDashboardWeb, :live_view

  alias BnwDashboardWeb.PlugsApp.Helpers.{
    ModalComponent,
    TableLive,
    SearchLive,
    ChangeReportComponent
  }
  alias BnwDashboardWeb.PlugsApp.Template.ChangeYardComponent
  alias PlugsApp.{
    Templates,
    TemplateYards,
    Authorize,
    Reports,
    Users
  }

  defp get_role(socket) do
    current_user = Map.get(socket.assigns, :current_user)
    if current_user do
      Authorize.authorize(current_user, "template")
    else
      ""
    end
  end

  defp authenticate(socket) do
    case get_role(socket) do
      "admin" -> true
      "edit"  -> true
      "view"  -> true
      _       -> false
    end
  end

  defp fetch_permissions(socket) do
    role = get_role(socket)
    it_admin = socket.assigns.current_user.it_admin
    is_admin = role == "admin"
    is_edit  = role == "admin" or role == "edit"
    assign(socket, it_admin: it_admin, is_admin: is_admin, is_edit: is_edit)
  end

  defp init_args(socket) do
    %{
      selected_yard: selected_yard,
      yards: yards,
    } = socket.assigns
    args = [
      %{type: :date,      special: nil,       name: :co_month,                display_name: "Date"},
      %{type: :drop_down, special: nil,       name: :yard,                    display_name: "Yard", selected: selected_yard, list: yards},
      %{type: :text,      special: nil,       name: :lot,                     display_name: "Lot"},
      %{type: :number,    special: nil,       name: :proj_dmc,                display_name: "Proj DMC",             step: 0.01},
      %{type: :number,    special: :currency, name: :proj_other_costs,        display_name: "Proj Other Costs",     step: 0.01},
      %{type: :number,    special: :currency, name: :proj_rations_costs,      display_name: "Proj Rations Costs",   step: 0.01},
      %{type: :number,    special: :percent,  name: :proj_death_loss_percent, display_name: "Proj Death Loss %",    step: 0.01},
      %{type: :number,    special: :percent,  name: :op_percent,              display_name: "OP %",                 step: 0.01},
      %{type: :number,    special: nil,       name: :proj_adg,                display_name: "Proj ADG",             step: 0.01},
      %{type: :number,    special: nil,       name: :fat_freight,             display_name: "Fat Freight",          step: 0.01},
      %{type: :number,    special: nil,       name: :proj_cog_w_interest,     display_name: "Proj COG w/ Int",      step: 0.01},
      %{type: :number,    special: nil,       name: :proj_be_wo_interest,     display_name: "Proj BE w/o Interest", step: 0.01},
      %{type: :number,    special: nil,       name: :proj_be,                 display_name: "Proj BE",              step: 0.01},
      %{type: :number,    special: nil,       name: :cnb_purchase_price,      display_name: "CNB Purchase Price",   step: 0.01},
      %{type: :disp_only, special: nil,       name: :yard_lot,                display_name: "Yard/Lot"},
    ]

    assign(socket, args: args)
  end

  defp fetch_items(plug) do
    yard = Map.get(plug, :yard, 0)
    |> TemplateYards.get_plug()
    Map.put(plug, :yard, yard)
  end

  defp fetch_plugs(socket) do
    %{
      page: page,
      per_page: per_page,
      search: search,
      selected_search_col: search_col
    } = socket.assigns
    pre_plugs = Map.get(socket.assigns, :plugs, [])

    plugs =
      Templates.list_plugs(page, per_page, search_col, search)
      |> Enum.map(&(fetch_items(&1)))
      |> Enum.map(&(Templates.change_plug(&1)))
    assign(socket, plugs: pre_plugs ++ plugs)
  end

  defp fetch_extra(socket) do
    yards = TemplateYards.list_plugs()
    assign(socket, yards: yards)
  end

  defp fetch_plug_extra(socket) do
    plug_yards = TemplateYards.list_all_plugs()
    assign(socket, plug_yards: plug_yards)
  end

  defp init_reports(socket) do
    %{plug: plug} = socket.assigns
    reports = Reports.list_reports(plug)

    assign(socket, can_show_reports: Enum.count(reports) > 0, reports: reports)
  end

  @impl true
  def mount(_params, session, socket) do
    page = 1
    per_page = 20
    socket =
      assign_defaults(session, socket)
      |> assign(page_title: "BNW Dashboard · Plugs Template",
                app: "Plugs",
                add_more: false,
                selected_yard: nil,
                yards: nil,
                modal: nil,
                update_action: "replace",
                page: page,
                plug: "template",
                selected_search_col: :co_month,
                search: "",
                per_page: per_page)
      |> fetch_plugs()
      |> fetch_extra()
      |> fetch_permissions()
      |> init_args()
      |> init_reports()

    if connected?(socket) do
      Templates.subscribe()
      TemplateYards.subscribe()
      Users.subscribe()
      Reports.subscribe()
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

  @impl true
  def handle_info({[:template_yard, :created_or_updated], _}, socket) do
    socket = fetch_extra(socket)
    |> fetch_plug_extra()
    {:noreply, socket}
  end

  @impl true
  def handle_info({[:template_yard, :deleted], _}, socket) do
    socket = fetch_extra(socket)
    |> fetch_plug_extra()
    {:noreply, socket}
  end

  @impl true
  def handle_info({[:template, :created_or_updated_add_more], _}, socket) do
    changeset =
      Templates.new_plug()
      |> Templates.change_plug()
    socket = assign(socket,
      changeset: changeset,
      modal: :change_plug,
      modal_title: "New Template",
      selected_yard: 1)
    |> assign(page: 1, plugs: [])
    |> fetch_plugs()
    {:noreply, socket}
  end

  @impl true
  def handle_info({[:template, :created_or_updated], _}, socket) do
    socket = assign(socket, page: 1, plugs: [])
    |> fetch_plugs()
    |> assign(modal: nil)
    {:noreply, socket}
  end

  @impl true
  def handle_info({[:template, :deleted], _}, socket) do
    socket = assign(socket, page: 1, plugs: [])
    |> fetch_plugs()
    {:noreply, socket}
  end

  @impl true
  def handle_info({[:report, :created_or_updated], _}, socket) do
    socket = init_reports(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_info({[:report, :deleted], _}, socket) do
    socket = init_reports(socket)
    {:noreply, socket}
  end

  @impl true
  def handle_info({[:user, :updated], _plug}, socket) do
    case authenticate(socket) do
      true -> {:noreply, fetch_permissions(socket)}
      false -> {:noreply, redirect(socket, to: "/")}
    end
  end

  @impl true
  def handle_info(_, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("edit_yards", _, socket) do
    socket = assign(socket,
      modal: :change_yard,
      modal_title: "Manage Yards")
      |> fetch_plug_extra()
    {:noreply, socket}
  end

  @impl true
  def handle_event("edit", params, socket) do
    {id, ""} = Integer.parse(params["id"])
    cur = Enum.find(socket.assigns.plugs, fn u -> u.data.id == id end)
    %{yards: yards} = socket.assigns
    yard = Enum.find(yards, fn x-> x[:key] == cur.data.yard end)[:value]

    socket = assign(socket,
      changeset: cur,
      modal: :change_plug,
      modal_title: "Edit Template",
      selected_yard: yard)
      |> init_args()
    {:noreply, socket}
  end

  @impl true
  def handle_event("new", _, socket) do
    changeset =
      Templates.new_plug()
      |> Templates.change_plug()
    socket = assign(socket,
      changeset: changeset,
      modal: :change_plug,
      modal_title: "New Template",
      selected_yard: 1)
      |> init_args()
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel", _, socket) do
    socket = assign(socket, changest: nil, modal: nil)
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", params, socket) do
    {id, ""} = Integer.parse(params["id"])
    cur = Enum.find(socket.assigns.plugs, fn u -> u.data.id == id end)
    Templates.delete_plug(cur.data)
    {:noreply, socket}
  end

  def handle_event("save", %{"template" => plug}, socket) do
    %{changeset: changeset, add_more: add_more} = socket.assigns

    changeset = Templates.validate(changeset.data, plug)
    if changeset.valid? do
      case Templates.create_or_update_plug(changeset.data, plug, add_more) do
        {:ok, _plug} ->
          {:noreply, socket}
        {:error, %Ecto.Changeset{} = changest} ->
          {:noreply, assign(socket, changeset: changest)}
      end
    else
      {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("add_more", _, socket) do
    {:noreply, assign(socket, add_more: true)}
  end

  def handle_event("done", _, socket) do
    {:noreply, assign(socket, add_more: false)}
  end

  def handle_event("validate", %{"template" => plug}, socket) do
    %{changeset: changeset} = socket.assigns
    changeset = Templates.validate(changeset.data, plug)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("load_more", _, socket) do
    %{
      page: page
    } = socket.assigns
    page = page + 1
    socket = assign(socket, update_action: "append", page: page)

    {:noreply, fetch_plugs(socket)}
  end

  def handle_event("show_reports", _, socket) do
    {:noreply, assign(socket,
        modal: :show_reports,
        modal_title: "Template Reports")}
  end

  def handle_event("search", %{"search" => params}, socket) do
    %{
      selected_search_col: prev_col,
      search: prev_search
    } = socket.assigns
    %{
      "search" => search,
      "search_col" => search_col
    } = params

    search_col = String.to_atom(search_col)

    search =
    if prev_col == search_col do
      search
    else
      ""
    end

    socket = assign(socket,
      selected_search_col: search_col,
      search: search
    )

    socket =
    if search_col &&
    (search != "" ||
      prev_search != "") do
      assign(socket, page: 1, plugs: [])
      |> fetch_plugs()
    else
      socket
    end
    {:noreply, socket}
  end
end
