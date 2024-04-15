defmodule Violacorp.Schemas.Kycdocuments do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Kycdocuments

  @moduledoc "Kycdocuments Table Model"

  schema "kycdocuments" do
    field :commanall_id, :integer
    field :document_number, :string
    field :issue_date, :date
    field :expiry_date, :date
    field :file_type, :string
    field :file_name, :string
    field :file_location, :string
    field :file_location_two, :string
    field :status, :string
    field :country, :string
    field :type, :string
    field :content, :string
    field :fourstop_response, :string
    field :reason, :string
    field :refered_id, :integer
    field :reference_id, :string
    field :director_id, :integer
    field :inserted_by, :integer

    belongs_to :documenttype, Violacorp.Schemas.Documenttype
    timestamps()
  end

  @doc false
  def changeset(%Kycdocuments{} = kycdocuments, attrs) do
    kycdocuments
    |> cast(
         attrs,
         [
           :director_id,
           :commanall_id,
           :documenttype_id,
           :document_number,
           :expiry_date,
           :issue_date,
           :file_type,
           :file_name,
           :file_location,
           :status,
           :type,
           :content,
           :inserted_by
         ]
       )
    |> validate_required([:documenttype_id, :document_number, :expiry_date])
    |> update_change(:document_number, &String.trim/1)
    |> validate_format(:document_number, ~r/^[A-z0-9- ]+$/)
    |> validate_length(:document_number, max: 45)
      #    |> validate_inclusion(:file_type, ["jpg"])
      #    |> validate_length(:file_type, is: 3)
    |> validate_current_or_future_date(:expiry_date)
    |> validate_current_or_future_date(:issue_date)
  end

  def changeset_upload_employee_kyc(%Kycdocuments{} = kycdocuments, attrs) do
    kycdocuments
    |> cast(
         attrs,
         [
           :commanall_id,
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
    |> validate_required([:commanall_id, :documenttype_id, :document_number])
    |> update_change(:document_number, &String.trim/1)
    |> validate_format(:document_number, ~r/^[A-z0-9- ]+$/)
    |> validate_length(:document_number, max: 45)
  end

  def changeset_upload_kyb(%Kycdocuments{} = kycdocuments, attrs) do
    kycdocuments
    |> cast(
         attrs,
         [
           :commanall_id,
           :documenttype_id,
           :document_number,
           :expiry_date,
           :issue_date,
           :file_type,
           :file_name,
           :file_location,
           :status,
           :type,
           :content,
           :inserted_by
         ]
       )
    |> validate_required([:documenttype_id, :file_location, :commanall_id])
    |> foreign_key_constraint(:commanall_id, name: :fk_kycdocuments_commanall1, message: "Invalid Commanall_ID")

  end

  @doc false
  def changesetAddress(%Kycdocuments{} = kycdocuments, attrs) do
    kycdocuments
    |> cast(
         attrs,
         [
           :commanall_id,
           :documenttype_id,
           :document_number,
           :expiry_date,
           :issue_date,
           :file_type,
           :file_name,
           :file_location_two,
           :file_location,
           :status,
           :type,
           :content,
           :inserted_by
         ]
       )
    |> validate_required([:documenttype_id, :file_type, :content])
    |> update_change(:document_number, &String.trim/1)
    |> validate_format(:document_number, ~r/^[A-z0-9- ]+$/)
      #    |> validate_inclusion(:file_type, ["jpg"])
      #    |> validate_length(:file_type, is: 3)
    |> foreign_key_constraint(:documenttype, name: :fk_kycdocuments_documenttype1)
    |> validate_current_or_future_date(:expiry_date)
    |> validate_current_or_future_date(:issue_date)
    #    |> validate_format(:content, ~r/^[A-z0-9+/=]*$/)
  end

  @doc false
  def changesetIDProof(%Kycdocuments{} = kycdocuments, attrs) do
    kycdocuments
    |> cast(
         attrs,
         [
           :commanall_id,
           :documenttype_id,
           :country,
           :document_number,
           :expiry_date,
           :issue_date,
           :file_type,
           :file_name,
           :file_location,
           :file_location_two,
           :status,
           :type,
           :content,
           :inserted_by
         ]
       )
    |> validate_required([:documenttype_id, :document_number, :country, :issue_date, :expiry_date])
    |> update_change(:document_number, &String.trim/1)
    |> validate_format(:document_number, ~r/^[A-z0-9- ]+$/)
    |> validate_length(:document_number, min: 6, max: 45)
    |> validate_inclusion(:type, ["I"])
    |> validate_current_or_future_date(:expiry_date)
    |> validate_current_or_future_date(:issue_date)
  end

  @doc false
  def changesetAddressProof(%Kycdocuments{} = kycdocuments, attrs) do
    kycdocuments
    |> cast(
         attrs,
         [
           :commanall_id,
           :documenttype_id,
           :document_number,
           :expiry_date,
           :issue_date,
           :file_type,
           :file_name,
           :file_location,
           :status,
           :type,
           :content,
           :inserted_by
         ]
       )
    |> validate_required([:documenttype_id])
    |> update_change(:document_number, &String.trim/1)
    |> validate_format(:document_number, ~r/^[A-z0-9- ]+$/)
    |> validate_length(:document_number, max: 45)
    |> validate_inclusion(:type, ["A"])
  end

  @doc false
  def update_status(%Kycdocuments{} = kycdocuments, attrs) do
    kycdocuments
    |> cast(attrs, [:status, :director_id])
    |> validate_required([:status])
  end
  @doc false
  def update_status_changeset(%Kycdocuments{} = kycdocuments, attrs) do
    kycdocuments
    |> cast(attrs, [:status])
    |> validate_required([:status])
  end

  def updateGBGResponse(%Kycdocuments{} = kycdocuments, attrs) do
    kycdocuments
    |> cast(attrs, [:reference_id, :fourstop_response, :status])
    |> validate_required([])
  end

  def changesetKycOverride(%Kycdocuments{} = kycdocuments, attrs) do
    kycdocuments
    |> cast(attrs, [:status, :reason, :refered_id])
    |> validate_required([:reason])
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
