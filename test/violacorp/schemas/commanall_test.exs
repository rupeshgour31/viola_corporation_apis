defmodule Violacorp.Schemas.CommanallTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Commanall
  @moduledoc false

  #  @valid_attrs %{
  #    email_id:  "simoon@viola.co.uk",
  #    password:  "fjkfasdf&^%02#",
  #    vpin:  "1234",
  #    status:  "A",
  #    viola_id:  "viola001",
  #    accomplish_userid:  "12125",
  #    request:  "Map",
  #    response:  "Map",
  #    reg_step:  "OTP",
  #    step:  "OTP",
  #    reg_data:  "Map",
  #    id_proof:  "Y",
  #    m_api_token:  "AWdswaddw52D35215354",
  #    api_token:  "Ddsa345315321DSf",
  #    ip_address:  "192.168.0.1",
  #    address_proof:  "Y",
  #    card_requested:  "Y",
  #    on_boarding_fee:  "Y",
  #    as_employee:  "N",
  #    trust_level:  2,
  #    as_login:  "Y",
  #    check_version:  "Y",
  #    inserted_by:  1212,
  #  }

  @valid_attrs %{
    email_id: "simoon@viola.co.uk",
    viola_id: "viola001",
    company_id: 120
  }
  @invalid_attrs %{}
  @doc"changeset"
  test "changeset with valid attributes" do
    changeset = Commanall.changeset(%Commanall{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Commanall.changeset(%Commanall{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "email_id required check" do
    changeset = Commanall.changeset(%Commanall{}, Map.delete(@valid_attrs, :email_id))
    assert !changeset.valid?
  end

  @doc" registration_changeset"

  @valid_attrs_registration %{
    password: "fjkfasdf&^%02#",
    vpin: "1352",
    status: "A",
    reg_step: "OTP",
  }

  test "changeset with valid attributes for registration" do
    changeset = Commanall.registration_changeset(%Commanall{}, @valid_attrs_registration)
    assert changeset.valid?
  end

  test "changeset with invalid attributes for registration" do
    changeset = Commanall.registration_changeset(%Commanall{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "vpin required check for registration" do
    changeset = Commanall.registration_changeset(%Commanall{}, Map.delete(@valid_attrs_registration, :vpin))
    assert !changeset.valid?
  end

  test "password required check for registration" do
    changeset = Commanall.registration_changeset(%Commanall{}, Map.delete(@valid_attrs_registration, :password))
    assert !changeset.valid?
  end

  @doc"registration_accomplish "
  @valid_attrs_accomplish %{
    accomplish_userid: 21215,
    request: "MAP",
    response: "map"
  }
  test "changeset with valid attributes for accomplish" do
    changeset = Commanall.registration_accomplish(%Commanall{}, @valid_attrs_accomplish)
    assert changeset.valid?
  end

  @doc " login_changeset"

  @valid_attrs_login %{
    company_id: 1212,
    employee_id: 121,
    viola_id: "viola125",
    email_id: "simon@viola.org",
    password: "kjkjaH78##£",
    status: "A"
  }

  test "changeset with valid attributes for login" do
    changeset = Commanall.login_changeset(%Commanall{}, @valid_attrs_login)
    assert changeset.valid?
  end

  test "changeset with invalid attributes for login" do
    changeset = Commanall.login_changeset(%Commanall{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "email_id required check for login" do
    changeset = Commanall.login_changeset(%Commanall{}, Map.delete(@valid_attrs_login, :email_id))
    assert !changeset.valid?
  end

  test "password required check for login" do
    changeset = Commanall.login_changeset(%Commanall{}, Map.delete(@valid_attrs_login, :password))
    assert !changeset.valid?
  end

  @doc" changeset_company_contact"

  @valid_attrs_companycontact %{
    viola_id: "viola002",
    email_id: "simon@viola.org",
    password: "jhjhH555##",
    reg_data: "map",
    step: "OTP",
    reg_step: "OTP",
    status: "A"
  }
  test "changeset with valid attributes for company_contact" do
    changeset = Commanall.changeset_company_contact(%Commanall{}, @valid_attrs_companycontact)
    assert changeset.valid?
  end

  test "changeset with invalid attributes for company_contact" do
    changeset = Commanall.changeset_company_contact(%Commanall{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "email_id required check for company_contact" do
    changeset = Commanall.changeset_company_contact(%Commanall{}, Map.delete(@valid_attrs_companycontact, :email_id))
    assert !changeset.valid?
  end

  test "check if email_id maximum 150 characters" do
    attrs = %{
      @valid_attrs_companycontact |
      email_id: "siiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiimmmmmmmmmooooooooooooooooooooooooooooooooooooooooooooon@viooooooooooooooooooooooooooooola.ooooooooooooooooooooorg"
    }
    changeset = Commanall.changeset_company_contact(%Commanall{}, attrs)
    assert %{email_id: ["should be at most 150 character(s)"]} = errors_on(changeset)
  end

  @doc " changeset_contact"

  @valid_attrs_contact %{
    viola_id: "viola002",
    email_id: "simon@coialk.com",
    vpin: 1234,
    password: "jhjHH76s##",
    as_employee: "Y",
    status: "A"
  }

  test "changeset with valid attributes for contact" do
    changeset = Commanall.changeset_contact(%Commanall{}, @valid_attrs_contact)
    assert changeset.valid?
  end

  test "changeset with invalid attributes for contact" do
    changeset = Commanall.changeset_contact(%Commanall{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "email_id required check for contact" do
    changeset = Commanall.changeset_contact(%Commanall{}, Map.delete(@valid_attrs_contact, :email_id))
    assert !changeset.valid?
  end

  test "check if email_id maximum 150 characters for contact" do
    attrs = %{
      @valid_attrs_contact |
      email_id: "siiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiimmmmmmmmmooooooooooooooooooooooooooooooooooooooooooooon@viooooooooooooooooooooooooooooola.ooooooooooooooooooooorg"
    }
    changeset = Commanall.changeset_contact(%Commanall{}, attrs)
    assert %{email_id: ["should be at most 150 character(s)"]} = errors_on(changeset)
  end

  test "check if vpin min length 4 for contact" do
    attrs = %{@valid_attrs_contact | vpin: 123}
    changeset = Commanall.changeset_contact(%Commanall{}, attrs)
    assert %{vpin: ["should be at least 4 character(s)"]} = errors_on(changeset)
  end

  test "check if vpin max length 4 for contact" do
    attrs = %{@valid_attrs_contact | vpin: 12345}
    changeset = Commanall.changeset_contact(%Commanall{}, attrs)
    assert %{vpin: ["should be at most 4 character(s)"]} = errors_on(changeset)
  end

  @doc"changeset_contactinfo"

  @valid_attrs_contactinfo %{
    viola_id: "viola002",
    email_id: "simon@viola.com",
    password: "jJSjhjhd&^&##",
    status: "A"
  }

  test "changeset with valid attributes for contactinfo" do
    changeset = Commanall.changeset_contactinfo(%Commanall{}, @valid_attrs_contactinfo)
    assert changeset.valid?
  end

  @doc"changeset_updatepassword"
  @valid_attrs_updatepassword %{
    password: "jsjdhd8787##"
  }

  test "changeset with valid attributes for changeset_updatepassword" do
    changeset = Commanall.changeset_updatepassword(%Commanall{}, @valid_attrs_updatepassword)
    assert changeset.valid?
  end

  test "changeset with invalid attributes for changeset_updatepassword" do
    changeset = Commanall.changeset_updatepassword(%Commanall{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "password required check for changeset_updatepassword" do
    changeset = Commanall.changeset_updatepassword(%Commanall{}, Map.delete(@valid_attrs_updatepassword, :password))
    assert !changeset.valid?
  end

  @doc "changeset_updatepin "

  @valid_attrs_updatepin %{
    vpin: 1234
  }

  test "changeset with valid attributes for vpin" do
    changeset = Commanall.changeset_updatepin(%Commanall{}, @valid_attrs_updatepin)
    assert changeset.valid?
  end

  test "changeset with invalid attributes for vpin" do
    changeset = Commanall.changeset_updatepin(%Commanall{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "vpin required check for vpin" do
    changeset = Commanall.changeset_updatepin(%Commanall{}, Map.delete(@valid_attrs_updatepin, :vpin))
    assert !changeset.valid?
  end

  test "check if vpin min length 4 for vpin" do
    attrs = %{@valid_attrs_updatepin | vpin: 123}
    changeset = Commanall.changeset_updatepin(%Commanall{}, attrs)
    assert %{vpin: ["should be at least 4 character(s)"]} = errors_on(changeset)
  end

  test "check if vpin max length 4 for vpin" do
    attrs = %{@valid_attrs_updatepin | vpin: 12345}
    changeset = Commanall.changeset_updatepin(%Commanall{}, attrs)
    assert %{vpin: ["should be at most 4 character(s)"]} = errors_on(changeset)
  end

  test "check if vpin has invalid format" do
    attrs = %{@valid_attrs_updatepin | vpin: "%%%%"}
    changeset = Commanall.changeset_updatepin(%Commanall{}, attrs)
    assert %{vpin: ["has invalid format"]} = errors_on(changeset)
  end

  @doc "changeset_updateemail"

  @valid_attrs_updateemail %{
    email_id: "simon@viola.org"
  }

  test "changeset with valid attributes for email_id" do
    changeset = Commanall.changeset_updateemail(%Commanall{}, @valid_attrs_updateemail)
    assert changeset.valid?
  end

  test "changeset with invalid attributes for email_id" do
    changeset = Commanall.changeset_updateemail(%Commanall{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "email_id required check for email_id" do
    changeset = Commanall.changeset_updateemail(%Commanall{}, Map.delete(@valid_attrs_updateemail, :email_id))
    assert !changeset.valid?
  end

  @doc"changesetSteps "

  @valid_attrs_steps %{
    step: "vpin",
    reg_data: "MAP",
    reg_step: "1",
    status: "A"
  }

  test "changeset with valid attributes for steps" do
    changeset = Commanall.changesetSteps(%Commanall{}, @valid_attrs_steps)
    assert changeset.valid?
  end

  @doc "changesetRequest "

  @valid_attrs_request %{
    card_requested: "Y"
  }
  test "changeset with valid attributes for card requested" do
    changeset = Commanall.changesetRequest(%Commanall{}, @valid_attrs_request)
    assert changeset.valid?
  end

  @doc "changesetFee "

  @valid_attrs_fee %{
    on_boarding_fee: "Y"
  }

  test "changeset with valid attributes for fee" do
    changeset = Commanall.changesetFee(%Commanall{}, @valid_attrs_fee)
    assert changeset.valid?
  end

  @doc "changeset_first_step"

  @valid_attrs_first_step %{
    viola_id: "viola002",
    email_id: "simon@viola.orf",
    password: "Hkjsakj762##",
    vpin: 1234,
    reg_data: "MAP",
    step: "OTP",
    reg_step: "OTP",
    status: "A",
    ip_address: "192.168.0.1"
  }

  test "changeset with valid attributes for first_step" do
    changeset = Commanall.changeset_first_step(%Commanall{}, @valid_attrs_first_step)
    assert changeset.valid?
  end

  test "changeset with invalid attributes for first_step" do
    changeset = Commanall.changeset_first_step(%Commanall{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "email_id required check for first_step" do
    changeset = Commanall.changeset_first_step(%Commanall{}, Map.delete(@valid_attrs_first_step, :email_id))
    assert !changeset.valid?
  end

  test "check if email_id maximum 150 characters for first_step" do
    attrs = %{
      @valid_attrs_first_step |
      email_id: "siiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiimmmmmmmmmooooooooooooooooooooooooooooooooooooooooooooon@viooooooooooooooooooooooooooooola.ooooooooooooooooooooorg"
    }
    changeset = Commanall.changeset_first_step(%Commanall{}, attrs)
    assert %{email_id: ["should be at most 150 character(s)"]} = errors_on(changeset)
  end

  test "check if password has invalid format" do
    attrs = %{@valid_attrs_first_step | password: "ssssssssssss"}
    changeset = Commanall.changeset_first_step(%Commanall{}, attrs)
    assert %{
             password: [
               "Password must be between 8-15 digits and have at least one number, one lowercase, one uppercase alphabet and one special character (e.g. #$^+=!*()@%&)."
             ]
           } = errors_on(changeset)
  end

  @doc" changesetEmail"
  @valid_attrs_email %{
    email_id: "simon@vioa.org"
  }
  test "changeset with valid attributes for changesetEmail" do
    changeset = Commanall.changesetEmail(%Commanall{}, @valid_attrs_email)
    assert changeset.valid?
  end
  test "changeset with invalid attributes for changesetEmail" do
    changeset = Commanall.changesetEmail(%Commanall{}, @invalid_attrs)
    refute changeset.valid?
  end
  test "email_id required check for changesetEmail" do
    changeset = Commanall.changesetEmail(%Commanall{}, Map.delete(@valid_attrs_email, :email_id))
    assert !changeset.valid?
  end
  test "check if email_id maximum 150 characters for changesetEmail" do
    attrs = %{
      @valid_attrs_email |
      email_id: "siiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiimmmmmmmmmooooooooooooooooooooooooooooooooooooooooooooon@viooooooooooooooooooooooooooooola.ooooooooooooooooooooorg"
    }
    changeset = Commanall.changesetEmail(%Commanall{}, attrs)
    assert %{email_id: ["should be at most 150 character(s)"]} = errors_on(changeset)
  end

  @doc" changeset_as_employee"
  @valid_attrs_employee %{
    employee_id: 121,
    as_employee: "Y",
    card_requested: "Y"
  }
  test "changeset with valid attributes for changeset_as_employee" do
    changeset = Commanall.changeset_as_employee(%Commanall{}, @valid_attrs_employee)
    assert changeset.valid?
  end
  test "changeset with invalid attributes for changeset_as_employee" do
    changeset = Commanall.changeset_as_employee(%Commanall{}, @invalid_attrs)
    refute changeset.valid?
  end
  test "employee_id required check for changeset_as_employee" do
    changeset = Commanall.changeset_as_employee(%Commanall{}, Map.delete(@valid_attrs_employee, :employee_id))
    assert !changeset.valid?
  end

  @doc " updateStatus"
  @valid_attrs_status %{
    status: "A"
  }
  test "changeset with valid attributes for updateStatus" do
    changeset = Commanall.updateStatus(%Commanall{}, @valid_attrs_status)
    assert changeset.valid?
  end

  @doc" update_token"
  @valid_attrs_update_token %{
    api_token: "sf215fds46135463546sd5f46sdsdf",
    m_api_token: "kjsdlkfjsafd8787878sa9da",
    ip_address: "192.168.0.1"
  }
  test "changeset with valid attributes for token" do
    changeset = Commanall.update_token(%Commanall{}, @valid_attrs_update_token)
    assert changeset.valid?
  end

  @doc" update_login"
  @valid_attrs_update_login %{
    as_login: "Y"
  }
  test "changeset with valid attributes for update_login" do
    changeset = Commanall.update_login(%Commanall{}, @valid_attrs_update_login)
    assert changeset.valid?
  end

  @doc "updateField"
  @valid_attrs_onboarding_fee %{
    on_boarding_fee: "Y"
  }
  test "changeset with valid attributes for updateField" do
    changeset = Commanall.updateField(%Commanall{}, @valid_attrs_onboarding_fee)
    assert changeset.valid?
  end

  @doc "updateTrustLevel"
  @valid_attrs_trustlevel %{
    trust_level: "3"
  }
  test "changeset with valid attributes for trustlevel" do
    changeset = Commanall.updateTrustLevel(%Commanall{}, @valid_attrs_trustlevel)
    assert changeset.valid?
  end

  test "changeset with invalid attributes for trustlevel" do
    changeset = Commanall.updateTrustLevel(%Commanall{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "trust_level required check for trustlevel" do
    changeset = Commanall.updateTrustLevel(%Commanall{}, Map.delete(@valid_attrs_trustlevel, :trust_level))
    assert !changeset.valid?
  end

end