defmodule Violacorp.Schemas.Company do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Directors

  @moduledoc "Company Table Model"

  schema "company" do
#    field :countries_id, :integer
    field :group_id, :integer
    field :company_name, :string
    field :company_cin, :string
    field :company_logo, :string
    field :registration_number, :string
    field :date_of_registration, :date
    field :landline_number, :string
    field :company_type, :string
    field :sector_id, :integer
    field :sector_details, :string
    field :monthly_transfer, :integer
    field :company_website, :string
    field :loading_fee, :string
    field :date_from, :date
    field :date_to, :date
    field :inserted_by, :integer

    has_many :companyaccounts, Violacorp.Schemas.Companyaccounts
    has_many :commanall, Violacorp.Schemas.Commanall
    has_many :directors, Violacorp.Schemas.Directors
    has_many :companybankaccount, Violacorp.Schemas.Companybankaccount
    has_many :transactions, Violacorp.Schemas.Transactions
    has_many :employee, Violacorp.Schemas.Employee
    belongs_to :countries, Violacorp.Schemas.Countries
    has_many :shareholder, Violacorp.Schemas.Shareholder
    has_many :companydocumentinfo, Violacorp.Schemas.Companydocumentinfo

    timestamps()
  end

  @doc false
  def changeset(%Company{} = company, attrs) do
    company
    |> cast(attrs, [:countries_id, :loading_fee, :company_name, :company_cin, :company_logo, :registration_number, :date_of_registration, :landline_number, :company_website, :company_type, :inserted_by])
    |> validate_required([:countries_id, :company_type, :company_name])
    |> update_change(:company_name, &String.trim/1)
    |> update_change(:registration_number, &String.trim/1)
    |> validate_length(:company_name, min: 3, max: 40)
    |> validate_format(:company_name, ~r/^[A-z0-9- ]+$/)
    |> validate_format(:registration_number, ~r/[^A-z0-9- ]+$/)
    |> validate_inclusion(:loading_fee, ["W", "N"])
  end

  @doc false
  def changeset_reg_step_one(company, attrs \\ :empty) do
    company
    |> cast(attrs, [:countries_id, :loading_fee, :company_name, :company_cin, :company_logo, :registration_number, :date_of_registration, :landline_number, :company_website, :company_type, :inserted_by])
    |> validate_required([:countries_id, :company_type, :company_name])
    |> cast_assoc(:directors, required: false, with: &Directors.reg_step_one/2)
    |> update_change(:company_name, &String.trim/1)
    |> validate_length(:company_name, min: 3, max: 40)
    |> validate_format(:company_name, ~r/^[A-z0-9- ]*$/)
  end

  @doc false
  def changeset_reg_step_oneV3(company, attrs \\ :empty) do
    company
    |> cast(attrs, [:countries_id, :loading_fee, :company_name, :company_cin, :company_logo, :registration_number, :date_of_registration, :landline_number, :company_website, :company_type, :inserted_by])
    |> validate_required([:countries_id, :company_type])
    |> cast_assoc(:directors, required: false, with: &Directors.reg_step_oneV3/2)
    |> validate_inclusion(:loading_fee, ["STR", "LTD"])
  end

#  @doc false
#  def changeset_reg_step_four(company, attrs \\ :empty) do
#    company
#    |> cast(attrs, [:countries_id, :loading_fee, :company_name, :company_cin, :company_logo, :registration_number, :date_of_registration, :landline_number, :sector_id, :sector_details, :monthly_transfer, :company_website, :company_type, :inserted_by])
#    |> update_change(:company_name, &String.trim/1)
#    |> validate_length(:company_name, min: 3, max: 40)
#    |> validate_format(:company_name, ~r/^[A-z0-9- ]+$/)
#    |> validate_format(:registration_number, ~r/^[A-z0-9- ]+$/)
#  end

  @doc false
  def changeset_reg_step_four(company, attrs \\ :empty) do
    company
    |> cast(attrs, [:countries_id, :loading_fee, :company_name, :company_cin, :company_logo, :registration_number, :date_of_registration, :landline_number, :sector_id, :sector_details, :monthly_transfer, :company_website, :company_type, :inserted_by])
    |> validate_required([:sector_id, :sector_details, :monthly_transfer, :company_name, :landline_number, :date_of_registration])
    |> update_change(:company_name, &String.trim/1)
    |> validate_length(:company_name, min: 3, max: 40)
    |> validate_format(:company_name, ~r/^[A-z0-9- ]+$/)
    |> validate_format(:registration_number, ~r/^[A-z0-9- ]+$/)
    |> validate_length(:registration_number, min: 6, max: 25)
    |> validate_format(:landline_number, ~r/^(((0))[1-9][0-9]{9})/)
    |> validate_length(:landline_number, min: 11, max: 11)
    |> validate_format(:company_website, ~r/^((https?|ftp|smtp):\/\/)?(www.)?[a-z0-9]+(\.[a-z]{2,}){1,3}(#?\/?[a-zA-Z0-9#]+)*\/?(\?[a-zA-Z0-9-_]+=[a-zA-Z0-9-%]+&?)?$/)
    |> validate_length(:company_website, min: 6, max: 150)
    |> validate_length(:sector_details, min: 2, max: 100)
    |> validate_current_or_future_date(:date_of_registration)
  end

  @doc false
  def changeset_reg_step_four_limited_company(company, attrs \\ :empty) do
    company
    |> cast(attrs, [:countries_id, :loading_fee, :company_name, :company_cin, :company_logo, :registration_number, :date_of_registration, :landline_number, :sector_id, :sector_details, :monthly_transfer, :company_website, :company_type, :inserted_by])
    |> validate_required([:sector_id, :sector_details, :monthly_transfer, :company_name, :landline_number, :date_of_registration, :registration_number])
    |> update_change(:company_name, &String.trim/1)
    |> validate_length(:company_name, min: 3, max: 40)
    |> validate_format(:company_name, ~r/^[A-z0-9- ]+$/)
    |> validate_format(:registration_number, ~r/^[A-z0-9- ]+$/)
    |> validate_length(:registration_number, min: 6, max: 25)
    |> validate_format(:landline_number, ~r/^(((0))[1-9][0-9]{9})/)
    |> validate_length(:landline_number, min: 11, max: 11)
    |> validate_format(:company_website, ~r/^((https?|ftp|smtp):\/\/)?(www.)?[a-z0-9]+(\.[a-z]{2,}){1,3}(#?\/?[a-zA-Z0-9#]+)*\/?(\?[a-zA-Z0-9-_]+=[a-zA-Z0-9-%]+&?)?$/)
    |> validate_length(:company_website, min: 6, max: 150)
    |> validate_length(:sector_details, min: 2, max: 100)
    |> validate_current_or_future_date(:date_of_registration)
  end

  @doc false
  def changeset_empty(%Company{} = company, attrs) do
    company
    |> cast(attrs, [:countries_id, :company_name, :company_cin, :company_logo, :registration_number, :date_of_registration, :landline_number, :company_website, :company_type, :inserted_by])
    |> validate_required([:countries_id])
  end

  @doc false
  def changesetWebsite(%Company{} = company, attrs) do
    company
    |> cast(attrs, [:company_website])
  end

  @doc false
  def changesetGroup(%Company{} = company, attrs) do
    company
    |> cast(attrs, [:group_id])
  end

  def changesetregisteration(%Company{} = company, attrs) do
    company
    |> cast(attrs, [:registration_number])
    |> validate_required([:registration_number])
    |> validate_format(:registration_number, ~r/^[A-z0-9- ]+$/)
    |> validate_length(:registration_number, min: 6, max: 25)
  end

  def changesetContact(%Company{} = company, attrs) do
    company
    |> cast(attrs, [:landline_number])
    |> validate_required([:landline_number])
    |> validate_format(:landline_number, ~r/^(((0))[1-9][0-9]{9})/)
    |> validate_length(:landline_number, min: 11, max: 11)
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
      if field == :date_of_registration do
        changeset
        |> add_error(field, "Registeration date must in the past")
      else
        changeset
      end
    else
      changeset
    end
  end

end
