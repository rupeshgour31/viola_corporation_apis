defmodule Violacorp.Schemas.Employeenotes do
  use Ecto.Schema
  import Ecto.Changeset

  alias Violacorp.Schemas.Employeenotes

  schema "employeenotes" do
    field :notes, :string
    field :status, :string
    field :inserted_by, :integer

     belongs_to :commanall, Violacorp.Schemas.Commanall
    timestamps()
  end

  def changeset(%Employeenotes{} = employeenotes, attr)do
    employeenotes
    |>cast(attr, [:commanall_id, :notes, :status, :inserted_by])
    |>foreign_key_constraint(:commanall, name: :fk_employeenotes_commanall1)
    |> validate_required([:notes])
    |> validate_length(:notes, max: 150)
    |> validate_format(:notes,~r/^[a-zA-Z0-9 _.-]+$/)
  end

end
