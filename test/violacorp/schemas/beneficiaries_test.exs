defmodule Violacorp.Schemas.BeneficiariesTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Beneficiaries
  @moduledoc false

  @valid_attrs %{
    company_id: 1210,
    first_name: "Simoin",
    last_name: "Morgan",
    nick_name: "Halibut",
    sort_code: "321245",
    account_number: "12458523",
    description: "Beneficiaries",
    type: "E",
    invoice_number: "121251221",
    status: "A",
    mode: "P",
    inserted_by: 1212,
  }
  @invalid_attrs %{}

  @doc"changeset"
  test "changeset with valid attributes" do
    changeset = Beneficiaries.changeset(%Beneficiaries{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Beneficiaries.changeset(%Beneficiaries{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "required first_name check" do
    changeset = Beneficiaries.changeset(%Beneficiaries{}, Map.delete(@valid_attrs, :first_name))
    assert !changeset.valid?
  end

  test "required sort_code check" do
    changeset = Beneficiaries.changeset(%Beneficiaries{}, Map.delete(@valid_attrs, :sort_code))
    assert !changeset.valid?
  end

  test "required account_number check" do
    changeset = Beneficiaries.changeset(%Beneficiaries{}, Map.delete(@valid_attrs, :account_number))
    assert !changeset.valid?
  end

  test "required type check" do
    changeset = Beneficiaries.changeset(%Beneficiaries{}, Map.delete(@valid_attrs, :type))
    assert !changeset.valid?
  end

  test "required status check" do
    changeset = Beneficiaries.changeset(%Beneficiaries{}, Map.delete(@valid_attrs, :status))
    assert !changeset.valid?
  end

  test "required inserted_by check" do
    changeset = Beneficiaries.changeset(%Beneficiaries{}, Map.delete(@valid_attrs, :inserted_by))
    assert !changeset.valid?
  end

  test "check if first_name has incorrect format" do
    attrs = %{@valid_attrs | first_name: "%%%%%^&"}
    changeset = Beneficiaries.changeset(%Beneficiaries{}, attrs)
    assert %{first_name: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if last_name has incorrect format" do
    attrs = %{@valid_attrs | last_name: "%%%%%^&"}
    changeset = Beneficiaries.changeset(%Beneficiaries{}, attrs)
    assert %{last_name: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if nick_name has incorrect format" do
    attrs = %{@valid_attrs | nick_name: "%%%%%^&"}
    changeset = Beneficiaries.changeset(%Beneficiaries{}, attrs)
    assert %{nick_name: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if account_number has incorrect format" do
    attrs = %{@valid_attrs | account_number: "%%%%%^&"}
    changeset = Beneficiaries.changeset(%Beneficiaries{}, attrs)
    assert %{account_number: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if description has incorrect format" do
    attrs = %{@valid_attrs | description: "%%%%%^&"}
    changeset = Beneficiaries.changeset(%Beneficiaries{}, attrs)
    assert %{description: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if sort_code has incorrect format" do
    attrs = %{@valid_attrs | sort_code: "%%%%%^&"}
    changeset = Beneficiaries.changeset(%Beneficiaries{}, attrs)
    assert %{sort_code: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if invoice_number has incorrect format" do
    attrs = %{@valid_attrs | invoice_number: "%%%%%^&"}
    changeset = Beneficiaries.changeset(%Beneficiaries{}, attrs)
    assert %{invoice_number: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if first_name maximum 150 characters" do
    attrs = %{
      @valid_attrs |
      first_name: "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcd"
    }
    changeset = Beneficiaries.changeset(%Beneficiaries{}, attrs)
    assert %{first_name: ["should be at most 150 character(s)"]} = errors_on(changeset)
  end

  test "check if last_name maximum 150 characters" do
    attrs = %{
      @valid_attrs |
      last_name: "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcd"
    }
    changeset = Beneficiaries.changeset(%Beneficiaries{}, attrs)
    assert %{last_name: ["should be at most 150 character(s)"]} = errors_on(changeset)
  end

  test "check if nick_name maximum 45 characters" do
    attrs = %{
      @valid_attrs |
      nick_name: "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghij"
    }
    changeset = Beneficiaries.changeset(%Beneficiaries{}, attrs)
    assert %{nick_name: ["should be at most 45 character(s)"]} = errors_on(changeset)
  end

  test "check if invoice_number maximum 45 characters" do
    attrs = %{@valid_attrs | invoice_number: "5454545452121212211515155151515151515151151515151"}
    changeset = Beneficiaries.changeset(%Beneficiaries{}, attrs)
    assert %{invoice_number: ["should be at most 45 character(s)"]} = errors_on(changeset)
  end

  test "check if account_number maximum length 15" do
    attrs = %{@valid_attrs | account_number: "133215122154878745545235"}
    changeset = Beneficiaries.changeset(%Beneficiaries{}, attrs)
    assert %{account_number: ["should be at most 15 character(s)"]} = errors_on(changeset)
  end

  test "check if sort_code maximum length 10" do
    attrs = %{@valid_attrs | sort_code: "133215122154878745545235"}
    changeset = Beneficiaries.changeset(%Beneficiaries{}, attrs)
    assert %{sort_code: ["should be at most 10 character(s)"]} = errors_on(changeset)
  end

  test "check if type accepts only E, I" do
    attrs = %{@valid_attrs | type: "R"}
    changeset = Beneficiaries.changeset(%Beneficiaries{}, attrs)
    assert %{type: ["Make Sure you use I or E"]} = errors_on(changeset)
  end

  test "check if status accepts only A, D, B" do
    attrs = %{@valid_attrs | status: "R"}
    changeset = Beneficiaries.changeset(%Beneficiaries{}, attrs)
    assert %{status: ["Make Sure you use A or D or B"]} = errors_on(changeset)
  end

  @doc"changesetBeneficiary"

  @valid_attrs_beneficiary %{
    invoice_number: "1222151",
    description: "description"
  }

  test "changeset with valid attributes beneficiary" do
    changeset = Beneficiaries.changesetBeneficiary(%Beneficiaries{}, @valid_attrs_beneficiary)
    assert changeset.valid?
  end

  test "check if invoice_number maximum length 45 beneficiary" do
    attrs = %{@valid_attrs_beneficiary | invoice_number: "1332151221548787455452314545451644545643651546465"}
    changeset = Beneficiaries.changesetBeneficiary(%Beneficiaries{}, attrs)
    assert %{invoice_number: ["should be at most 45 character(s)"]} = errors_on(changeset)
  end

  test "check if description has incorrect format beneficiary" do
    attrs = %{@valid_attrs_beneficiary | description: "%%%%%^&"}
    changeset = Beneficiaries.changesetBeneficiary(%Beneficiaries{}, attrs)
    assert %{description: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if invoice_number has incorrect format beneficiary" do
    attrs = %{@valid_attrs_beneficiary | invoice_number: "%%%%%^&"}
    changeset = Beneficiaries.changesetBeneficiary(%Beneficiaries{}, attrs)
    assert %{invoice_number: ["has invalid format"]} = errors_on(changeset)
  end

  @doc"changesetBeneficiaryMode"

  @valid_attrs_mode %{
    mode: "P"
  }

  test "changeset with valid attributes mode" do
    changeset = Beneficiaries.changesetBeneficiaryMode(%Beneficiaries{}, @valid_attrs_mode)
    assert changeset.valid?
  end

  test "changeset with invalid attributes mode" do
    changeset = Beneficiaries.changesetBeneficiaryMode(%Beneficiaries{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "required mode check mode" do
    changeset = Beneficiaries.changesetBeneficiaryMode(%Beneficiaries{}, Map.delete(@valid_attrs_mode, :mode))
    assert !changeset.valid?
  end

  @doc"updateStatus"

  @valid_attrs_status %{
    status: "A"
  }

  test "changeset with valid attributes update" do
    changeset = Beneficiaries.updateStatus(%Beneficiaries{}, @valid_attrs_status)
    assert changeset.valid?
  end

  test "changeset with invalid attributes update" do
    changeset = Beneficiaries.updateStatus(%Beneficiaries{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "required status check update" do
    changeset = Beneficiaries.updateStatus(%Beneficiaries{}, Map.delete(@valid_attrs_status, :status))
    assert !changeset.valid?
  end

  test "check if status accepts only A, D, B update" do
    attrs = %{@valid_attrs_status | status: "R"}
    changeset = Beneficiaries.updateStatus(%Beneficiaries{}, attrs)
    assert %{status: ["Make Sure you use A or D or B"]} = errors_on(changeset)
  end
end