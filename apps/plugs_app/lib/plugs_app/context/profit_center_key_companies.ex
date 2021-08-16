defmodule PlugsApp.ProfitCenterKeyCompanies do

  import Ecto.Query
  alias PlugsApp.{
    ProfitCenterKeyCompany,
    Repo
  }

  @topic "plugs_app:profit_center_key_company"


  @doc """
  This function subscribes a user to changes in the ocb_report_plugs plugs page.
  This allows for users to get a live update on their role within the application.
  """
  def subscribe(), do: Phoenix.PubSub.subscribe(PlugsApp.PubSub, @topic)
  def subscribe(id), do: Phoenix.PubSub.subscribe(PlugsApp.PubSub, "#{@topic}:#{id}")
  @doc """
  This function unsubscribes a user to changes in the ocb_report_plugs plugs page.
  """
  def unsubscribe(), do: Phoenix.PubSub.unsubscribe(PlugsApp.PubSub, @topic)
  def unsubscribe(id), do: Phoenix.PubSub.unsubscribe(PlugsApp.PubSub, "#{@topic}:#{id}")

  @doc """
  Get all plugs from the database.
  """
  def list_plugs() do
    list_all_plugs()
    |> Enum.map(fn x->
      %{id: id, company: company} = x
      [key: company, value: id]
    end)
  end

  def get_plug(id) do
    %{company: company} = get_plug_struct(id)
    company
  end

  def list_all_plugs() do
    ProfitCenterKeyCompany
    |> order_by([plug], asc: plug.company)
    |> Repo.all()
  end

  def get_plug_struct(id) do
    if is_nil(id) do
      %{company: nil}
    else
      plug = ProfitCenterKeyCompany
      |> where([plug], plug.id == ^id)
      |> Repo.one()
      if !is_nil(plug) do
        plug
      else
        %{company: nil}
      end
    end
  end

  def new_plug() do
    %ProfitCenterKeyCompany{}
  end

  def change_plug(%ProfitCenterKeyCompany{} = plug, attrs \\ %{}) do
    ProfitCenterKeyCompany.changeset(plug, attrs)
  end

  @doc """
  Validation function used by the modal. Verifies valid date
  """
  def validate(%ProfitCenterKeyCompany{} = plug, attrs \\ %{}) do
    plug
    |> change_plug(attrs)
    |> Map.put(:action, :insert)
  end

  @doc """
  Create or update a specifc plug. Called by the create update modal.
  """
  def create_or_update_plug(%ProfitCenterKeyCompany{} = plug, attrs \\ %{}) do
    plug
    |> ProfitCenterKeyCompany.changeset(attrs)
    |> Repo.insert_or_update()
    |> notify_subscribers([:profit_center_key_company, :created_or_updated])
  end

  @doc """
  Delete a plug then notify others of its departure
  """
  def delete_plug(%ProfitCenterKeyCompany{} = plug) do
    Repo.delete(plug)
    |> notify_subscribers([:profit_center_key_company, :deleted])
  end

  @doc """
  Tell everyone who is subscribed about a change.
  """
  def notify_subscribers({:ok, result}, event) do
    Phoenix.PubSub.broadcast(PlugsApp.PubSub, @topic, {event, result})
    Phoenix.PubSub.broadcast(PlugsApp.PubSub, "#{@topic}:#{result.id}", {event, result})

    {:ok, result}
  end
  def notify_subscribers({:error, reason}, _event), do: {:error, reason}
end
