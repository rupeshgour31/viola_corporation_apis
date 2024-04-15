defmodule Violacorp.Schemas.Loginhistory do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Loginhistory

  @moduledoc "Loginhistory Table Model"

  schema "loginhistory" do
    field :commanall_id, :integer
    field :administratorusers_id, :integer
    field :email_id, :string
    field :time_in, :string
    field :time_out, :string
    field :details, :string
    field :success, :string
    field :existing_user, :string
    field :device_type, :string

    timestamps()
  end

  @doc false
  def changeset(%Loginhistory{} = loginhistory, attrs) do
    loginhistory

    |> cast(attrs, [:commanall_id, :administratorusers_id, :email_id, :time_in, :time_out, :details, :success, :existing_user, :device_type])
#    |> validate_required([:commanall_id, :email_id])
  end
end
