defmodule Violacorp.Schemas.Commanall do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Commanall

  @moduledoc "Commanall Table Model"

  schema "commanall" do
    field :email_id, :string
    field :password, Cloak.SHA256Field
    field :vpin, Cloak.SHA256Field
    field :status, :string
    field :viola_id, :string
    field :accomplish_userid, :integer
    field :request, :string
    field :response, :string
    field :reg_step, :string
    field :step, :string
    field :reg_data, :string
    field :id_proof, :string
    field :m_api_token, :string
    field :api_token, :string
    field :ip_address, :string
    field :address_proof, :string
    field :card_requested, :string
    field :on_boarding_fee, :string
    field :as_employee, :string
    field :trust_level, :string
    field :as_login, :string
    field :check_version, :string
    field :internal_status, :string
    field :inserted_by, :integer
    field :username, :string
    field :email_verified, :string
    field :mobile_verified, :string
    field :start_date, :date

    belongs_to :company, Violacorp.Schemas.Company
    belongs_to :employee, Violacorp.Schemas.Employee
    has_many :kycdocuments, Violacorp.Schemas.Kycdocuments
    has_many :contacts, Violacorp.Schemas.Contacts
    has_many :address, Violacorp.Schemas.Address
    has_many :notifications, Violacorp.Schemas.Notifications
    has_many :duefees, Violacorp.Schemas.Duefees
    has_many :resendmailhistory, Violacorp.Schemas.Resendmailhistory
    has_many :expense, Violacorp.Schemas.Expense
    has_many :blockusers, Violacorp.Schemas.Blockusers
    has_many :fourstop, Violacorp.Schemas.Fourstop
    has_one :devicedetails, Violacorp.Schemas.Devicedetails
    has_many :otp, Violacorp.Schemas.Otp
    has_many :mandate, Violacorp.Schemas.Mandate
    has_many :tags, Violacorp.Schemas.Tags
    timestamps()
  end

  @doc false
  def changeset(%Commanall{} = commanall, attrs) do
    commanall
    |> cast(attrs, [:company_id, :viola_id, :email_id])
    |> validate_required([:email_id])
    |> unique_constraint(:email_id)
    #    |> validate_format(:email_id, ~r/^[\w-]+(?:\._[\w-]+)*@(?:[\w-]+\.)+[a-zA-Z]{2,7}$/, message: "Please use following format word@word.com")
  end

  @doc false
  def registration_changeset(%Commanall{} = commanall, attrs) do
    commanall
    |> cast(attrs, [:password, :vpin, :reg_step, :status])
    |> validate_required([:password, :vpin])
    |> validate_length(:password, min: 8, max: 255)
    |> validate_length(:vpin, min: 4, max: 4)
  end

  @doc false
  def registration_accomplish(%Commanall{} = commanall, attrs) do
    commanall
    |> cast(attrs, [:accomplish_userid, :request, :response])
  end

  @doc false
  def login_changeset(%Commanall{} = commanall, attrs) do
    commanall
    |> cast(attrs, [:company_id, :employee_id, :viola_id, :email_id, :password, :status])
    |> validate_required([:email_id, :password])
  end

  @doc false
  def changeset_company_contact(commanall, attrs \\ :empty) do
    commanall
    |> cast(attrs, [:viola_id, :email_id, :password, :reg_data, :step, :reg_step, :status])
    |> validate_required([:email_id])
    |> cast_assoc(:contacts, required: false)
    |> unique_constraint(:email_id, name: :email_id_UNIQUE, message: "User already registered with this email")
    |> update_change(:email_id, &String.trim/1)
    |> validate_length(:email_id, max: 150)
  end

  @doc false
  def changeset_contact(commanall, attrs \\ :empty) do
    commanall
    |> cast(attrs, [:viola_id, :email_id, :vpin, :password, :as_employee, :status])
    |> validate_required([:email_id])
    |> cast_assoc(:address, required: false)
    |> cast_assoc(:contacts, required: false)
    |> unique_constraint(:email_id, name: :email_id_UNIQUE, message: "User already registered with this email")
    |> update_change(:email_id, &String.trim/1)
    |> validate_length(:email_id, max: 150)
    |> validate_length(:vpin, min: 4, max: 4)
  end

  @doc false
  def changeset_contactinfo(commanall, attrs \\ :empty) do
    commanall
    |> cast(attrs, [:viola_id, :email_id, :password, :status])
    |> cast_assoc(:contacts, required: false)
  end

  @doc false
  def changeset_updatepassword(commanall, attrs \\ :empty) do
    commanall
    |> cast(attrs, [:password])
    |> validate_required([:password])
  end

  @doc false
  def changeset_updatepin(commanall, attrs \\ :empty) do
    commanall
    |> cast(attrs, [:vpin])
    |> validate_required([:vpin])
    |> validate_format(:vpin, ~r/^[0-9]+$/)
    |> validate_length(:vpin, min: 4, max: 4)
  end

  @doc false
  def changeset_updateemail(commanall, attrs \\ :empty) do
    commanall
    |> cast(attrs, [:email_id])
    |> validate_required([:email_id])
  end

  @doc false
  def changesetSteps(%Commanall{} = commanall, attrs) do
    commanall
    |> cast(attrs, [:step, :reg_data, :reg_step, :status])
  end

  @doc false
  def changesetRequest(%Commanall{} = commanall, attrs) do
    commanall
    |> cast(attrs, [:card_requested, :status])
  end

  @doc false
  def changesetFee(%Commanall{} = commanall, attrs) do
    commanall
    |> cast(attrs, [:on_boarding_fee])
  end

  @doc "new reg"
  def changeset_first_step(commanall, attrs \\ :empty) do
    commanall
    |> cast(attrs, [:viola_id, :email_id, :password, :vpin, :reg_data, :step, :reg_step, :status, :ip_address])
    |> validate_required([:email_id])
    |> cast_assoc(:contacts, required: false)
    |> unique_constraint(:email_id, name: :email_id_UNIQUE, message: "User already registered with this email")
    |> update_change(:email_id, &String.trim/1)
    |> validate_format(
         :password,
         ~r/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[#$^+=!*()@%&]).{8,15}$/,
         message: "Password must be between 8-15 digits and have at least one number, one lowercase, one uppercase alphabet and one special character (e.g. #$^+=!*()@%&)."
       )
    |> validate_length(:email_id, max: 150)
  end

  @doc "change Email Id"
  def changesetEmail(commanall, attrs \\ :empty) do
    commanall
    |> cast(attrs, [:email_id])
    |> validate_required([:email_id])
    |> unique_constraint(:email_id, name: :email_id_UNIQUE, message: "User already registered with this email")
    |> update_change(:email_id, &String.trim/1)
    |> validate_format(:email_id, ~r/^[A-z0-9-.-_@]+$/)
    |> validate_length(:email_id, max: 150)
  end

  @doc "change Email Id"
  def changesetEmailUpdate(commanall, attrs \\ :empty) do
    commanall
    |> cast(attrs, [:email_id])
    |> validate_required([:email_id])
    |> unique_constraint(:email_id, name: :email_id_UNIQUE, message: "User already registered with this email")
    |> update_change(:email_id, &String.trim/1)
    |> validate_format(:email_id, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}/)
    |> validate_length(:email_id, max: 150)
  end
  @doc "as_employee"
  def changeset_as_employee(commanall, attrs \\ :empty) do
    commanall
    |> cast(attrs, [:employee_id, :as_employee, :card_requested])
    |> validate_required([:employee_id])
  end

  @doc "Update Status"
  def updateStatus(%Commanall{} = commanall, attrs) do
    commanall
    |> cast(attrs, [:status, :api_token, :m_api_token, :internal_status])
  end

  @doc false
  def update_token(party, attrs) do
    party
    |> cast(attrs, [:api_token, :m_api_token, :ip_address])
  end

  @doc false
  def update_login(party, attrs) do
    party
    |> cast(attrs, [:as_login])
  end

  @doc "Update Status"
  def updateField(%Commanall{} = commanall, attrs) do
    commanall
    |> cast(attrs, [:on_boarding_fee])
  end

  @doc false
  def updateTrustLevel(party, attrs) do
    party
    |> cast(attrs, [:trust_level])
    |> validate_required([:trust_level])
  end
  @doc false
  def chagesetStartDate(party, attrs) do
    party
    |> cast(attrs, [:start_date])
    |> validate_required([:start_date])
  end

  @doc false
  def changesetInternalStatus(party, attrs) do
    party
    |> cast(attrs, [:internal_status])
    |> validate_required([:internal_status])
    |> validate_inclusion(:internal_status, ["A", "C", "S", "UR"])
  end
  def changesetRegistrationStep(party, attrs) do
    party
    |> cast(attrs, [:reg_step, :company_id])
    |> validate_required([:reg_step])
    |> validate_inclusion(:reg_step, ["1", "11", "12", "2", "3", "4", "5", "6"])
  end

  @doc false
  def updateTrustLevelandEmail(party, attrs) do
    party
    |> cast(attrs, [:trust_level, :email_id])
    |> validate_required([:trust_level])
    |> validate_inclusion(:trust_level, ["1", "2", "3"])
  end
end
