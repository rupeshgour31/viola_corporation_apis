defmodule Violacorp.Schemas.Kycshareholder do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc "KYC Shareholder Table Model"

  schema "kycshareholder" do
    field :document_number, :string
    field :issue_date, :date
    field :expiry_date, :date
    field :file_type, :string
    field :file_name, :string
    field :file_location, :string
    field :content, :string
    field :country, :string
    field :type, :string
    field :status, :string
    field :inserted_by, :integer
    timestamps()

    belongs_to :shareholder, Violacorp.Schemas.Shareholder
    belongs_to :documenttype, Violacorp.Schemas.Documenttype

  end

  @doc false
  def changesetAddress(kycshareholder, attrs) do
    kycshareholder
    |> cast(
         attrs,
         [
           :shareholder_id,
           :documenttype_id,
           :document_number,
           :issue_date,
           :expiry_date,
           :file_type,
           :file_name,
           :file_location,
           :content,
           :type,
           :status,
           :inserted_by
         ]
       )
    |> validate_required([:shareholder_id, :documenttype_id])
    |> foreign_key_constraint(:documenttype_id, name: :fk_kycshareholder_documenttype1)
    |> foreign_key_constraint(:shareholder_id, name: :fk_kycshareholder_shareholder1)
    |> validate_inclusion(:type, ["A"])
    |> validate_current_or_future_date(:expiry_date)
    |> validate_current_or_future_date(:issue_date)
  end

  @doc"changeset for Id Proof"
  def changesetIdProof(kycshareholder, attrs) do
    kycshareholder
    |> cast(
         attrs,
         [
           :shareholder_id,
           :documenttype_id,
           :document_number,
           :issue_date,
           :expiry_date,
           :file_type,
           :file_name,
           :file_location,
           :country,
           :content,
           :type,
           :status,
           :inserted_by
         ]
       )
    |> validate_required([:issue_date, :expiry_date, :document_number])
    |> foreign_key_constraint(:documenttype_id, name: :fk_kycshareholder_documenttype1)
    |> foreign_key_constraint(:shareholder_id, name: :fk_kycshareholder_shareholder1)
    |> update_change(:document_number, &String.trim/1)
    |> validate_format(:document_number, ~r/^[A-z0-9- ]+$/)
    |> validate_length(:document_number, max: 45)
    |> validate_inclusion(:type, ["I"])
    |> validate_current_or_future_date(:expiry_date)
    |> validate_current_or_future_date(:issue_date)
  end

  @doc"changeset for Company"
  def changesetCompany(kycshareholder, attrs) do
    kycshareholder
    |> cast(
         attrs,
         [
           :shareholder_id,
           :documenttype_id,
           :document_number,
           :issue_date,
           :expiry_date,
           :file_type,
           :file_name,
           :file_location,
           :content,
           :type,
           :status,
           :inserted_by
         ]
       )
    |> validate_required([:shareholder_id, :documenttype_id])
    |> foreign_key_constraint(:documenttype_id, name: :fk_kycshareholder_documenttype1)
    |> foreign_key_constraint(:shareholder_id, name: :fk_kycshareholder_shareholder1)
    |> update_change(:documents_number, &String.trim/1)
    |> validate_format(:document_number, ~r/^[A-z0-9- ]+$/)
    |> validate_length(:document_number, max: 45)
    |> validate_inclusion(:type, ["C"])
    |> validate_current_or_future_date(:expiry_date)
    |> validate_current_or_future_date(:issue_date)
  end

  def validate_current_or_future_date(%{changes: changes} = changeset, field) do
    if date = changes[field] do
      do_validate_current_or_future_date(changeset, field, date)
    else
      changeset
    end
  end

  def do_validate_current_or_future_date(changeset, field, date) do
    today = Date.utc_today()
    comparison = Date.compare(date, today)
    if comparison == :lt || comparison == :eq do
      if field == :expiry_date do
        changeset
        |> add_error(field, "Expiry date must in the future")
      else
        changeset
      end

    else
      if field == :issue_date do
        changeset
        |> add_error(field, "Issue date must in the past")
      else
        changeset
      end
    end
  end
end
