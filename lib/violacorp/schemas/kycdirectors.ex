defmodule Violacorp.Schemas.Kycdirectors do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Kycdirectors

  @moduledoc "Kycdirectors Table Model"

  schema "kycdirectors" do
    field :documenttype_id, :integer
    field :document_number, :string
    field :expiry_date, :date
    field :issue_date, :date
    field :file_type, :string
    field :file_name, :string
    field :file_location, :string
    field :file_location_two, :string
    field :status, :string
    field :type, :string
    field :country, :string
    field :fourstop_response, :string
    field :reference_id, :string
    field :refered_id, :integer
    field :inserted_by, :integer
    field :reason, :string
    field :address_documenttype_id, :integer, [source: :documenttype_id]

    belongs_to :directors, Violacorp.Schemas.Directors
    #    belongs_to :documenttype, Violacorp.Schemas.Documenttype

    timestamps()
  end

  @doc false
  def changeset(%Kycdirectors{} = kycdirectors, attrs) do
    kycdirectors
    |> cast(
         attrs,
         [
           :reason,
           :directors_id,
           :documenttype_id,
           :country,
           :document_number,
           :issue_date,
           :expiry_date,
           :file_type,
           :file_name,
           :file_location,
           :file_location_two,
           :status,
           :type,
           :inserted_by
         ]
       )
    |> validate_required([:documenttype_id, :document_number])
    |> foreign_key_constraint(:documenttype, name: :fk_kycdirectors_documenttype1)
    |> foreign_key_constraint(:directors, name: :fk_kycdirectors_directors1_)
    |> update_change(:document_number, &String.trim/1)
    |> validate_format(:document_number, ~r/^[A-z0-9- ]+$/)
    |> validate_length(:document_number, max: 45)
    |> validate_current_or_future_date(:expiry_date)
    |> validate_current_or_future_date(:issue_date)
  end

  @doc false
  def changeset_addess(%Kycdirectors{} = kycdirectors, attrs) do
    kycdirectors
    |> cast(
         attrs,
         [
           :directors_id,
           :documenttype_id,
           :document_number,
           :expiry_date,
           :issue_date,
           :file_type,
           :file_name,
           :file_location,
           :status,
           :type,
           :inserted_by
         ]
       )
    |> validate_required([:documenttype_id])
    |> foreign_key_constraint(:documenttype, name: :fk_kycdirectors_documenttype1)
    |> update_change(:document_number, &String.trim/1)
    |> validate_format(:document_number, ~r/^[A-z0-9- ]+$/)
  end

  @doc false
  def changeset_director_kyc(%Kycdirectors{} = kycdirectors, attrs) do
    kycdirectors
    |> cast(
         attrs,
         [
           :directors_id,
           :address_documenttype_id,
           :document_number,
           :expiry_date,
           :issue_date,
           :file_type,
           :file_name,
           :file_location,
           :status,
           :type,
           :inserted_by
         ]
       )
    |> validate_required([:address_documenttype_id])
    |> foreign_key_constraint(:documenttype, name: :fk_kycdirectors_documenttype1)
    |> update_change(:document_number, &String.trim/1)
    |> validate_format(:document_number, ~r/^[A-z0-9- ]+$/)
  end

  @doc false
  def update_by_gbg(%Kycdirectors{} = kycdirectors, attrs) do
    kycdirectors
    |> cast(attrs, [:fourstop_response])
    |> validate_required([])
  end

  @doc false
  def changeset_upload_kyc(%Kycdirectors{} = kycdirectors, attrs) do
    kycdirectors
    |> cast(
         attrs,
         [
           :directors_id,
           :documenttype_id,
           :document_number,
           :issue_date,
           :expiry_date,
           :file_type,
           :file_name,
           :file_location,
           :file_location_two,
           :status,
           :type,
           :inserted_by
         ]
       )
    |> validate_required([:directors_id, :documenttype_id, :file_location])
  end
  def changesetUploadIdProof(%Kycdirectors{} = kycdirectors, attrs) do
    kycdirectors
    |> cast(
         attrs,
         [
           :directors_id,
           :documenttype_id,
           :document_number,
           :issue_date,
           :expiry_date,
           :country,
           :file_type,
           :file_name,
           :file_location,
           :file_location_two,
           :status,
           :type,
           :inserted_by
         ]
       )
    |> validate_required(
         [:directors_id, :documenttype_id, :file_location, :country, :document_number, :issue_date, :expiry_date]
       )
    |> validate_format(:document_number, ~r/^[A-z0-9- ]+$/)
    |> validate_length(:document_number, max: 20)
    |> validate_current_or_future_date(:expiry_date)
    |> validate_current_or_future_date(:issue_date)
  end
  def changeset_upload__drector_kyc(%Kycdirectors{} = kycdirectors, attrs) do
    kycdirectors
    |> cast(
         attrs,
         [
           :directors_id,
           :documenttype_id,
           :document_number,
           :issue_date,
           :expiry_date,
           :file_type,
           :file_name,
           :file_location,
           :file_location_two,
           :status,
           :type,
           :inserted_by
         ]
       )
    |> validate_required([:directors_id, :documenttype_id, :document_number, :file_location])
  end

  def updateGBGResponse(%Kycdirectors{} = kycdirectors, attrs) do
    kycdirectors
    |> cast(attrs, [:reference_id, :fourstop_response, :status])
    |> validate_required([])
  end

  def kycChangeset(%Kycdirectors{} = kycdirectors, attrs) do
    kycdirectors
    |> cast(attrs, [:reason, :inserted_by, :status, :refered_id])
    |> validate_required([:reason])
    |> validate_length(:reason, max: 255)
    |> validate_inclusion(:status, ["A", "AC", "D", "R", "RF", "FSP", "4P"])
  end

  def kycStatusChangeset(%Kycdirectors{} = kycdirectors, attrs) do
    kycdirectors
    |> cast(attrs, [:status, :directors_id])
    |> validate_required([:status])
    |> validate_inclusion(:status, ["A", "AC", "D", "R", "RF", "FSP", "4P"])
  end

  def kycStatusUpdateChangeset(%Kycdirectors{} = kycdirectors, attrs) do
    kycdirectors
    |> cast(attrs, [:status])
    |> validate_required([:status])
    |> validate_inclusion(:status, ["A", "AC", "D", "R", "RF", "FSP", "4P"])
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
