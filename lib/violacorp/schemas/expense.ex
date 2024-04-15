defmodule Violacorp.Schemas.Expense do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Expense


  schema "expense" do
    field :aws_url, :string
    field :generate_date, :date

    belongs_to :commanall, Violacorp.Schemas.Commanall
    belongs_to :employee, Violacorp.Schemas.Employee
    belongs_to :employeecards, Violacorp.Schemas.Employeecards
    timestamps()
  end

  @doc false
  def changeset(%Expense{} = expense, attrs) do
    expense
    |> cast(attrs, [:commanall_id, :employee_id, :employeecards_id, :aws_url, :generate_date])
    |> validate_required([:generate_date])
    |> update_change(:aws_url, &String.trim/1)
    |> validate_length(:aws_url, max: 150)
  end
end
