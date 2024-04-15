defmodule Violacorp.Schemas.Otp do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Otp

  @moduledoc "Otp Table Model"

  schema "otp" do
    field :otp_code, :string
    field :otp_source, :string
    field :status, :string
    field :inserted_by, :integer
    timestamps()
    belongs_to :commanall, Violacorp.Schemas.Commanall
  end

  @doc false
  def changeset(%Otp{} = otp, attrs) do
    otp
    |> cast(attrs, [:commanall_id, :otp_code, :otp_source, :inserted_by])
  end

  @doc false
  def attempt_changeset(otp,  attrs \\ :empty) do
    otp
    |> cast(attrs, [:commanall_id, :otp_code, :otp_source])
  end
end
