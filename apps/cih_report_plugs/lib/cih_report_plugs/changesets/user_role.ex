defmodule CihReportPlugs.UserRole do
  use Ecto.Schema
  import Ecto.Changeset

  alias CihReportPlugs.User

  prefix = "bnw_dashboard_cih_report_plugs"
  prefix = case Application.get_env(:accounts, :env) do
             :dev -> prefix <> "_dev"
             :test -> prefix <> "_test"
             _ -> prefix
           end
  @schema_prefix prefix

  schema "users_roles" do
    field :role, :string
    belongs_to :user, User
  end

  def changeset(user_role, attrs \\ %{}) do
    user_role
    |> cast(attrs, [:user_id, :role])
  end
end
