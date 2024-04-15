defmodule Violacorp.Schemas.Assignproject do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc "Assignproject Table Model"

  schema "assignproject" do
    field :employee_id, :integer
    field :inserted_by, :integer

    belongs_to :projects, Violacorp.Schemas.Projects

    timestamps()
  end

  @doc false
  def changeset(assignproject, attrs) do
    assignproject
    |> cast(attrs, [:employee_id, :projects_id, :inserted_by])
    |> validate_required([:employee_id])
  end
end
