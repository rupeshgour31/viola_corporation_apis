defmodule Violacorp.Schemas.Employee do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Employee

  @moduledoc "Employee Table Model"

  schema "employee" do
    field :group_id, :integer
    field :group_member_id, :integer
    field :title, :string
    field :employeeids, :string
    field :position, :string
    field :first_name, :string
    field :middle_name, :string
    field :last_name, :string
    field :date_of_birth, :date
    field :gender, :string
    field :verify_kyc, :string
    field :profile_picture, :string
    field :is_manager, :string
    field :no_of_cards, :integer
    field :director_id, :integer
    field :status, :string
    field :terms_accepted, :string
    field :terms_accepted_at, :utc_datetime
    field :inserted_by, :integer
    has_many :commanall, Violacorp.Schemas.Commanall
    has_many :employeecards, Violacorp.Schemas.Employeecards
    belongs_to :departments, Violacorp.Schemas.Departments
    belongs_to :company, Violacorp.Schemas.Company
    has_many :requestmoney, Violacorp.Schemas.Requestmoney
    has_many :requestcard, Violacorp.Schemas.Requestcard
    has_many :expense, Violacorp.Schemas.Expense
    has_many :transactions, Violacorp.Schemas.Transactions
    timestamps()
  end

  @doc false
  def changeset(%Employee{} = employee, attrs) do
    employee
    |> cast(attrs, [:company_id, :director_id, :departments_id, :employeeids, :title, :position, :first_name, :middle_name, :last_name, :date_of_birth, :gender, :profile_picture, :status, :is_manager, :inserted_by])
    |> validate_required([:title, :first_name, :last_name, :gender])
    |> foreign_key_constraint(:departments, name: :fk_employee_departments1)
    |> update_change(:first_name, &String.trim/1)
    |> update_change(:last_name, &String.trim/1)
    |> update_change(:first_name, &String.capitalize/1)
    |> update_change(:last_name, &String.capitalize/1)
    |> update_change(:position, &String.capitalize/1)
    |> validate_format(:first_name, ~r/[A-z-]+$/)
    |> validate_length(:first_name, max: 40)
    |> validate_format(:middle_name, ~r/[A-z-]+$/, message: "Make sure you only use A-z")
    |> validate_length(:middle_name, min: 1, max: 40)
    |> validate_format(:last_name, ~r/[A-z]+$/, message: "Make sure you only use A-z")
    |> validate_length(:last_name, max: 40)
    |> validate_current_or_future_date(:date_of_birth)
  end

  @doc false
  def changesetStatus(%Employee{} = employee, attrs) do
    employee
    |> cast(attrs, [:status])
  end

  def updateEmployeeCardschangeset(%Employee{} = employee, attrs) do
    employee
    |> cast(attrs, [:no_of_cards])
  end

  def departmentToNull(%Employee{} = employee, attrs) do
    employee
    |> cast(attrs, [:departments_id])
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
    comparison = Date.compare(date, Date.add(today, -6570))
    if comparison == :lt || comparison == :eq do
      changeset
    else
      changeset
      |> add_error(field, "You must be atleast 18 years old")
    end
  end

  def changesetGroup(%Employee{} = employee, attrs) do
    employee
    |> cast(attrs, [:group_id, :group_member_id])
  end

  @doc false
  def updateTerms(party, attrs) do
    party
    |> cast(attrs, [:terms_accepted, :status, :terms_accepted_at])
    |> validate_required([:terms_accepted])
    |> validate_inclusion(:terms_accepted, ["Yes", "No"])
  end

  def changesetDirector(%Employee{} = employee, attrs) do
    employee
    |> cast(attrs, [:director_id])
  end

  def update_gender(employee, attrs \\ :empty) do
    employee
    |> cast(attrs, [:gender])
    |> validate_required([:gender])
    |> validate_inclusion(:gender, ["M", "F"])
  end

  def changesetVerifyKyc(%Employee{} = employee, attrs) do
    employee
    |> cast(attrs, [:verify_kyc])
  end


  def changesetDob(%Employee{} = employee, attrs)do
    employee
    |> cast(attrs, [:date_of_birth])
    |> validate_required([:date_of_birth])
    |> validate_current_or_future_date(:date_of_birth)
  end

end
