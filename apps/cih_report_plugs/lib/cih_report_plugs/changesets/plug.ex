defmodule CihReportPlugs.Plug do
  use Ecto.Schema
  import Ecto.Changeset

  prefix = "bnw_dashboard_cih_report_plugs"
  prefix = case Application.get_env(:cih_report_plugs, :env) do
    :dev -> prefix <> "_dev"
    :test -> prefix <> "_test"
    _ -> prefix
  end

  @schema_prefix prefix

  schema "plugs" do
      field :projected_out_weight, :integer
      field :max_out_weight, :integer
      field :railer_be, :decimal, precision: 12, scale: 2
      field :projected_be, :decimal, precision: 12, scale: 2
      field :projected_ship_days, :integer
      field :created_at, :utc_datetime
      field :b_freight, :decimal, precision: 12, scale: 2
      field :n_freight, :decimal, precision: 12, scale: 2
      field :q_freight, :decimal, precision: 12, scale: 2
      field :b_bic, :decimal, precision: 12, scale: 2
      field :n_bic, :decimal, precision: 12, scale: 2
      field :q_bic, :decimal, precision: 12, scale: 2
      field :b_feed, :decimal, precision: 12, scale: 2
      field :n_feed, :decimal, precision: 12, scale: 2
      field :q_feed, :decimal, precision: 12, scale: 2
      field :tsp_days, :integer
      field :recalc_be_days, :integer
      field :recalc_feed_days, :integer
  end

  def changeset(plug, attrs \\ %{}) do
    plug
    |> cast(attrs, [
      :projected_out_weight,
      :max_out_weight,
      :railer_be,
      :projected_be,
      :projected_ship_days,
      :created_at,
      :b_freight,
      :n_freight,
      :q_freight,
      :b_bic,
      :n_bic,
      :q_bic,
      :b_feed,
      :n_feed,
      :q_feed,
      :tsp_days,
      :recalc_be_days,
      :recalc_feed_days])
    |> validate_required([
      :projected_out_weight,
      :max_out_weight,
      :railer_be,
      :projected_be,
      :projected_ship_days,
      :created_at,
      :b_freight,
      :n_freight,
      :q_freight,
      :b_bic,
      :n_bic,
      :q_bic,
      :b_feed,
      :n_feed,
      :q_feed,
      :tsp_days,
      :recalc_be_days,
      :recalc_feed_days])
  end
end
