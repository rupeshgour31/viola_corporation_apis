defmodule Violacorp.Schemas.Banners do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc "Banners Table Model"

  schema "banners" do
    field :file_location, :string
    field :status, :string
    field :inserted_by, :integer

    timestamps()
  end

  @doc false
  def changeset(banners, attrs) do
    banners
    |> cast(attrs, [:file_location, :status, :inserted_by])
    |> validate_required([:file_location, :status])
    |> validate_inclusion(:status, ["A", "D", "B"])
  end
end
