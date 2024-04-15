defmodule Violacorp.Schemas.KycdirectorsTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Kycdirectors
  @moduledoc false

  @valid_attrs %{
    directors_id: 1232,
    documenttype_id: 332,
    document_number: "1212221j",
    expiry_date: ~D[2022-02-02],
    issue_date: ~D[2015-02-02],
    file_type: "pfm",
    file_name: "dwdwdasd",
    file_location: "location",
    file_location_two: "location",
    status: "A",
    type: "I",
    country: nil,
    fourstop_response: "fdfsdfsdfsdf",
    reference_id: nil,
    refered_id: nil,
    inserted_by: 4545,
    reason: "ffgfdgfdgdf",
    address_documenttype_id: 34
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Kycdirectors.changeset(%Kycdirectors{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Kycdirectors.changeset(%Kycdirectors{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "documenttype_id required check" do
    changeset = Kycdirectors.changeset(%Kycdirectors{}, Map.delete(@valid_attrs, :documenttype_id))
    assert !changeset.valid?
  end

  test "document_number required check" do
    changeset = Kycdirectors.changeset(%Kycdirectors{}, Map.delete(@valid_attrs, :document_number))
    assert !changeset.valid?
  end


  test "check if document_number correct format" do
    attrs = %{@valid_attrs | document_number: "----=+8**"}
    changeset = Kycdirectors.changeset(%Kycdirectors{}, attrs)
    assert %{document_number: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if document_number correct length" do
    attrs = %{@valid_attrs | document_number: "dasdsadadasdsadadasdsadadasdsadadasdsadadasdsada"}
    changeset = Kycdirectors.changeset(%Kycdirectors{}, attrs)
    assert %{document_number: ["should be at most 45 character(s)"]} = errors_on(changeset)
  end

@doc"changeset_addess "




  test "changeset with valid attributes changeset_addess" do
    changeset = Kycdirectors.changeset_addess(%Kycdirectors{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changeset_addess" do
    changeset = Kycdirectors.changeset_addess(%Kycdirectors{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "documenttype_id required changeset_addess" do
    changeset = Kycdirectors.changeset_addess(%Kycdirectors{}, Map.delete(@valid_attrs, :documenttype_id))
    assert !changeset.valid?
  end

  test "check if document_number correct format changeset_addess" do
    attrs = %{@valid_attrs | document_number: "----=+8**"}
    changeset = Kycdirectors.changeset_addess(%Kycdirectors{}, attrs)
    assert %{document_number: ["has invalid format"]} = errors_on(changeset)
  end


@doc " changeset_director_kyc"





  test "changeset with valid attributes changeset_addess changeset_director_kyc" do
    changeset = Kycdirectors.changeset_director_kyc(%Kycdirectors{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changeset_addess changeset_director_kyc" do
    changeset = Kycdirectors.changeset_director_kyc(%Kycdirectors{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "address_documenttype_id required changeset_addess changeset_director_kyc" do
    changeset = Kycdirectors.changeset_director_kyc(%Kycdirectors{}, Map.delete(@valid_attrs, :address_documenttype_id))
    assert !changeset.valid?
  end

  test "check if document_number correct format changeset_addess changeset_director_kyc" do
    attrs = %{@valid_attrs | document_number: "----=+8**"}
    changeset = Kycdirectors.changeset_director_kyc(%Kycdirectors{}, attrs)
    assert %{document_number: ["has invalid format"]} = errors_on(changeset)
  end


@doc" update_by_gbg"

  test "changeset with valid attributes changeset_addess changeset_director_kyc update_by_gbg" do
    changeset = Kycdirectors.update_by_gbg(%Kycdirectors{}, @valid_attrs)
    assert changeset.valid?
  end



  @doc " changeset_upload_kyc "



  test "changeset with valid attributes changeset_addess changeset_upload_kyc" do
    changeset = Kycdirectors.changeset_upload_kyc(%Kycdirectors{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changeset_addess changeset_upload_kyc" do
    changeset = Kycdirectors.changeset_upload_kyc(%Kycdirectors{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "directors_id required changeset_addess changeset_upload_kyc" do
    changeset = Kycdirectors.changeset_upload_kyc(%Kycdirectors{}, Map.delete(@valid_attrs, :directors_id))
    assert !changeset.valid?
  end

  test "documenttype_id required changeset_addess changeset_upload_kyc" do
    changeset = Kycdirectors.changeset_upload_kyc(%Kycdirectors{}, Map.delete(@valid_attrs, :documenttype_id))
    assert !changeset.valid?
  end

  test "file_location required changeset_addess changeset_upload_kyc" do
    changeset = Kycdirectors.changeset_upload_kyc(%Kycdirectors{}, Map.delete(@valid_attrs, :file_location))
    assert !changeset.valid?
  end

  @doc "changesetUploadIdProof "

  test "changeset with valid attributes changeset_addess changesetUploadIdProof" do
    changeset = Kycdirectors.changesetUploadIdProof(%Kycdirectors{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changeset_addess changesetUploadIdProof" do
    changeset = Kycdirectors.changesetUploadIdProof(%Kycdirectors{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "directors_id required changeset_addess changesetUploadIdProof" do
    changeset = Kycdirectors.changesetUploadIdProof(%Kycdirectors{}, Map.delete(@valid_attrs, :directors_id))
    assert !changeset.valid?
  end

  test "documenttype_id required changeset_addess changesetUploadIdProof" do
    changeset = Kycdirectors.changesetUploadIdProof(%Kycdirectors{}, Map.delete(@valid_attrs, :documenttype_id))
    assert !changeset.valid?
  end

  test "file_location required changeset_addess changesetUploadIdProof" do
    changeset = Kycdirectors.changesetUploadIdProof(%Kycdirectors{}, Map.delete(@valid_attrs, :file_location))
    assert !changeset.valid?
  end

  test "document_number required changeset_addess changesetUploadIdProof" do
    changeset = Kycdirectors.changesetUploadIdProof(%Kycdirectors{}, Map.delete(@valid_attrs, :document_number))
    assert !changeset.valid?
  end


  test "issue_date required changeset_addess changesetUploadIdProof" do
    changeset = Kycdirectors.changesetUploadIdProof(%Kycdirectors{}, Map.delete(@valid_attrs, :issue_date))
    assert !changeset.valid?
  end

  test "expiry_date required changeset_addess changesetUploadIdProof" do
    changeset = Kycdirectors.changesetUploadIdProof(%Kycdirectors{}, Map.delete(@valid_attrs, :expiry_date))
    assert !changeset.valid?
  end

  test "check if document_number correct format changesetUploadIdProof" do
    attrs = %{@valid_attrs | document_number: "----=+8**"}
    changeset = Kycdirectors.changesetUploadIdProof(%Kycdirectors{}, attrs)
    assert %{document_number: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if document_number correct length changesetUploadIdProof" do
    attrs = %{@valid_attrs | document_number: "dasdsadadasdsadadasdsadadasdsadadasdsadadasdsada"}
    changeset = Kycdirectors.changesetUploadIdProof(%Kycdirectors{}, attrs)
    assert %{document_number: ["should be at most 20 character(s)"]} = errors_on(changeset)
  end


  @doc " changeset_upload__drector_kyc"


  test "changeset with valid attributes changeset_addess changeset_upload__drector_kyc" do
    changeset = Kycdirectors.changeset_upload__drector_kyc(%Kycdirectors{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes changeset_addess changeset_upload__drector_kyc" do
    changeset = Kycdirectors.changeset_upload__drector_kyc(%Kycdirectors{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "directors_id required changeset_addess changeset_upload__drector_kyc" do
    changeset = Kycdirectors.changeset_upload__drector_kyc(%Kycdirectors{}, Map.delete(@valid_attrs, :directors_id))
    assert !changeset.valid?
  end


  test "document_number required changeset_addess changeset_upload__drector_kyc" do
    changeset = Kycdirectors.changeset_upload__drector_kyc(%Kycdirectors{}, Map.delete(@valid_attrs, :document_number))
    assert !changeset.valid?
  end

  test "file_location required changeset_addess changeset_upload__drector_kyc" do
    changeset = Kycdirectors.changeset_upload__drector_kyc(%Kycdirectors{}, Map.delete(@valid_attrs, :file_location))
    assert !changeset.valid?
  end

@doc "updateGBGResponse"

  test "changeset with valid attributes  updateGBGResponse" do
    changeset = Kycdirectors.updateGBGResponse(%Kycdirectors{}, @valid_attrs)
    assert changeset.valid?
  end

  @doc "kycChangeset"


  test "changeset with valid attributes kycChangeset" do
    changeset = Kycdirectors.kycChangeset(%Kycdirectors{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes kycChangeset" do
    changeset = Kycdirectors.kycChangeset(%Kycdirectors{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "reason required kycChangeset" do
    changeset = Kycdirectors.kycChangeset(%Kycdirectors{}, Map.delete(@valid_attrs, :reason))
    assert !changeset.valid?
  end

  test "check if reason correct length kycChangeset" do
    attrs = %{@valid_attrs | reason: "dasdsadadasdsadadasdsadadasdsadadasdsadadasdsadadasdsadadasdsadadasdsadadasdsadadasdsadadasdsadadasdsadadasdsadadasdsadadasdsadadasdsadadasdsadadasdsadadasdsadadasdsadadasdsadadasdsadadasdsadadasdsadadasdsadadasdsadssssssssssssssssssssssssssadasdsadadasdsadadasdsada"}
    changeset = Kycdirectors.kycChangeset(%Kycdirectors{}, attrs)
    assert %{reason: ["should be at most 255 character(s)"]} = errors_on(changeset)
  end

  @doc "kycStatusChangeset"

  test "changeset with valid attributes kycStatusChangeset" do
    changeset = Kycdirectors.kycStatusChangeset(%Kycdirectors{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes kycStatusChangeset" do
    changeset = Kycdirectors.kycStatusChangeset(%Kycdirectors{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "status required kycStatusChangeset" do
    changeset = Kycdirectors.kycStatusChangeset(%Kycdirectors{}, Map.delete(@valid_attrs, :status))
    assert !changeset.valid?
  end
  test "check if status correct value kycStatusChangeset" do
    attrs = %{@valid_attrs | status: "F"}
    changeset = Kycdirectors.kycStatusChangeset(%Kycdirectors{}, attrs)
    assert %{status: ["is invalid"]} = errors_on(changeset)
  end












































end