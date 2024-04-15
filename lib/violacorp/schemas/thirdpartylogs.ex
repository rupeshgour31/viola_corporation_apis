defmodule Violacorp.Schemas.Thirdpartylogs do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Thirdpartylogs

  @moduledoc "Thirdpartylogs Table Model"

  schema "thirdpartylogs" do
    field :commanall_id, :integer
    field :section, :string
    field :method, :string
    field :request, :string
    field :response, :string
    field :status, :string
    field :inserted_by, :integer
    timestamps()
  end

  @doc false
  def changeset(%Thirdpartylogs{} = thirdpartylogs, attrs) do
    thirdpartylogs
    |> cast(attrs, [:commanall_id, :section, :method, :request, :response, :status, :inserted_by])
    |> validate_required([:request, :response])
  end
end
