defmodule Violacorp.Schemas.Adminbeneficiaries do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc "adminbeneficiaries Table Model"

  schema "adminbeneficiaries" do
    field :fullname, :string
    field :nick_name, :string
    field :sort_code, :string
    field :account_number, :string
    field :description, :string
    field :contacts, :string
    field :notification, :string
    field :type, :string
    field :status, :string
    field :inserted_by, :integer

    belongs_to :adminaccounts, Violacorp.Schemas.Adminaccounts

    timestamps()
  end

  @doc false
  def changeset(adminbeneficiaries, attrs) do
    adminbeneficiaries
    |> cast(attrs, [:adminaccounts_id, :fullname, :nick_name, :sort_code, :account_number, :description, :contacts, :notification, :type, :status, :inserted_by])
    |> validate_required([:fullname, :sort_code, :account_number])
    |> validate_length(:fullname, min: 2, max: 50)
    |> validate_format(:fullname, ~r/^[A-z ]+$/)
    |> validate_format(:nick_name, ~r/^[A-z ]+$/)
    |> validate_format(:sort_code, ~r/^[0-9]+$/)
    |> validate_format(:account_number, ~r/^[0-9]+$/)
    |> validate_length(:nick_name, min: 2, max: 45)
    |> validate_length(:sort_code, max: 45)
    |> validate_length(:account_number, max: 45)
    |> validate_length(:description, min: 2, max: 45)
  end

  def update_changeset(adminbeneficiaries, attrs) do
    adminbeneficiaries
    |> cast(attrs, [:fullname, :nick_name, :sort_code, :account_number, :description])
    |> validate_required([:fullname, :sort_code, :account_number])
    |> validate_length(:fullname, min: 2, max: 50)
    |> validate_format(:fullname, ~r/^[A-z ]+$/)
    |> validate_format(:nick_name, ~r/^[A-z ]+$/)
    |> validate_length(:nick_name, min: 2, max: 45)
    |> validate_length(:sort_code, max: 45)
    |> validate_length(:account_number, max: 45)
    |> validate_length(:description, min: 2, max: 45)
  end
end
