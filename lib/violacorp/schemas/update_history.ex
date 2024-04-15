defmodule Violacorp.Schemas.UpdateHistory do
  use Ecto.Schema
  import Ecto.Changeset

  alias Violacorp.Schemas.UpdateHistory

  schema "updatehistory" do
    field :field_name, :string
    field :new_value, :string
    field :old_value, :string
    field :inserted_by, :integer

    belongs_to :company,  Violacorp.Schemas.Company
    belongs_to :directors,  Violacorp.Schemas.Directors
    belongs_to :employee,  Violacorp.Schemas.Employee


    timestamps()
  end

  @doc """
      Changeset for Insert in UpdateHistory
  """
  def changeset(%UpdateHistory{} = update_history, attrs) do
    update_history
    |> cast(attrs, [:company_id, :employee_id, :directors_id, :field_name, :old_value, :new_value, :inserted_by])
    |> validate_required([:new_value])

  end
end
