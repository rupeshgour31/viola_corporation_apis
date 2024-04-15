defmodule Violacorp.Schemas.Shareholder do
  use Ecto.Schema
  import Ecto.Changeset

   alias Violacorp.Schemas.Shareholder
  @moduledoc "share holder table model"

  schema "shareholder" do
    field :fullname, :string
    field :dob, :date
    field :type, :string
    field :status, :string
    field :percentage, :integer
    field :address, :string
    field :inserted_by, :integer

    belongs_to :company, Violacorp.Schemas.Company
    has_many :kycshareholder, Violacorp.Schemas.Kycshareholder
    timestamps()
  end

  @doc false
#  def changeset(shareholder, attrs) do
#
#    shareholder
#    |> cast(attrs, [:fullname,:dob, :address, :percentage, :type, :inserted_by])
#  end

  def changeset(%Shareholder{} = shareholder, attrs) do
    shareholder
    |> cast(attrs, [:company_id,:dob,:fullname,:type,:address, :percentage, :inserted_by])
    |> validate_required([:fullname, :dob, :type, :address, :percentage, :company_id])
    |> foreign_key_constraint(:company, name: :fk_shareholder_company1)
    |> validate_format(:fullname, ~r/[A-z-]+$/, message: "Make sure you only use A-z")
    |> validate_length(:fullname, max: 50)
    |> validate_inclusion(:type, ["P", "C"], message: "Make sure you use P or C")
    |> validate_inclusion(:status, ["A", "D"])
    |> validate_format(:address, ~r/^[A-z0-9- .\/#&,]+$/)
    |> update_change(:fullname, &String.trim/1)
    |> update_change(:fullname, &String.capitalize/1)
  end

  def addChangeset(%Shareholder{} = shareholder, attrs) do
    shareholder
    |> cast(attrs, [:company_id,:dob,:fullname,:type,:address, :percentage, :inserted_by])
    |> validate_required([:fullname, :type, :address, :percentage, :company_id])
    |> foreign_key_constraint(:company, name: :fk_shareholder_company1)
    |> validate_format(:fullname, ~r/[A-z-]+$/, message: "Make sure you only use A-z")
    |> validate_length(:fullname, max: 50)
    |> validate_inclusion(:type, ["P", "C"], message: "Make sure you use P or C")
    |> validate_inclusion(:status, ["A", "D"])
    |> validate_format(:address, ~r/^[A-z0-9- .\/#&,]+$/)
    |> update_change(:fullname, &String.trim/1)
    |> update_change(:fullname, &String.capitalize/1)
  end

end
