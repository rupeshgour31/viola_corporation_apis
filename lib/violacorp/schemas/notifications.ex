defmodule Violacorp.Schemas.Notifications do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Notifications

  @moduledoc "Notifications Table Model"

  schema "notifications" do
    field :subject, :string
    field :message, :string
    field :status, :string
    field :inserted_by, :integer
    belongs_to :commanall, Violacorp.Schemas.Commanall
    timestamps()
  end

  @doc false
  def changeset(%Notifications{} = notifications, attrs) do
    notifications
    |> cast(attrs, [:commanall_id, :subject, :message, :status, :inserted_by])
    |> validate_required([:commanall_id, :message])
  end

  @doc false
  def updatestatus_changeset(notifications, attrs) do
    notifications
    |> cast(attrs, [:status])
    |> validate_required([:status])
  end
end
