defmodule CattlePurchase.WeightCategory do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias CattlePurchase.Repo

  prefix = "bnw_dashboard_cattle_purchase"

  prefix =
    case Application.get_env(:cattle_purchase, :env) do
      :dev -> prefix <> "_dev"
      :test -> prefix <> "_test"
      _ -> prefix
    end

  @schema_prefix prefix
  schema "weight_categories" do
    field :start_weight, :integer
    field :end_weight, :integer

    timestamps()
  end

  @required ~w(start_weight end_weight)a
  @allowed @required

  def changeset(%__MODULE__{} = model, attrs \\ %{}) do
    model
    |> cast(attrs, @allowed)
    |> validate_required(@required)
    |> check_weights_valid(attrs["start_weight"], attrs["end_weight"])
    |> overlap_weight_ranges(attrs["start_weight"], attrs["end_weight"])
  end

  def new_changeset(%__MODULE__{} = model, attrs \\ %{}) do
    model
    |> cast(attrs, @allowed)
  end

  def check_weights_valid(cs, nil, nil), do: cs

  def check_weights_valid(cs, start_weight, end_weight) when cs.valid?  do
    if end_weight|> String.to_integer() < start_weight|> String.to_integer() do
      add_error(cs, :end_weight, "can't be less than start_weight")
    else
      if end_weight|> String.to_integer() == start_weight|> String.to_integer() do
        add_error(cs, :end_weight, "can't be same as start weight")
      else
        cs
      end
    end
  end

  def check_weights_valid(cs, _start_weight,_end_weight), do: cs

  def overlap_weight_ranges(cs, nil, nil), do: cs

  def overlap_weight_ranges(cs, start_weight, end_weight) when cs.valid? do
    max_end_weight = from( wc in __MODULE__,
                            select: max(wc.end_weight)
                          )
                          |> Repo.one()
    min_start_weight = from( wc in __MODULE__,
                              select: min(wc.start_weight)
                            )
                            |> Repo.one()


    if (max_end_weight && start_weight|> String.to_integer() > max_end_weight)
        || (min_start_weight && end_weight|> String.to_integer() <  min_start_weight) do
        cs
    else
        result = from( wc in __MODULE__,
                        where: (wc.start_weight >= ^start_weight
                        and wc.end_weight >= ^end_weight) or
                        (wc.start_weight <= ^start_weight
                        and wc.end_weight >= ^end_weight) or
                        (wc.start_weight >= ^start_weight
                        and wc.end_weight <= ^end_weight) or
                        wc.end_weight == ^start_weight or
                        wc.end_weight <= ^start_weight,
                        select: %{id: wc.id}
                      )
                      |> Repo.all()

      if result == [] do
        cs
      else
        add_error(cs, :start_weight, "range already exists")
      end
    end
  end

  def overlap_weight_ranges(cs, _start_weight, _end_weight), do: cs
end
