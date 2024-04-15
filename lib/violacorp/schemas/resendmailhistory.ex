defmodule Violacorp.Schemas.Resendmailhistory do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Resendmailhistory

  @moduledoc "Requestmoney Table Model"

  schema "resendmailhistory" do
    field :section, :string
    field :employee_id, :integer
    field :type, :string
    field :inserted_by, :integer

    belongs_to :commanall, Violacorp.Schemas.Commanall
    timestamps()
  end

  @doc false
  def changeset(%Resendmailhistory{} = resendmailhistory, attrs) do
    resendmailhistory
    |> cast(attrs, [:commanall_id, :employee_id, :section, :type, :inserted_by])
    |> validate_required([:section])
  end

end
