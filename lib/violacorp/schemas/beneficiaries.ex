defmodule Violacorp.Schemas.Beneficiaries do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Beneficiaries

  @moduledoc "Beneficiaries Table Model"

  schema "beneficiaries" do
    field :first_name, :string
    field :last_name, :string
    field :nick_name, :string
    field :sort_code, :string
    field :account_number, :string
    field :description, :string
    field :type, :string
    field :status, :string
    field :invoice_number, :string
    field :mode, :string
    field :inserted_by, :integer

    belongs_to :company, Violacorp.Schemas.Company

    timestamps()
  end

  @doc false
  def changeset(%Beneficiaries{} = beneficiaries, attrs) do
    beneficiaries
    |> cast(
         attrs,
         [
           :company_id,
           :first_name,
           :last_name,
           :nick_name,
           :sort_code,
           :account_number,
           :description,
           :type,
           :invoice_number,
           :status,
           :mode,
           :inserted_by
         ]
       )
    |> validate_required([:first_name, :sort_code, :account_number, :type, :status, :inserted_by])
    |> update_change(:first_name, &String.trim/1)
    |> update_change(:last_name, &String.trim/1)
    |> update_change(:nick_name, &String.trim/1)
    |> update_change(:sort_code, &String.trim/1)
    |> update_change(:account_number, &String.trim/1)
    |> update_change(:description, &String.trim/1)
    |> update_change(:type, &String.trim/1)
    |> update_change(:status, &String.trim/1)
    |> update_change(:invoice_number, &String.trim/1)
    |> validate_format(:first_name, ~r/[A-z0-9]+$/)
    |> validate_format(:last_name, ~r/[A-z0-9]+$/)
    |> validate_format(:nick_name, ~r/[A-z0-9]+$/)
    |> validate_format(:account_number, ~r/[A-z0-9]+$/)
    |> validate_format(:description, ~r/[a-zA-Z0-9-,. ]+$/)
    |> validate_format(:sort_code, ~r/[A-z0-9]+$/)
    |> validate_format(:invoice_number, ~r/[0-9]+$/)
    |> validate_length(:description, max: 18)
    |> validate_length(:first_name, max: 150)
    |> validate_length(:last_name, max: 150)
    |> validate_length(:nick_name, max: 45)
    |> validate_length(:invoice_number, max: 45)
    |> validate_length(:account_number, max: 15)
    |> validate_length(:sort_code, max: 10)
    |> validate_inclusion(:type, ["I", "E"], message: "Make Sure you use I or E")
    |> validate_inclusion(:status, ["A", "D", "B"], message: "Make Sure you use A or D or B")
  end

  def changesetBeneficiary(%Beneficiaries{} = beneficiaries, attrs) do
    beneficiaries
    |> cast(attrs, [:invoice_number, :description])
    |> validate_format(:invoice_number, ~r/[0-9]+$/)
    |> validate_format(:description, ~r/[A-z0-9 ]+$/)
    |> validate_length(:invoice_number, max: 45)
  end

  def changesetBeneficiaryMode(%Beneficiaries{} = beneficiaries, attrs) do
    beneficiaries
    |> cast(attrs, [:mode])
    |> validate_required([:mode])
  end

  def updateStatus(%Beneficiaries{} = beneficiaries, attrs) do
    beneficiaries
    |> cast(attrs, [:status])
    |> validate_required([:status])
    |> validate_inclusion(:status, ["A", "D", "B"], message: "Make Sure you use A or D or B")
  end
end
