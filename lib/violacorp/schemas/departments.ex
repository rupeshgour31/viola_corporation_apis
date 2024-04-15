defmodule Violacorp.Schemas.Departments do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Departments

  @moduledoc "Departments Table Model"

  schema "departments" do
    field :company_id, :integer
    field :department_name, :string
    field :number_of_employee, :integer
    field :status, :string
    field :inserted_by, :integer

    has_many :employee, Violacorp.Schemas.Employee
    timestamps()
  end

  @doc false
  def changeset(%Departments{} = departments, attrs) do
    departments
    |> cast(attrs, [:company_id, :department_name, :number_of_employee, :status, :inserted_by])
    |> validate_required([:department_name,:status])
    |> update_change(:department_name, &String.trim/1)
    |> validate_format(:department_name, ~r/^[a-zA-Z ]+$/, message: "Make sure you only use A-z")
    |> validate_length(:department_name, min: 3, max: 40)
    |> validate_inclusion(:status, ["A", "D"])
  end

  def updateEmployeeNumberchangeset(%Departments{} = departments, attrs) do
    departments
    |> cast(attrs, [:number_of_employee])
  end
end
