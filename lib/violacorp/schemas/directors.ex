defmodule Violacorp.Schemas.Directors do
  use Ecto.Schema
  import Ecto.Changeset

  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Kycdirectors

  @moduledoc "Directors Table Model"

  schema "directors" do
    field :position, :string
    field :title, :string
    field :employeeids, :string
    field :email_id, :string
    field :first_name, :string
    field :middle_name, :string
    field :last_name, :string
    field :date_of_birth, :date
    field :gender, :string
    field :status, :string
    field :signature, :string
    field :mendate_signature, :string
    field :access_type, :string
    field :is_primary, :string
    field :verify_kyc, :string
    field :allocating_cards, :string
    field :as_employee, :string
    field :sequence, :integer
    field :employee_id, :integer
    field :inserted_by, :integer

    belongs_to :company, Violacorp.Schemas.Company
    has_many :addressdirectors, Violacorp.Schemas.Addressdirectors
    has_many :contactsdirectors, Violacorp.Schemas.Contactsdirectors
    has_many :kycdirectors, Violacorp.Schemas.Kycdirectors
    has_many :kycdirectorsaddress, Violacorp.Schemas.Kycdirectors
    has_many :kyclogin, Violacorp.Schemas.Kyclogin
#    has_many :updatehistory, Violacorp.Schemas.UpdateHistory
#    has_many :fourstop, Violacorp.Schemas.Fourstop

    timestamps()
  end

  @doc false
  def changeset(%Directors{} = directors, attrs) do
    directors
    |> cast(attrs, [:company_id, :position, :employeeids, :email_id, :title, :first_name, :middle_name, :last_name, :date_of_birth, :gender, :status, :signature, :sequence, :access_type, :is_primary, :inserted_by])
    |> validate_required([:position, :first_name, :last_name])
    |> foreign_key_constraint(:company, name: :fk_directors_company1)
    |> update_change(:first_name, &String.trim/1)
    |> update_change(:last_name, &String.trim/1)
    |> update_change(:first_name, &String.capitalize/1)
    |> update_change(:last_name, &String.capitalize/1)
    |> validate_format(:first_name, ~r/[A-z-]+$/, message: "Make sure you only use A-z")
    |> validate_length(:first_name, min: 3, max: 40)
    |> validate_format(:middle_name, ~r/[A-z-]+$/, message: "Make sure you only use A-z")
    |> validate_length(:middle_name, min: 1, max: 40)
    |> validate_format(:position, ~r/[A-z-]+$/)
    |> validate_length(:position, max: 40)
    |> validate_format(:last_name, ~r/[A-z]+$/, message: "Make sure you only use A-z")
    |> validate_length(:last_name, min: 3, max: 40)
  end

  def changeset_update(%Directors{} = directors, attrs) do
    directors
    |> cast(attrs, [:company_id, :position, :employeeids, :email_id, :title, :first_name, :middle_name, :last_name, :date_of_birth, :gender, :status, :signature, :mendate_signature, :sequence, :access_type, :is_primary, :inserted_by])
    |> validate_required([:position, :first_name, :last_name,:signature, :title, :gender])
    |> update_change(:first_name, &String.trim/1)
    |> update_change(:last_name, &String.trim/1)
    |> update_change(:signature, &String.trim/1)
#    |> update_change(:mendate_signature, &String.trim/1)
    |> update_change(:first_name, &String.capitalize/1)
    |> update_change(:last_name, &String.capitalize/1)
    |> validate_format(:first_name, ~r/[A-z-]+$/, message: "Make sure you only use A-z")
    |> validate_length(:first_name, min: 3, max: 40)
    |> validate_format(:middle_name, ~r/[A-z-]+$/, message: "Make sure you only use A-z")
    |> validate_length(:middle_name, min: 1, max: 40)
    |> validate_format(:position, ~r/[A-z-]+$/)
    |> validate_length(:position, max: 40)
    |> validate_format(:last_name, ~r/[A-z]+$/, message: "Make sure you only use A-z")
    |> validate_length(:last_name, min: 3, max: 40)
    |> validate_format(:email_id, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}/, message: "Please use following format word@word.com")
    |> validate_current_or_future_date(:date_of_birth)
  end

  @doc false
  def changeset_contact(directors, attrs \\ :empty) do
    directors
    |> cast(attrs, [:company_id, :verify_kyc, :position, :employeeids, :email_id, :title, :first_name, :middle_name, :last_name, :date_of_birth, :gender, :status, :signature, :sequence, :access_type, :is_primary, :inserted_by])
    |> cast_assoc(:addressdirectors, required: false)
    |> cast_assoc(:contactsdirectors, required: false)
    |> cast_assoc(:kycdirectors, required: false)
    |> cast_assoc(:kycdirectorsaddress, required: false, with: &Kycdirectors.changeset_addess/2)
    |> cast_assoc(:kyclogin, required: false)
    |> validate_required([:position, :title, :first_name, :last_name, :date_of_birth, :signature])
    |> update_change(:first_name, &String.trim/1)
    |> update_change(:last_name, &String.trim/1)
    |> update_change(:signature, &String.trim/1)
    |> update_change(:first_name, &String.capitalize/1)
    |> update_change(:last_name, &String.capitalize/1)
    |> validate_format(:first_name, ~r/^[A-z-]+$/, message: "Make sure you only use A-z")
    |> validate_length(:first_name, min: 3, max: 40)
    |> validate_format(:middle_name, ~r/[A-z-]+$/, message: "Make sure you only use A-z")
    |> validate_length(:middle_name, min: 1, max: 40)
    |> validate_format(:last_name, ~r/^[A-z]+$/, message: "Make sure you only use A-z")
    |> validate_length(:last_name, min: 3, max: 40)
    |> validate_length(:signature, max: 80)
    |> validate_current_or_future_date(:date_of_birth)
# |> validate_format(:email_id, ~r/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,25}$/, message: "Please use following format word@word.com")
  end

  @doc false
  def reg_step_five(directors, attrs \\ :empty) do
    directors
    |> cast(attrs, [:company_id, :position, :employeeids, :email_id, :title, :first_name, :middle_name, :last_name, :date_of_birth, :gender, :status, :signature, :sequence, :access_type, :is_primary, :inserted_by])
    |> cast_assoc(:addressdirectors, required: false)
    |> cast_assoc(:contactsdirectors, required: false)
    |> cast_assoc(:kycdirectors, required: false)
#    |> cast_assoc(:fourstop, required: false)
    |> cast_assoc(:kycdirectorsaddress, required: false, with: &Kycdirectors.changeset_addess/2)
    |> validate_required([:position, :title, :first_name, :last_name, :date_of_birth, :email_id])
    |> update_change(:first_name, &String.trim/1)
    |> update_change(:last_name, &String.trim/1)
    |> update_change(:signature, &String.trim/1)
    |> update_change(:first_name, &String.capitalize/1)
    |> update_change(:last_name, &String.capitalize/1)
    |> validate_format(:first_name, ~r/^[A-z-]+$/, message: "Make sure you only use A-z")
    |> validate_length(:first_name, min: 3, max: 40)
    |> validate_format(:middle_name, ~r/[A-z-]+$/, message: "Make sure you only use A-z")
    |> validate_length(:middle_name, min: 1, max: 40)
    |> validate_format(:last_name, ~r/^[A-z]+$/, message: "Make sure you only use A-z")
    |> validate_length(:last_name, min: 3, max: 40)
#    |> validate_format(:email_id, ~r/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,25}$/, message: "Please use following format word@word.com")
  end

  @doc false
  def reg_step_one(directors, attrs \\ :empty) do
    directors
    |> cast(attrs, [:company_id, :position, :title, :first_name, :middle_name, :last_name, :signature, :sequence, :access_type, :is_primary, :inserted_by])
    |> validate_required([:position, :title, :first_name, :last_name, :signature])
    |> update_change(:first_name, &String.trim/1)
    |> update_change(:last_name, &String.trim/1)
    |> update_change(:signature, &String.trim/1)
    |> update_change(:first_name, &String.capitalize/1)
    |> update_change(:last_name, &String.capitalize/1)
    |> validate_format(:first_name, ~r/[A-z-]+$/, message: "Make sure you only use A-z")
    |> validate_length(:first_name, min: 3, max: 40)
    |> validate_format(:middle_name, ~r/[A-z-]+$/, message: "Make sure you only use A-z")
    |> validate_length(:middle_name, min: 1, max: 40)
    |> validate_format(:last_name, ~r/[A-z]+$/, message: "Make sure you only use A-z")
    |> validate_length(:last_name, min: 3, max: 40)
  end

  @doc false
  def reg_step_oneV3(directors, attrs \\ :empty) do
    directors
    |> cast(attrs, [:company_id, :employeeids, :position, :title, :first_name, :middle_name, :date_of_birth, :email_id, :last_name, :gender, :sequence, :verify_kyc, :access_type, :is_primary, :inserted_by])
    |> validate_required([:position, :title, :first_name, :last_name, :gender])
    |> cast_assoc(:addressdirectors, required: false)
    |> cast_assoc(:contactsdirectors, required: false)
    |> cast_assoc(:kycdirectors, required: false)
    |> cast_assoc(:kycdirectorsaddress, required: false, with: &Kycdirectors.changeset_addess/2)
    |> update_change(:first_name, &String.trim/1)
    |> update_change(:last_name, &String.trim/1)
    |> update_change(:first_name, &String.capitalize/1)
    |> update_change(:last_name, &String.capitalize/1)
    |> validate_format(:first_name, ~r/^[A-z-]+$/, message: "Make sure you only use A-z")
    |> validate_length(:first_name, min: 3, max: 40)
    |> validate_format(:middle_name, ~r/[A-z-]+$/, message: "Make sure you only use A-z")
    |> validate_length(:middle_name, min: 1, max: 40)
    |> validate_format(:last_name, ~r/^[A-z]+$/, message: "Make sure you only use A-z")
    |> validate_length(:last_name, min: 3, max: 40)
  end

  @doc false
  def reg_step_fiveV3(directors, attrs \\ :empty) do
    directors
    |> cast(attrs, [:company_id, :position, :first_name, :middle_name, :last_name, :email_id, :sequence, :gender, :access_type, :verify_kyc, :is_primary, :inserted_by])
    |> validate_required([:position, :first_name, :last_name, :email_id])
    |> cast_assoc(:kyclogin, required: false)
    |> update_change(:first_name, &String.trim/1)
    |> update_change(:last_name, &String.trim/1)
    |> update_change(:first_name, &String.capitalize/1)
    |> update_change(:last_name, &String.capitalize/1)
    |> validate_format(:first_name, ~r/^[A-z-]+$/, message: "Make sure you only use A-z")
    |> validate_length(:first_name, min: 3, max: 40)
    |> validate_format(:middle_name, ~r/[A-z-]+$/, message: "Make sure you only use A-z")
    |> validate_length(:middle_name, min: 1, max: 40)
    |> validate_format(:last_name, ~r/^[A-z]+$/, message: "Make sure you only use A-z")
    |> validate_length(:last_name, min: 3, max: 40)
    |> validate_format(:email_id, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}/)
  end


  @doc false
  def allocating_cards(directors, attrs \\ :empty) do
    directors
    |> cast(attrs, [:allocating_cards])
    |> validate_required([:allocating_cards])
  end

  def update_status(directors, attrs \\ :empty) do
    directors
    |> cast(attrs, [:as_employee, :employee_id, :status])
  end

  def updateDob(directors, attrs ) do
    directors
    |> cast(attrs, [:date_of_birth])
    |> validate_required([:date_of_birth])
    |> validate_current_or_future_date(:date_of_birth)
  end

  def update_gender(directors, attrs \\ :empty) do
    directors
    |> cast(attrs, [:gender])
    |> validate_required([:gender])
    |> validate_inclusion(:gender, ["M", "F"])
  end

  def update_email(directors, attrs ) do
    directors
    |> cast(attrs, [:email_id])
    |> validate_required([:email_id])
    |> validate_format(:email_id, ~r/^[A-z0-9-.-_@]+$/)
    |> validate_length(:email_id, max: 150)
  end
  def update_director_email(directors, attrs ) do
    directors
    |> cast(attrs, [:email_id])
    |> validate_required([:email_id])
    |> update_change(:email_id, &String.trim/1)
    |> validate_format(:email_id, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}/)
    |> validate_length(:email_id, max: 150)
  end

  def changesetEmployee(directors, attrs) do
    directors
    |> cast(attrs, [:employee_id])
  end


  def changesetSignature(directors, attrs) do
    directors
    |> cast(attrs, [:signature])
  end

  def changesetVerifyKyc(directors, attrs) do
    directors
    |> cast(attrs, [:verify_kyc])
  end

  def changesetSequence(directors, attrs) do
    directors
    |> cast(attrs, [:sequence])
  end

  def changesetPrimary(directors, attrs) do
    directors
    |> cast(attrs, [:is_primary])
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
    comparison = Date.compare(today, date)
    if comparison == :lt || comparison == :eq do
      if (field == :date_of_birth), do: changeset |> add_error(field, "Date of Birth must in the past.")
    else
      current_year = today.year
      dob_year = date.year
      diff = current_year - dob_year
      if (diff < 18), do: changeset |> add_error(field, "Age must be atleast 18 year."), else: changeset
    end
  end

end