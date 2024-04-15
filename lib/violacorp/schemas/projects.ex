defmodule Violacorp.Schemas.Projects do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Projects

  @moduledoc "Projects Table Model"

  schema "projects" do
    field :company_id, :integer
    field :project_name, :string
    field :start_date, :date
    field :is_delete, :string
    field :inserted_by, :integer

    has_many :assignproject, Violacorp.Schemas.Assignproject

    timestamps()
  end

  @doc false
  def changeset(%Projects{} = projects, attrs) do
    projects
    |> cast(attrs, [:company_id, :project_name, :start_date, :is_delete, :inserted_by])
    |> validate_required([:project_name, :start_date,:company_id])
    |> update_change(:project_name, &String.trim/1)
    |> validate_format(:project_name, ~r/^[A-z0-9- ]+$/, message: "Make sure you only use A-z")
    |> validate_length(:project_name, max: 40)
  end

  def deleteChangeset(%Projects{} = projects, attrs) do
    projects
    |> cast(attrs, [:is_delete])
    |> validate_required([:is_delete])
  end
end
