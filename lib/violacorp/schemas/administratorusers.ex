defmodule Violacorp.Schemas.Administratorusers do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Administratorusers

  @moduledoc "Administratorusers Table Model"

  schema "administratorusers" do
    field :fullname, :string
    field :role, :string
    field :unique_id, :string
    field :email_id, :string
    field :password, Cloak.SHA256Field
    field :secret_password, Cloak.SHA256Field
    field :contact_number, :string
    field :status, :string
    field :is_primary, :string
    field :api_token, :string
    field :notification_status, :string
    field :browser_token, :string
    field :inserted_by, :integer
    field :permissions, :string

    has_many :adminaccounts, Violacorp.Schemas.Adminaccounts
    has_many :tags, Violacorp.Schemas.Tags

    timestamps()
  end

  @doc false
  def changeset(%Administratorusers{} = administratorusers, attrs) do
    administratorusers
    |> cast(attrs, [:fullname, :role, :unique_id, :email_id, :password, :contact_number, :inserted_by])
    |> validate_required([:fullname, :role, :email_id, :contact_number])
  end

  @doc false
  def changeset_update(%Administratorusers{} = administratorusers, attrs) do
    administratorusers
    |> cast(attrs, [:fullname, :role, :email_id, :is_primary, :contact_number, :status])
    |> validate_required([:fullname, :role, :email_id, :is_primary, :contact_number, :status])
    |> validate_inclusion(:is_primary, ["Y", "N"])
    |> validate_inclusion(:status, ["A", "D", "B"])
  end

  @doc false
  def changeset_updatepassword(%Administratorusers{} = administratorusers, attrs) do
    administratorusers
    |> cast(attrs, [:secret_password])
  end

  @doc false
  def changeset_password(administratorusers, attrs \\ :empty) do
    administratorusers
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> update_change(:password, &String.trim/1)
    |> validate_format(
         :password,
         ~r/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[#$^+=!*()@%&]).{8,25}$/,
         message: "Password must be between 8-25 digits and have at least one number, one lowercase, one uppercase alphabet and one special character (e.g. #$^+=!*()@%&)."
       )
  end

  @doc false
  def login_changeset(%Administratorusers{} = administratorusers, attrs) do
    administratorusers
    |> cast(attrs, [:email_id, :password, :status])
    |> validate_required([:email_id, :password])
  end

  def generate_password_admin(%Administratorusers{} = administratorusers, attrs)do
    administratorusers
    |> cast(attrs, [:secret_password])
    |> validate_required([:secret_password])
  end

  def changesetToken(administratorusers, attrs) do
    administratorusers
    |> cast(attrs, [:api_token])
  end

  @doc "
   This is for notification status update
       "
  def changesetNotificationStatus(admin, attrs) do
    admin
    |> cast(attrs, [:notification_status])
    |> validate_required([:notification_status])
    |> validate_inclusion(:notification_status, ["Y", "N"])
  end

  @doc "
   This is for browser token update
       "
  def changesetBrowserToken(administratorusers, attrs) do
    administratorusers
    |> cast(attrs, [:browser_token])
    |> validate_required([:browser_token])
  end

  @doc "
   This is for browser token delete
       "
  def changesetSDeleteBrowserToken(administratorusers, attrs) do
    administratorusers
    |> cast(attrs, [:browser_token])
  end
end