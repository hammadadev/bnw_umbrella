defmodule PlugsApp.NbxTrucking do
  use Ecto.Schema
  import Ecto.Changeset

  prefix = "bnw_dashboard_plugs_app"
  prefix = case Application.get_env(:plugs_app, :env) do
    :dev -> prefix <> "_dev"
    :test -> prefix <> "_test"
    _ -> prefix
  end

  @schema_prefix prefix

  schema "nbx_trucking" do
    field :start_date, :date
    field :truck,      :integer
    field :dept,       :integer
    field :miles,      :integer
    field :tons,       :integer

    timestamps()
  end

  def changeset(plug, attrs \\ %{}) do
    plug
    |> cast(attrs, [
          :start_date,
          :truck,
          :dept,
          :miles,
          :tons,
        ])
    |> validate_required(:dept)
    |> unique_constraint([:start_date, :truck, :dept], name: :nbx_trucking_unique_constraint)
  end
end
