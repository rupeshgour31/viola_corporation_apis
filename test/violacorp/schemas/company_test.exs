defmodule Violacorp.Schemas.CompanyTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Company
  @moduledoc false

  @valid_attrs %{
    countries_id: 53,
    loading_fee: "W",
    company_name: "Company",
    company_cin: "cin",
    company_logo: "logo",
    registration_number: "A00000000000#", #ISSUE HERE WITH REGEX
    date_of_registration: ~D[2018-05-05],
    landline_number: "02920522154",
    company_website: "www.abc.co.uk",
    company_type: "LTD",
    inserted_by: 1212
  }
  @invalid_attrs %{}
  @doc"changeset"
  test "changeset with valid attributes" do
    changeset = Company.changeset(%Company{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Company.changeset(%Company{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "countries_id required check" do
    changeset = Company.changeset(%Company{}, Map.delete(@valid_attrs, :countries_id))
    assert !changeset.valid?
  end

  test "company_name required check" do
    changeset = Company.changeset(%Company{}, Map.delete(@valid_attrs, :company_name))
    assert !changeset.valid?
  end

  test "company_type required check" do
    changeset = Company.changeset(%Company{}, Map.delete(@valid_attrs, :company_type))
    assert !changeset.valid?
  end

  test "check if loading_fee accepts only W, N" do
    attrs = %{@valid_attrs | loading_fee: "R"}
    changeset = Company.changeset(%Company{}, attrs)
    assert %{loading_fee: ["is invalid"]} = errors_on(changeset)
  end

  test "check if company_name maximum 40 characters" do
    attrs = %{@valid_attrs | company_name: "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabc"}
    changeset = Company.changeset(%Company{}, attrs)
    assert %{company_name: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

  test "check if company_name minimum 3 characters" do
    attrs = %{@valid_attrs | company_name: "av"}
    changeset = Company.changeset(%Company{}, attrs)
    assert %{company_name: ["should be at least 3 character(s)"]} = errors_on(changeset)
  end

  test "check if company_name accepts only alpha characters" do
    attrs = %{@valid_attrs | company_name: "%%%%%^&"}
    changeset = Company.changeset(%Company{}, attrs)
    assert %{company_name: ["has invalid format"]} = errors_on(changeset)
  end

  ##################################
  #####REGEX ERROR ON FOLLOWING TEST

  test "check if registration_number accepts only alpha characters" do
    attrs = %{@valid_attrs | registration_number: "AAAAAAAAAAAA"}
    changeset = Company.changeset(%Company{}, attrs)
    assert %{registration_number: ["has invalid format"]} = errors_on(changeset)
  end

  ###################################
  ###################################

  @doc" changeset_reg_step_one"

  @valid_attrs_step_one %{

    countries_id: 3,
    loading_fee: "Y",
    company_name: "New COmpany Ltd",
    company_cid: "CID",
    company_logo: "LGOG",
    registration_number: "AAAAAAAAAAA",
    date_of_registration: ~D[2014-05-05],
    landline_number: "02952124578",
    company_website: "www.www.com",
    company_type: "LTD",
    inserted_by: 1221
  }

  test "changeset with valid attributes for step one" do
    changeset = Company.changeset_reg_step_one(%Company{}, @valid_attrs_step_one)
    assert changeset.valid?
  end

  test "changeset with invalid attributes for step one" do
    changeset = Company.changeset_reg_step_one(%Company{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "countries_id required check for step one" do
    changeset = Company.changeset_reg_step_one(%Company{}, Map.delete(@valid_attrs_step_one, :countries_id))
    assert !changeset.valid?
  end

  test "company_type required check for step one" do
    changeset = Company.changeset_reg_step_one(%Company{}, Map.delete(@valid_attrs_step_one, :company_type))
    assert !changeset.valid?
  end

  test "company_name required check for step one" do
    changeset = Company.changeset_reg_step_one(%Company{}, Map.delete(@valid_attrs_step_one, :company_name))
    assert !changeset.valid?
  end

  test "check if company_name accepts only alpha characters for step one" do
    attrs = %{@valid_attrs | company_name: "%%%%%^&"}
    changeset = Company.changeset_reg_step_one(%Company{}, attrs)
    assert %{company_name: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if company_name maximum 40 characters for step one" do
    attrs = %{@valid_attrs | company_name: "efghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefgh"}
    changeset = Company.changeset_reg_step_one(%Company{}, attrs)
    assert %{company_name: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

  test "check if company_name minimum 3 characters for step one" do
    attrs = %{@valid_attrs | company_name: "av"}
    changeset = Company.changeset_reg_step_one(%Company{}, attrs)
    assert %{company_name: ["should be at least 3 character(s)"]} = errors_on(changeset)
  end

  @doc"changeset_reg_step_oneV3 "

  @valid_attrs_step_onev3 %{
    countries_id: 322,
    loading_fee: "LTD", ########Validation Error#################
    company_name: "Company Lyd Ltd",
    company_cid: "CID",
    company_logo: "LOGO",
    registration_number: "aaaaaaaaaaaaaaaaa",
    date_of_registration: ~D[2012-05-05],
    landline_number: "02920522658",
    company_website: "website.com",
    company_type: "LTD",
    inserted_by: 1212
  }

  test "changeset with valid attributes for step one v3" do
    changeset = Company.changeset_reg_step_oneV3(%Company{}, @valid_attrs_step_onev3)
    assert changeset.valid?
  end

  test "changeset with invalid attributes for step one v3" do
    changeset = Company.changeset_reg_step_oneV3(%Company{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "countries_id required check for step one v3" do
    changeset = Company.changeset_reg_step_oneV3(%Company{}, Map.delete(@valid_attrs_step_onev3, :countries_id))
    assert !changeset.valid?
  end

  test "company_type required check for step one v3" do
    changeset = Company.changeset_reg_step_oneV3(%Company{}, Map.delete(@valid_attrs_step_onev3, :company_type))
    assert !changeset.valid?
  end

  test "check if loading_fee accepts only LTD, STR" do
    attrs = %{@valid_attrs_step_onev3 | loading_fee: "R"}
    changeset = Company.changeset_reg_step_oneV3(%Company{}, attrs)
    assert %{loading_fee: ["is invalid"]} = errors_on(changeset)
  end


  @doc" changeset_reg_step_four"

  @valid_attrs_step_four %{
    countries_id: 1211,
    loading_fee: "Y",
    company_name: "company 1",
    company_cin: "CIN",
    company_logo: "LOGO",
    registration_number: "A00000000",
    date_of_registration: ~D[2014-04-02],
    landline_number: "02520211548",
    sector_id: 45,
    sector_details: "sector details",
    monthly_transfer: 500,
    company_website: "website.com",
    company_type: "LTD",
    inserted_by: 1212
  }


  test "changeset with valid attributes for step four" do
    changeset = Company.changeset_reg_step_four(%Company{}, @valid_attrs_step_four)
    assert changeset.valid?
  end

  test "changeset with invalid attributes for step four" do
    changeset = Company.changeset_reg_step_four(%Company{}, @invalid_attrs)
    refute changeset.valid?
  end


  test "sector_id required check for step four" do
    changeset = Company.changeset_reg_step_four(%Company{}, Map.delete(@valid_attrs_step_four, :sector_id))
    assert !changeset.valid?
  end

  test "sector_details required check for step four" do
    changeset = Company.changeset_reg_step_four(%Company{}, Map.delete(@valid_attrs_step_four, :sector_details))
    assert !changeset.valid?
  end

  test "monthly_transfer required check for step four" do
    changeset = Company.changeset_reg_step_four(%Company{}, Map.delete(@valid_attrs_step_four, :monthly_transfer))
    assert !changeset.valid?
  end

  test "company_name required check for step four" do
    changeset = Company.changeset_reg_step_four(%Company{}, Map.delete(@valid_attrs_step_four, :company_name))
    assert !changeset.valid?
  end

  test "landline_number required check for step four" do
    changeset = Company.changeset_reg_step_four(%Company{}, Map.delete(@valid_attrs_step_four, :landline_number))
    assert !changeset.valid?
  end

  test "date_of_registration required check for step four" do
    changeset = Company.changeset_reg_step_four(%Company{}, Map.delete(@valid_attrs_step_four, :date_of_registration))
    assert !changeset.valid?
  end

  test "check if company_name maximum 40 characters step four" do
    attrs = %{
      @valid_attrs_step_four |
      company_name: "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghij"
    }
    changeset = Company.changeset_reg_step_four(%Company{}, attrs)
    assert %{company_name: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

  test "check if company_name minimum 3 characters step four" do
    attrs = %{@valid_attrs_step_four | company_name: "ac"}
    changeset = Company.changeset_reg_step_four(%Company{}, attrs)
    assert %{company_name: ["should be at least 3 character(s)"]} = errors_on(changeset)
  end

  test "check if company_name accepts only alpha characters step four" do
    attrs = %{@valid_attrs_step_four | company_name: "%%%%%^&"}
    changeset = Company.changeset_reg_step_four(%Company{}, attrs)
    assert %{company_name: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if registration_number accepts only alpha characters step four" do
    attrs = %{@valid_attrs_step_four | registration_number: "%%%%%^&"}
    changeset = Company.changeset_reg_step_four(%Company{}, attrs)
    assert %{registration_number: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if landline_number accepts only alpha characters step four" do
    attrs = %{@valid_attrs_step_four | landline_number: "%%%tyef%%^&"}
    changeset = Company.changeset_reg_step_four(%Company{}, attrs)
    assert %{landline_number: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if company_website accepts only alpha characters step four" do
    attrs = %{@valid_attrs_step_four | company_website: "%%%%%^&"}
    changeset = Company.changeset_reg_step_four(%Company{}, attrs)
    assert %{company_website: ["has invalid format"]} = errors_on(changeset)
  end

  test "check if registration_number maximum 25 characters step four" do
    attrs = %{@valid_attrs_step_four | registration_number: "frgfdgfdgdfgfdgdfgsdgrgerdfgrwgaged"}
    changeset = Company.changeset_reg_step_four(%Company{}, attrs)
    assert %{registration_number: ["should be at most 25 character(s)"]} = errors_on(changeset)
  end

  test "check if registration_number minimum 6 characters step four" do
    attrs = %{@valid_attrs_step_four | registration_number: "ac"}
    changeset = Company.changeset_reg_step_four(%Company{}, attrs)
    assert %{registration_number: ["should be at least 6 character(s)"]} = errors_on(changeset)
  end

  test "check if landline_number maximum 11 characters step four" do
    attrs = %{@valid_attrs_step_four | landline_number: "012112154584"}
    changeset = Company.changeset_reg_step_four(%Company{}, attrs)
    assert %{landline_number: ["should be at most 11 character(s)"]} = errors_on(changeset)
  end

  test "check if landline_number minimum 11 characters step four" do
    attrs = %{@valid_attrs_step_four | landline_number: "01"}
    changeset = Company.changeset_reg_step_four(%Company{}, attrs)
    assert %{
             landline_number: ["should be at least 11 character(s)",
               "has invalid format"]
           } = errors_on(changeset)
  end

  test "check if company_website maximum 150 characters step four" do
    attrs = %{
      @valid_attrs_step_four |
      company_website: "www.ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddccccccccccccccaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaacccccccccccccccc.com"
    }
    changeset = Company.changeset_reg_step_four(%Company{}, attrs)
    assert %{company_website: ["should be at most 150 character(s)"]} = errors_on(changeset)
  end

  test "check if company_website minimum 6 characters step four" do
    attrs = %{@valid_attrs_step_four | company_website: "ww.co"}
    changeset = Company.changeset_reg_step_four(%Company{}, attrs)
    assert %{company_website: ["should be at least 6 character(s)"]} = errors_on(changeset)
  end

  test "check if sector_details maximum 100 characters step four" do
    attrs = %{
      @valid_attrs_step_four |
      sector_details: "wwwdsdfsdfsdfdfkndsjfifhjasikhsdcscascasvascascsadcxsafjiashjfiasjiasjficanciashodsankjdcbnsaascascsacom"
    }
    changeset = Company.changeset_reg_step_four(%Company{}, attrs)
    assert %{sector_details: ["should be at most 100 character(s)"]} = errors_on(changeset)
  end

  test "check if sector_details minimum 2 characters step four" do
    attrs = %{@valid_attrs_step_four | sector_details: "w"}
    changeset = Company.changeset_reg_step_four(%Company{}, attrs)
    assert %{sector_details: ["should be at least 2 character(s)"]} = errors_on(changeset)
  end

  @doc " changeset_reg_step_four_limited_company"

  @valid_attrs_4ltd %{
    countries_id: 3,
    loading_fee: "Y",
    company_name: "Company Name",
    company_cin: "CIN",
    company_logo: "LGOG",
    registration_number: "aaaaaaaaaaaaa",
    date_of_registration: ~D[2019-01-01],
    landline_number: "02920255698",
    sector_id: 3,
    sector_details: "details of sector",
    monthly_transfer: 500,
    company_website: "www.cas.com",
    company_type: "LTD",
    inserted_by: 1212
  }

  test "changeset with valid attributes for step four_limited" do
    changeset = Company.changeset_reg_step_four_limited_company(%Company{}, @valid_attrs_4ltd)
    assert changeset.valid?
  end

  test "changeset with invalid attributes for step four_limited" do
    changeset = Company.changeset_reg_step_four_limited_company(%Company{}, @invalid_attrs)
    refute changeset.valid?
  end


  test "sector_id required check for step four_limited" do
    changeset = Company.changeset_reg_step_four_limited_company(%Company{}, Map.delete(@valid_attrs_4ltd, :sector_id))
    assert !changeset.valid?
  end

  test "sector_details required check for step four_limited" do
    changeset = Company.changeset_reg_step_four_limited_company(%Company{}, Map.delete(@valid_attrs_4ltd, :sector_details))
    assert !changeset.valid?
  end

  test "monthly_transfer required check for step four_limited" do
    changeset = Company.changeset_reg_step_four_limited_company(%Company{}, Map.delete(@valid_attrs_4ltd, :monthly_transfer))
    assert !changeset.valid?
  end

  test "company_name required check for step four_limited" do
    changeset = Company.changeset_reg_step_four_limited_company(%Company{}, Map.delete(@valid_attrs_4ltd, :company_name))
    assert !changeset.valid?
  end

  test "landline_number required check for step four_limited" do
    changeset = Company.changeset_reg_step_four_limited_company(%Company{}, Map.delete(@valid_attrs_4ltd, :landline_number))
    assert !changeset.valid?
  end

  test "date_of_registration required check for step four_limited" do
    changeset = Company.changeset_reg_step_four_limited_company(%Company{}, Map.delete(@valid_attrs_4ltd, :date_of_registration))
    assert !changeset.valid?
  end

  test "registration_number required check for step four_limited" do
    changeset = Company.changeset_reg_step_four_limited_company(%Company{}, Map.delete(@valid_attrs_4ltd, :registration_number))
    assert !changeset.valid?
  end

  test "check if company_name min length 3 characters" do
    attrs = %{@valid_attrs_4ltd | company_name: "aa"}
    changeset = Company.changeset_reg_step_four_limited_company(%Company{}, attrs)
    assert %{company_name: ["should be at least 3 character(s)"]} = errors_on(changeset)
  end

  test "check if company_name maximum length 40 characters" do
    attrs = %{@valid_attrs_4ltd | company_name: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}
    changeset = Company.changeset_reg_step_four_limited_company(%Company{}, attrs)
    assert %{company_name: ["should be at most 40 character(s)"]} = errors_on(changeset)
  end

  test "check company name format" do
    attrs = %{@valid_attrs_4ltd | company_name: "23~'#####"}
    changeset = Company.changeset_reg_step_four_limited_company(%Company{}, attrs)
    assert %{company_name: ["has invalid format"]} = errors_on(changeset)
  end

  test "check registration_number format" do
    attrs = %{@valid_attrs_4ltd | registration_number: "23~'#####"}
    changeset = Company.changeset_reg_step_four_limited_company(%Company{}, attrs)
    assert %{registration_number: ["has invalid format"]} = errors_on(changeset)
  end


  test "check if registration_number min length 6 characters" do
    attrs = %{@valid_attrs_4ltd | registration_number: "aa"}
    changeset = Company.changeset_reg_step_four_limited_company(%Company{}, attrs)
    assert %{registration_number: ["should be at least 6 character(s)"]} = errors_on(changeset)
  end

  test "check if registration_number maximum length 25 characters" do
    attrs = %{@valid_attrs_4ltd | registration_number: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"}
    changeset = Company.changeset_reg_step_four_limited_company(%Company{}, attrs)
    assert %{registration_number: ["should be at most 25 character(s)"]} = errors_on(changeset)
  end

  test "check landline_number format" do
    attrs = %{@valid_attrs_4ltd | landline_number: "23~'#####ss"}
    changeset = Company.changeset_reg_step_four_limited_company(%Company{}, attrs)
    assert %{landline_number: ["has invalid format"]} = errors_on(changeset)
  end


  test "check if landline_number min length 11 characters" do
    attrs = %{@valid_attrs_4ltd | landline_number: "0234323322"}
    changeset = Company.changeset_reg_step_four_limited_company(%Company{}, attrs)
    assert %{landline_number: ["should be at least 11 character(s)",
               "has invalid format"]} = errors_on(changeset)
  end

  test "check if landline_number maximum length 11 characters" do
    attrs = %{@valid_attrs_4ltd | landline_number: "0111111111111111111111111111"}
    changeset = Company.changeset_reg_step_four_limited_company(%Company{}, attrs)
    assert %{landline_number: ["should be at most 11 character(s)"]} = errors_on(changeset)
  end


  test "check company_website format" do
    attrs = %{@valid_attrs_4ltd | company_website: "23~'#####ss"}
    changeset = Company.changeset_reg_step_four_limited_company(%Company{}, attrs)
    assert %{company_website:   ["has invalid format"]} = errors_on(changeset)
  end


  test "check if company_website min length 6 characters" do
    attrs = %{@valid_attrs_4ltd | company_website: "w.a.c"}
    changeset = Company.changeset_reg_step_four_limited_company(%Company{}, attrs)
    assert %{company_website: ["should be at least 6 character(s)",
               "has invalid format"]} = errors_on(changeset)
  end

  test "check if company_website maximum length 150 characters" do
    attrs = %{@valid_attrs_4ltd | company_website: "www.aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.com"}
    changeset = Company.changeset_reg_step_four_limited_company(%Company{}, attrs)
    assert %{company_website: ["should be at most 150 character(s)"]} = errors_on(changeset)
  end

  test "check if sector_details min length 2 characters" do
    attrs = %{@valid_attrs_4ltd | sector_details: "w"}
    changeset = Company.changeset_reg_step_four_limited_company(%Company{}, attrs)
    assert %{sector_details: ["should be at least 2 character(s)"]} = errors_on(changeset)
  end

  test "check if sector_details maximum length 100 characters" do
    attrs = %{@valid_attrs_4ltd | sector_details: "ThehlakjslkkskjkkThehlaThehlakjslkkskjkkThehlakjslkkskjkkThehlakjslkkskjkkThehlakjslkkskjkkkjslkkskjkkThehlakjslkkskjkk"}
    changeset = Company.changeset_reg_step_four_limited_company(%Company{}, attrs)
    assert %{sector_details: ["should be at most 100 character(s)"]} = errors_on(changeset)
  end


  @doc " changeset_empty"

  @valid_attrs_empty %{
    countries_id: 3,
    company_name: "Company Name",
    company_cin: "CIN",
    company_logo: "LGOG",
    registration_number: "aaaaaaaaaaaaa",
    date_of_registration: ~D[2019-01-01],
    landline_number: "02920255698",
    company_website: "www.cas.com",
    company_type: "LTD",
    inserted_by: 1212
  }

  test "changeset with valid attributes for changeset_empty" do
    changeset = Company.changeset_empty(%Company{}, @valid_attrs_empty)
    assert changeset.valid?
  end

  test "changeset with invalid attributes for changeset_empty" do
    changeset = Company.changeset_empty(%Company{}, @invalid_attrs)
    refute changeset.valid?
  end


  test "countries_id required check for step four_limited" do
    changeset = Company.changeset_empty(%Company{}, Map.delete(@valid_attrs_empty, :countries_id))
    assert !changeset.valid?
  end


  @doc " changesetWebsite"

  @valid_attrs_changesetWebsite %{
    company_website: "www.cas.com"
  }

  test "changeset with valid attributes for changesetWebsite" do
    changeset = Company.changesetWebsite(%Company{}, @valid_attrs_changesetWebsite)
    assert changeset.valid?
  end

  @doc " changesetGroup"

  @valid_attrs_changesetGroup %{
    group_id: 1213
  }

  test "changeset with valid attributes for changesetGroup" do
    changeset = Company.changesetGroup(%Company{}, @valid_attrs_changesetGroup)
    assert changeset.valid?
  end


  @doc " changesetregisteration"

  @valid_attrs_changesetregisteration %{
    registration_number: "1235215"
  }

  test "changeset with valid attributes for changesetregisteration" do
    changeset = Company.changesetregisteration(%Company{}, @valid_attrs_changesetregisteration)
    assert changeset.valid?
  end

  test "changeset with invalid attributes for changesetregisteration" do
    changeset = Company.changesetregisteration(%Company{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "registration_number required check for changesetregisteration" do
    changeset = Company.changesetregisteration(%Company{}, Map.delete(@valid_attrs_changesetregisteration, :registration_number))
    assert !changeset.valid?
  end

  test "check registration_number format changesetregisteration" do
    attrs = %{@valid_attrs_changesetregisteration | registration_number: "23~'#####ss"}
    changeset = Company.changesetregisteration(%Company{}, attrs)
    assert %{registration_number:   ["has invalid format"]} = errors_on(changeset)
  end

  test "check if registration_number min length 6 characters changesetregisteration" do
    attrs = %{@valid_attrs_changesetregisteration | registration_number: "4554"}
    changeset = Company.changesetregisteration(%Company{}, attrs)
    assert %{registration_number: ["should be at least 6 character(s)"]} = errors_on(changeset)
  end

  test "check if registration_number maximum length 25 characters changesetregisteration" do
    attrs = %{@valid_attrs_changesetregisteration | registration_number: "1234512451245124512465784519545"}
    changeset = Company.changesetregisteration(%Company{}, attrs)
    assert %{registration_number: ["should be at most 25 character(s)"]} = errors_on(changeset)
  end


  @doc " changesetContact"

  @valid_attrs_changesetContact %{
    landline_number: "07411542587"
  }

  test "changeset with valid attributes for valid_attrs_changesetContact" do
    changeset = Company.changesetContact(%Company{}, @valid_attrs_changesetContact)
    assert changeset.valid?
  end

  test "changeset with invalid attributes for valid_attrs_changesetContact" do
    changeset = Company.changesetContact(%Company{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "landline_number required check for changesetContact" do
    changeset = Company.changesetContact(%Company{}, Map.delete(@valid_attrs_changesetContact, :landline_number))
    assert !changeset.valid?
  end

  test "check landline_number if blank changesetContact" do
    attrs = %{@valid_attrs_changesetContact | landline_number: ""}
    changeset = Company.changesetContact(%Company{}, attrs)
    assert %{landline_number: ["can't be blank"]} = errors_on(changeset)
  end

  test "check landline_number format changesetContact" do
    attrs = %{@valid_attrs_changesetContact | landline_number: "23~'#####ss"}
    changeset = Company.changesetContact(%Company{}, attrs)
    assert %{landline_number:   ["has invalid format"]} = errors_on(changeset)
  end

  test "check if landline_number min length 11 characters changesetContact" do
    attrs = %{@valid_attrs_changesetContact | landline_number: "4554"}
    changeset = Company.changesetContact(%Company{}, attrs)
    assert %{landline_number:  ["should be at least 11 character(s)",
               "has invalid format"]} = errors_on(changeset)
  end

  test "check if landline_number maximum length 11 characters changesetContact" do
    attrs = %{@valid_attrs_changesetContact | landline_number: "1234512451245124512465784519545"}
    changeset = Company.changesetContact(%Company{}, attrs)
    assert %{landline_number:  ["should be at most 11 character(s)",
               "has invalid format"]
           } = errors_on(changeset)
  end

end