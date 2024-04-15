defmodule Violacorp.Schemas.Requestmoney do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Requestmoney

  @moduledoc "Requestmoney Table Model"

  schema "requestmoney" do
    field :company_id, :integer
    field :cur_code, :string
    field :amount, :decimal
    field :reason, :string
    field :status, :string
    field :company_reason, :string
    belongs_to :employeecards, Violacorp.Schemas.Employeecards
    belongs_to :employee, Violacorp.Schemas.Employee
    timestamps()
  end

  @doc false
  def changeset(%Requestmoney{} = requestmoney, attrs) do
    requestmoney
    |> cast(attrs, [:company_id, :employee_id, :employeecards_id, :cur_code, :amount, :reason])
    |> validate_required([:employee_id, :employeecards_id, :amount, :reason])
    |> update_change(:reason, &String.trim/1)
    |> validate_format(:reason, ~r/[A-z-]*$/, message: "Make sure you only use A-z")
    |> validate_length(:reason, max: 60)
    |> validate_number(:amount, greater_than_or_equal_to: 0.01)
  end

  @doc false
  def updatestatus_changeset(requestcard, attrs) do
    requestcard
    |> cast(attrs, [:status, :company_reason])
    |> validate_required([:status])
  end
end
