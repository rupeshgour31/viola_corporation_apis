defmodule Violacorp.Schemas.Groupfee do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Groupfee

  @moduledoc "Groupfee Table Model"

  schema "groupfee" do
    field :commanall_id, :integer
    field :amount, :decimal
    field :fee_type, :string
    field :trans_type, :string
    field :rules, :string
    field :mode, :string
    field :status, :string
    field :as_default, :string
    field :inserted_by, :integer

    belongs_to :feehead, Violacorp.Schemas.Feehead
    timestamps()
  end

  @doc false
  def changeset(%Groupfee{} = groupfee, attrs) do
    groupfee
    |> cast(attrs, [:feehead_id, :commanall_id, :amount, :fee_type, :trans_type, :as_default, :mode, :rules, :status, :inserted_by])
    |> validate_required([:feehead_id, :amount, :fee_type, :trans_type])
    |> validate_inclusion(:fee_type, ["F", "P"])
    |> validate_inclusion(:trans_type, ["MONTH", "ONE", "EVERY"])
    |> validate_inclusion(:mode, ["C", "D"])
    |> validate_inclusion(:status, ["A", "D"])
    |> validate_inclusion(:as_default, ["Yes", "No"])
    |> validate_number(:amount, greater_than: "0.00")
  end
end
