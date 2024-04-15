defmodule Violacorp.Schemas.Appversions do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc "appversions Table Model"

  schema "appversions" do
    field :type, :string
    field :version, :string
    field :is_active, :string
    field :inserted_by, :integer

    timestamps()
  end

  @doc "changeset for appversions"
  def changeset(appversions, attrs) do
    appversions
    |> cast(attrs, [:type, :version, :is_active, :inserted_by])
    |> validate_required([:type, :is_active, :version])
    |> update_change(:type, &String.trim/1)
    |> update_change(:is_active, &String.trim/1)
    |> validate_length(:version, min: 3, max: 10)
    |> validate_format(:version,~r/^[(\d+\.)(\d+\.)(\d)$]+$/)
    |> validate_inclusion(:type, ["A", "I"])
    |> validate_inclusion(:is_active, ["Y", "N"])
  end


  def changesetUpdate(appversions, attrs)do
    appversions
    |> cast(attrs, [:is_active, :inserted_by])
    |> validate_required([:is_active])
    |> validate_inclusion(:is_active, ["Y", "N"])
  end
end
