defmodule Violacorp.Schemas.Devicedetails do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Devicedetails

  @moduledoc "Devicedetails Table Model"

  schema "devicedetails" do
    field :session_id, :string
    field :type, :string
    field :unique_id, :string
    field :token, :string
    field :details, :string
    field :status, :string
    field :is_delete, :string
    field :inserted_by, :integer

    timestamps()

    belongs_to :commanall, Violacorp.Schemas.Commanall
  end

  @doc false
  def changeset(%Devicedetails{} = devicedetails, attrs) do
    devicedetails
    |> cast(attrs, [:commanall_id, :session_id, :type, :unique_id, :token, :details, :status, :is_delete, :inserted_by])
    |> validate_required([:commanall_id, :type])
  end

  def deleteStatusChangeset(%Devicedetails{} = devicedetails, attrs) do
    devicedetails
    |> cast(attrs, [:is_delete])
    |> validate_required([:is_delete])
  end
end
