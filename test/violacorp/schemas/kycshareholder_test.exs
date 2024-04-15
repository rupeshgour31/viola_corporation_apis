defmodule Violacorp.Schemas.KycshareholderTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Kycshareholder
  @moduledoc false

  @valid_attrs %{
    shareholder_id: 1232,
    documenttype_id: 2312,
    document_number: "fdweew9832",
    issue_date: ~D[2015-02-02],
    expiry_date: ~D[2022-02-02],
    file_type: "jpg",
    file_name: "sdfsdfsdf",
    file_location: "dfsdfsdfsd",
    content: "dsfsdfsdf",
    type: "A",
    status: "A",
    inserted_by: 4545
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Kycshareholder.changesetAddress(%Kycshareholder{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Kycshareholder.changesetAddress(%Kycshareholder{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "shareholder_id required check" do
    changeset = Kycshareholder.changesetAddress(%Kycshareholder{}, Map.delete(@valid_attrs, :shareholder_id))
    assert !changeset.valid?
  end

  test "documenttype_id required check" do
    changeset = Kycshareholder.changesetAddress(%Kycshareholder{}, Map.delete(@valid_attrs, :documenttype_id))
    assert !changeset.valid?
  end

  test "check if type format is correct " do
    attrs = %{@valid_attrs | type: "F"}
    changeset = Kycshareholder.changesetAddress(%Kycshareholder{}, attrs)
    assert %{type: ["is invalid"]} = errors_on(changeset)
  end

  @doc " changesetIdProof"


  @valid_attrs_ID %{
    shareholder_id: 1232,
    documenttype_id: 2312,
    document_number: "fdweew9832",
    issue_date: ~D[2015-02-02],
    expiry_date: ~D[2022-02-02],
    file_type: "jpg",
    file_name: "sdfsdfsdf",
    file_location: "dfsdfsdfsd",
    content: "dsfsdfsdf",
    type: "I",
    status: "A",
    inserted_by: 4545

  }

  test "changeset with valid attributes changesetIdProof" do
    changeset = Kycshareholder.changesetIdProof(%Kycshareholder{}, @valid_attrs_ID)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changesetIdProof" do
    changeset = Kycshareholder.changesetIdProof(%Kycshareholder{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "issue_date required check changesetIdProof" do
    changeset = Kycshareholder.changesetIdProof(%Kycshareholder{}, Map.delete(@valid_attrs_ID, :issue_date))
    assert !changeset.valid?
  end

  test "expiry_date required check changesetIdProof" do
    changeset = Kycshareholder.changesetIdProof(%Kycshareholder{}, Map.delete(@valid_attrs_ID, :expiry_date))
    assert !changeset.valid?
  end

  test "check if type format is correct changesetIdProof" do
    attrs = %{@valid_attrs_ID | type: "F"}
    changeset = Kycshareholder.changesetAddress(%Kycshareholder{}, attrs)
    assert %{type: ["is invalid"]} = errors_on(changeset)
  end

  test "check if document_number format is correct changesetIdProof" do
    attrs = %{@valid_attrs_ID | document_number: "####23edrft"}
    changeset = Kycshareholder.changesetIdProof(%Kycshareholder{}, attrs)
    assert %{document_number: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if document_number length max 45 changesetIdProof" do
    attrs = %{@valid_attrs | document_number: "ssdsdsdsdsdssdsdsdsdsdssdsdsdsdsdssdsdsdsdsdssdsdsdsdsdssdsdsdsdsd"}
    changeset = Kycshareholder.changesetIdProof(%Kycshareholder{}, attrs)
    assert %{document_number: ["should be at most 45 character(s)"]} = errors_on(changeset)
  end

@doc " changesetCompany"
  @valid_attrs_company %{
    shareholder_id: 1232,
    documenttype_id: 2312,
    document_number: "fdweew9832",
    issue_date: ~D[2015-02-02],
    expiry_date: ~D[2022-02-02],
    file_type: "jpg",
    file_name: "sdfsdfsdf",
    file_location: "dfsdfsdfsd",
    content: "dsfsdfsdf",
    type: "C",
    status: "A",
    inserted_by: 4545
  }

  test "changeset with valid attributes changesetCompany" do
    changeset = Kycshareholder.changesetCompany(%Kycshareholder{}, @valid_attrs_company)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changesetCompany" do
    changeset = Kycshareholder.changesetCompany(%Kycshareholder{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "shareholder_id required check changesetCompany" do
    changeset = Kycshareholder.changesetCompany(%Kycshareholder{}, Map.delete(@valid_attrs_company, :shareholder_id))
    assert !changeset.valid?
  end

  test "documenttype_id required check changesetCompany" do
    changeset = Kycshareholder.changesetCompany(%Kycshareholder{}, Map.delete(@valid_attrs_company, :documenttype_id))
    assert !changeset.valid?
  end

  test "check if type format is correct changesetCompany" do
    attrs = %{@valid_attrs_company | type: "F"}
    changeset = Kycshareholder.changesetCompany(%Kycshareholder{}, attrs)
    assert %{type: ["is invalid"]} = errors_on(changeset)
  end

  test "check if document_number format is correct changesetCompany" do
    attrs = %{@valid_attrs_company | document_number: "####23edrft"}
    changeset = Kycshareholder.changesetCompany(%Kycshareholder{}, attrs)
    assert %{document_number: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if document_number length max 45 changesetCompany" do
    attrs = %{@valid_attrs_company | document_number: "ssdsdsdsdsdssdsdsdsdsdssdsdsdsdsdssdsdsdsdsdssdsdsdsdsdssdsdsdsdsd"}
    changeset = Kycshareholder.changesetCompany(%Kycshareholder{}, attrs)
    assert %{document_number: ["should be at most 45 character(s)"]} = errors_on(changeset)
  end






















end