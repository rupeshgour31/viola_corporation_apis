defmodule Violacorp.Schemas.KycdocumentsTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Kycdocuments
  @moduledoc false

  @valid_attrs %{
    documenttype_id: 1232,
    expiry_date: ~D[2022-02-05],
    document_number: "fgfd877",
    commanall_id: 1212,
    issue_date: ~D[2005-02-05],
    file_type: "jpg",
    file_name: "gdfgfdgfdg",
    file_location: "dgdgdfgdfgdfg",
    file_location_two: nil,
    status: "A",
    country: "nil",
    type: "I",
    content: "dsdsadasdasd",
    fourstop_response: "dsadasdasd",
    reason: "dfsdfsdfsdf",
    refered_id: 1232,
    reference_id: nil,
    director_id: 342,
    inserted_by: 2311,
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Kycdocuments.changeset(%Kycdocuments{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Kycdocuments.changeset(%Kycdocuments{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "documenttype_id required check" do
    changeset = Kycdocuments.changeset(%Kycdocuments{}, Map.delete(@valid_attrs, :documenttype_id))
    assert !changeset.valid?
  end

  test "document_number required check" do
    changeset = Kycdocuments.changeset(%Kycdocuments{}, Map.delete(@valid_attrs, :document_number))
    assert !changeset.valid?
  end

  test "expiry_date required check" do
    changeset = Kycdocuments.changeset(%Kycdocuments{}, Map.delete(@valid_attrs, :expiry_date))
    assert !changeset.valid?
  end

  test "check if document_number max 45 numbers" do
    attrs = %{@valid_attrs | document_number: "dsdsvdsvdvdsdsvdsvdvdsdsvdsvdvdsdsvdsvdvdsdsvdsvdv"}
    changeset = Kycdocuments.changeset(%Kycdocuments{}, attrs)
    assert %{document_number: ["should be at most 45 character(s)"]} = errors_on(changeset)
  end

  test "check if document_number correct format" do
    attrs = %{@valid_attrs | document_number: "£$%^__++=.'#;,^!"}
    changeset = Kycdocuments.changeset(%Kycdocuments{}, attrs)
    assert %{document_number: ["has invalid format"]} = errors_on(changeset)
  end

@doc" changeset_upload_employee_kyc"

  test "changeset with valid attributes changeset_upload_employee_kyc" do
    changeset = Kycdocuments.changeset_upload_employee_kyc(%Kycdocuments{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changeset_upload_employee_kyc" do
    changeset = Kycdocuments.changeset_upload_employee_kyc(%Kycdocuments{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "commanall_id required check changeset_upload_employee_kyc" do
    changeset = Kycdocuments.changeset_upload_employee_kyc(%Kycdocuments{}, Map.delete(@valid_attrs, :commanall_id))
    assert !changeset.valid?
  end

  test "documenttype_id required check changeset_upload_employee_kyc" do
    changeset = Kycdocuments.changeset_upload_employee_kyc(%Kycdocuments{}, Map.delete(@valid_attrs, :documenttype_id))
    assert !changeset.valid?
  end

  test "document_number required check changeset_upload_employee_kyc" do
    changeset = Kycdocuments.changeset_upload_employee_kyc(%Kycdocuments{}, Map.delete(@valid_attrs, :document_number))
    assert !changeset.valid?
  end

  test "check if document_number max 45 numbers changeset_upload_employee_kyc" do
    attrs = %{@valid_attrs | document_number: "dsdsvdsvdvdsdsvdsvdvdsdsvdsvdvdsdsvdsvdvdsdsvdsvdv"}
    changeset = Kycdocuments.changeset_upload_employee_kyc(%Kycdocuments{}, attrs)
    assert %{document_number: ["should be at most 45 character(s)"]} = errors_on(changeset)
  end

  test "check if document_number correct format changeset_upload_employee_kyc" do
    attrs = %{@valid_attrs | document_number: "£$%^__++=.'#;,^!"}
    changeset = Kycdocuments.changeset_upload_employee_kyc(%Kycdocuments{}, attrs)
    assert %{document_number: ["has invalid format"]} = errors_on(changeset)
  end

@doc "changeset_upload_kyb"

  test "changeset with valid attributes changeset_upload_kyb" do
    changeset = Kycdocuments.changeset_upload_kyb(%Kycdocuments{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changeset_upload_kyb" do
    changeset = Kycdocuments.changeset_upload_kyb(%Kycdocuments{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "documenttype_id required check changeset_upload_kyb" do
    changeset = Kycdocuments.changeset_upload_kyb(%Kycdocuments{}, Map.delete(@valid_attrs, :documenttype_id))
    assert !changeset.valid?
  end

  test "file_location required check changeset_upload_kyb" do
    changeset = Kycdocuments.changeset_upload_kyb(%Kycdocuments{}, Map.delete(@valid_attrs, :file_location))
    assert !changeset.valid?
  end

  test "commanall_id required check changeset_upload_kyb" do
    changeset = Kycdocuments.changeset_upload_kyb(%Kycdocuments{}, Map.delete(@valid_attrs, :commanall_id))
    assert !changeset.valid?
  end

  @doc "changesetAddress"


  test "changeset with valid attributes changesetAddress" do
    changeset = Kycdocuments.changesetAddress(%Kycdocuments{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changesetAddress" do
    changeset = Kycdocuments.changesetAddress(%Kycdocuments{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "documenttype_id required check changesetAddress" do
    changeset = Kycdocuments.changesetAddress(%Kycdocuments{}, Map.delete(@valid_attrs, :documenttype_id))
    assert !changeset.valid?
  end

  test "file_type required check changesetAddress" do
    changeset = Kycdocuments.changesetAddress(%Kycdocuments{}, Map.delete(@valid_attrs, :file_type))
    assert !changeset.valid?
  end

  test "content required check changesetAddress" do
    changeset = Kycdocuments.changesetAddress(%Kycdocuments{}, Map.delete(@valid_attrs, :content))
    assert !changeset.valid?
  end

  test "check if document_number correct format changesetAddress" do
    attrs = %{@valid_attrs | document_number: "£$%^__++=.'#;,^!"}
    changeset = Kycdocuments.changesetAddress(%Kycdocuments{}, attrs)
    assert %{document_number: ["has invalid format"]} = errors_on(changeset)
  end

@doc "changesetIDProof"



  test "changeset with valid attributes changesetIDProof" do
    changeset = Kycdocuments.changesetIDProof(%Kycdocuments{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changesetIDProof" do
    changeset = Kycdocuments.changesetIDProof(%Kycdocuments{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "documenttype_id required check changesetIDProof" do
    changeset = Kycdocuments.changesetIDProof(%Kycdocuments{}, Map.delete(@valid_attrs, :documenttype_id))
    assert !changeset.valid?
  end

  test "document_number required check changesetIDProof" do
    changeset = Kycdocuments.changesetIDProof(%Kycdocuments{}, Map.delete(@valid_attrs, :document_number))
    assert !changeset.valid?
  end

  test "issue_date required check changesetIDProof" do
    changeset = Kycdocuments.changesetIDProof(%Kycdocuments{}, Map.delete(@valid_attrs, :issue_date))
    assert !changeset.valid?
  end


  test "expiry_date required check changesetIDProof" do
    changeset = Kycdocuments.changesetIDProof(%Kycdocuments{}, Map.delete(@valid_attrs, :expiry_date))
    assert !changeset.valid?
  end

  @doc "changesetAddressProof"
    #[:commanall_id, :documenttype_id, :document_number, :expiry_date,
  #:issue_date, :file_type, :file_name, :file_location, :status, :type, :content, :inserted_by])

  @valid_attrs_changesetAddressProof %{
    documenttype_id: 1232,
    expiry_date: ~D[2022-02-05],
    document_number: "fgfd877",
    commanall_id: 1212,
    issue_date: ~D[2005-02-05],
    file_type: "jpg",
    file_name: "gdfgfdgfdg",
    file_location: "dgdgdfgdfgdfg",
    status: "A",
    type: "A",
    content: "dsdsadasdasd",
    inserted_by: 2311
  }

  test "changeset with valid attributes changesetAddressProof" do
    changeset = Kycdocuments.changesetAddressProof(%Kycdocuments{}, @valid_attrs_changesetAddressProof)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changesetAddressProof" do
    changeset = Kycdocuments.changesetAddressProof(%Kycdocuments{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "documenttype_id required check changesetAddressProof" do
    changeset = Kycdocuments.changesetAddressProof(%Kycdocuments{}, Map.delete(@valid_attrs_changesetAddressProof, :documenttype_id))
    assert !changeset.valid?
  end

  test "check if document_number correct format changesetAddressProof" do
    attrs = %{@valid_attrs_changesetAddressProof | document_number: "£$%^__++=.'#;,^!"}
    changeset = Kycdocuments.changesetAddressProof(%Kycdocuments{}, attrs)
    assert %{document_number: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if type has valid value changesetAddressProof" do
    attrs = %{@valid_attrs_changesetAddressProof | type: "G"}
    changeset = Kycdocuments.changesetAddressProof(%Kycdocuments{}, attrs)
    assert %{type: ["is invalid"]} = errors_on(changeset)
  end

  @doc "update_status"


  test "changeset with valid attributes update_status" do
    changeset = Kycdocuments.update_status(%Kycdocuments{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes update_status" do
    changeset = Kycdocuments.update_status(%Kycdocuments{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "status required check update_status" do
    changeset = Kycdocuments.update_status(%Kycdocuments{}, Map.delete(@valid_attrs, :status))
    assert !changeset.valid?
  end

  @doc " update_status_changeset"

  test "changeset with valid attributes update_status_changeset" do
    changeset = Kycdocuments.update_status_changeset(%Kycdocuments{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes update_status_changeset" do
    changeset = Kycdocuments.update_status_changeset(%Kycdocuments{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "status required check update_status_changeset" do
    changeset = Kycdocuments.update_status_changeset(%Kycdocuments{}, Map.delete(@valid_attrs, :status))
    assert !changeset.valid?
  end

  @doc "updateGBGResponse"

  test "changeset with valid attributes updateGBGResponse" do
    changeset = Kycdocuments.updateGBGResponse(%Kycdocuments{}, @valid_attrs)
    assert changeset.valid?
  end

  @doc "changesetKycOverride"

  test "changeset with valid attributes changesetKycOverride" do
    changeset = Kycdocuments.changesetKycOverride(%Kycdocuments{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changesetKycOverride" do
    changeset = Kycdocuments.changesetKycOverride(%Kycdocuments{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "reason required check changesetKycOverride" do
    changeset = Kycdocuments.changesetKycOverride(%Kycdocuments{}, Map.delete(@valid_attrs, :reason))
    assert !changeset.valid?
  end













end