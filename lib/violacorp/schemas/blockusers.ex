defmodule Violacorp.Schemas.Blockusers do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc "blockusers Table Model"

  schema "blockusers" do
    field :reason, :string
    field :status_date, :utc_datetime
    field :block_date, :utc_datetime
    field :type, :string
    field :status, :string
    field :inserted_by, :integer

    belongs_to :commanall, Violacorp.Schemas.Commanall
    timestamps()
  end

  @doc false
  def changeset(blockusers, attrs) do
    blockusers
    |> cast(attrs, [:commanall_id, :reason, :status_date, :block_date, :type, :status, :inserted_by])
    |> validate_required([:reason, :type, :status])
    |> update_change(:reason, &String.trim/1)
    |> update_change(:type, &String.trim/1)
    |> update_change(:status, &String.trim/1)
    |> validate_format(:reason, ~r/^[A-z0-9- .\/#,]+$/)
    |> validate_length(:reason, max: 255)
    |> validate_inclusion(:type, ["B", "U"])
    |> validate_inclusion(:status, ["A", "D"])
  end
end
