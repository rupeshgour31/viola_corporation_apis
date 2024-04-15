#defmodule Violacorp.Schemas.CompanykycTest do
#
#  use Violacorp.DataCase
#  alias Violacorp.Schemas.Companykyc
#  @moduledoc false

#  @valid_attrs %{
#    company_id: 1112,
#    company_countries_id: 12,
#    document_type: "A",
#    document_number: "fdsfsdfsdfd",
#    expiry_date: "2022/12",
#    inserted_by: 4545,
#  }
#  @invalid_attrs %{}

#  test "changeset with valid attributes" do
#    changeset = Companykyc.changeset(%Companykyc{}, @valid_attrs)
#    assert changeset.valid?
#  end
#
#  test "changeset with invalid attributes" do
#    changeset = Companykyc.changeset(%Companykyc{}, @invalid_attrs)
#    refute changeset.valid?
#  end

#  test "company_id required check" do
#    changeset = Companykyc.changeset(%Companykyc{}, Map.delete(@valid_attrs, :company_id))
#    assert !changeset.valid?
#  end
#  test "company_countries_id required check" do
#    changeset = Companykyc.changeset(%Companykyc{}, Map.delete(@valid_attrs, :company_countries_id))
#    assert !changeset.valid?
#  end
#  test "document_type required check" do
#    changeset = Companykyc.changeset(%Companykyc{}, Map.delete(@valid_attrs, :document_type))
#    assert !changeset.valid?
#  end
#  test "document_number required check" do
#    changeset = Companykyc.changeset(%Companykyc{}, Map.delete(@valid_attrs, :document_number))
#    assert !changeset.valid?
#  end
#  test "expiry_date required check" do
#    changeset = Companykyc.changeset(%Companykyc{}, Map.delete(@valid_attrs, :expiry_date))
#    assert !changeset.valid?
#  end
#  test "inserted_by required check" do
#    changeset = Companykyc.changeset(%Companykyc{}, Map.delete(@valid_attrs, :inserted_by))
#    assert !changeset.valid?
#  end


#end
