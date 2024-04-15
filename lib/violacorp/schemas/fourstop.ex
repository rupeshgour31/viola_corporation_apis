defmodule Violacorp.Schemas.Fourstop do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Fourstop

  @moduledoc "Fourstop Table Model"

  schema "fourstop" do
    field :director_id, :integer
    field :stopid, :string
    field :stop_status, :string
    field :description, :string
    field :score, :string
    field :rec, :string
    field :confidence_level, :string
    field :request, :string
    field :response, :string
    field :remark, :string
    field :status, :string
    field :inserted_by, :integer

#    belongs_to :directors, Violacorp.Schemas.Directors
    belongs_to :commanall, Violacorp.Schemas.Commanall
    timestamps()
  end

  @doc false
  def changeset(%Fourstop{} = fourstop, attrs) do
    fourstop
    |> cast(attrs, [:commanall_id, :director_id, :stopid, :stop_status, :description, :score, :rec, :confidence_level, :request, :response, :remark, :status, :inserted_by])
    |> validate_required([:commanall_id, :director_id, :stopid, :stop_status, :description, :score, :rec, :confidence_level, :request, :response, :remark, :status, :inserted_by])
    |> foreign_key_constraint(:commanall, name: :fk_fourstop_directorid)
  end

  def changesetv2(%Fourstop{} = fourstop, attrs) do
    fourstop
    |> cast(attrs, [:commanall_id, :director_id, :stopid, :stop_status, :description, :score, :rec, :confidence_level, :request, :response, :remark, :status, :inserted_by])
    |> validate_required([:commanall_id, :stopid, :stop_status, :description, :score, :rec, :confidence_level, :request, :response, :status, :inserted_by])
  end

  def update_status(%Fourstop{} = fourstop, attrs) do
    fourstop
    |> cast(attrs, [:status])
    |> validate_required([:status])
  end
end
