defmodule Violacorp.Schemas.Kyclogin do
  use Ecto.Schema
  import Ecto.Changeset

  alias Violacorp.Schemas.Kyclogin

  schema "kyclogin" do
      field :username, :string
      field :directors_company_id, :integer
      field :password, Cloak.SHA256Field
      field :steps, :string
      field :status, :string
      field :otp_code, :string
      field :last_login, :naive_datetime
      field :inserted_by, :integer

      belongs_to :directors, Violacorp.Schemas.Directors

      timestamps()
  end

  def changeset(%Kyclogin{} = kyclogin, attr)do
     kyclogin
     |> cast(attr, [:directors_id, :directors_company_id, :username,:password, :steps, :status, :last_login,:inserted_by])
     |> validate_required(:username)
     |> foreign_key_constraint(:directors, name: :fk_kyclogin_directors1)
     |> validate_length(:password, min: 8, max: 15)
  end

  def stepsChangeset(%Kyclogin{} = kyclogin, attr)do
    kyclogin
    |> cast(attr, [:steps])
  end

  def passwordChangeset(%Kyclogin{} = kyclogin, attr)do
    kyclogin
    |> cast(attr, [:password])
  end

  def stepsOTPChangeset(%Kyclogin{} = kyclogin, attr)do
    kyclogin
    |> cast(attr, [:steps, :otp_code])
  end

  def updateOTP(%Kyclogin{} = kyclogin, attr) do
    kyclogin
    |> cast(attr,[:otp_code])
    |> validate_required(:otp_code)
    |> validate_length(:otp_code, max: 255)
  end

  def updateEmailID(%Kyclogin{} = kyclogin, attr) do
    kyclogin
    |> cast(attr,[:username])
    |> validate_required(:username)
  end

end