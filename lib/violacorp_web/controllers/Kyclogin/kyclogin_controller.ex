defmodule ViolacorpWeb.Kyclogin.KycloginController do
  use ViolacorpWeb, :controller
  import Ecto.Query

  alias Violacorp.Repo

  alias Violacorp.Schemas.Kyclogin
  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Kycdirectors
  #  alias Violacorp.Schemas.Otp
  alias Violacorp.Schemas.Contactsdirectors
  alias Violacorp.Schemas.Addressdirectors
#  alias Violacorp.Schemas.Commanall



  alias ViolacorpWeb.Main.V2AlertsController

  alias  Violacorp.Libraries.Commontools

  @doc "Kyc Login "
  def kycLogin(conn, params)do
    unless map_size(params) == 0 do
      kyclogin = Repo.one(
        from a in Kyclogin, where: a.username == ^params["username"] and a.password == ^params["password"],
                            select: %{
                              username: a.username,
                              status: a.status,
                              steps: a.steps,
                              last_login: a.last_login,
                              directors_id: a.directors_id
                            }
      )
      if is_nil(kyclogin) do
        conn
        |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :emailPasswordWrong)
        |> halt
      else
        abc = conn
              |> assign_token(kyclogin, params)
        json conn, %{status_code: "200", steps: kyclogin.steps, token: abc}
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  @doc "assign token"
  def assign_token(_status, kyclogin, _params)do
    keyfortoken = Application.get_env(:violacorp, :tokenKey)
    payload = %{
      "directors_id" => kyclogin.directors_id
    }
    create_token(keyfortoken, payload)
  end

  @doc "create token"
  def create_token(key_for_token, payload) do
    Phoenix.Token.sign(ViolacorpWeb.Endpoint, key_for_token, payload)
  end

  @doc "upload director kyc"
  def  uploadKyc(conn, params)do
    %{"directors_id" => d_id} = conn.assigns[:current_user]

    file_image = cond do
      params["image_one"] == "" -> {:idproof, "Please select Id proof"}
      params["address_image_one"] == "" -> {:addressproof, "Please select address proof"}
      is_nil(params["image_one"]) -> {:idproof, "Please select Id proof"}
      is_nil(params["address_image_one"]) -> {:addressproof, "Please select address proof"}
      true -> {:ok, "yes"}
    end

    mobile = case String.first(params["contact_number"]) do
      "0" -> case String.at(params["contact_number"], 1) do
               "7" -> {:ok, "yes"}
               _ -> {:invalidMobile, "Please enter a valid mobile number"}
             end
      "7" -> {:ok, "yes"}
      _ -> {:invalidMobile, "Please enter a valid mobile number"}
    end
    contact_data = Repo.one(
      from contact in Contactsdirectors, where: contact.contact_number == ^params["contact_number"],
                                         limit: 1,
                                         select: contact
    )
    check_mobile = if !is_nil(contact_data) do
      {:error, "Mobile number is already registered."}
    else
      {:ok, "yes"}
    end

    #       file_image = if params["image_one"] !="" and params["address_image_one"] != "", do: {:ok, "yes"}, else: {:error, "Please upload Document"}
    #       check_file_image = if !is_nil(params["image_one"]) and !is_nil(params["address_image_one"]), do: {:ok, "yes"}, else: {:error, "Please upload Document"}
    with {:ok, _value} <- mobile,
         {:ok, _value} <- check_mobile,
         {:ok, _value} <- file_image do

      directors = Repo.get_by(Directors, id: d_id)
      if !is_nil(directors) do
#        com_info = Repo.get_by(Commanall, company_id: directors.company_id)
        country_code = Application.get_env(:violacorp, :country_code)

        contactsdirectors = %{
          "directors_id" => d_id,
          "contact_number" => params["contact_number"],
          "code" => country_code,
          "is_primary" => "Y"
        }
        gender = case params["title"] do
          "Mr" -> "M"
          "Mrs" -> "F"
          "Miss" -> "F"
          "Ms" -> "F"
          _ -> "M"
        end
        director_info = %{
          "title" => params["title"],
          "first_name" => params["first_name"],
          "middle_name" => params["middle_name"],
          "last_name" => params["last_name"],
          "date_of_birth" => params["date_of_birth"],
          "signature" => params["signature"],
          "gender" => gender,
          #                 "mendate_signature" => params["mendate_signature"],
        }
        address_map = %{
          "directors_id" => d_id,
          "countries_id" => params["location_id"],
          "address_line_one" => params["address_line_one"],
          "address_line_two" => params["address_line_two"],
          "address_line_three" => params["address_line_three"],
          "town" => params["town"],
          "post_code" => params["post_code"],
          "county" => params["county"]
        }
        file_location_one = if params["image_one"] != "" do
          ViolacorpWeb.Main.Assetstore.upload_image(params["image_one"])
        else
          nil
        end
        file_location_two = if params["image_two"] != "" do
          ViolacorpWeb.Main.Assetstore.upload_image(params["image_two"])
        else
          nil
        end
        address_location_one = if params["address_image_one"] != "" do
          ViolacorpWeb.Main.Assetstore.upload_image(params["address_image_one"])
        else
          nil
        end

        file_name = if !is_nil(file_location_one) do
          Path.basename(file_location_one)
        else
          if !is_nil(file_location_two) do
            Path.basename(file_location_two)
          else
            nil
          end
        end
        address_file_name = if !is_nil(address_location_one), do: Path.basename(file_location_one), else: nil
        kycdirectors = %{
          directors_id: d_id,
          documenttype_id: params["documenttype_id"],
          document_number: params["document_number"],
          issue_date: params["issue_date"],
          country: params["country"],
          expiry_date: params["expiry_date"],
          file_name: file_name,
          file_location: file_location_one,
          file_location_two: file_location_two,
          inserted_by: d_id,
          status: "D",
          type: "I"
        }
        kycdirectorsaddress = %{
          directors_id: d_id,
          address_documenttype_id: params["documenttypeaddress_id"],
          file_name: address_file_name,
          file_location: address_location_one,
          status: "D",
          type: "A"
        }
        id_changeset = Kycdirectors.changeset(%Kycdirectors{}, kycdirectors)
        add_changeset = Kycdirectors.changeset_director_kyc(%Kycdirectors{}, kycdirectorsaddress)
        address_changeset = Addressdirectors.changeset(%Addressdirectors{}, address_map)
        changeset = Directors.changeset_update(directors, director_info)
        changeset_contact = Contactsdirectors.changeset(%Contactsdirectors{}, contactsdirectors)
        if changeset_contact.valid? do
          if changeset.valid? do
            if address_changeset.valid? do
              if id_changeset.valid? do
                if add_changeset.valid? do
                  Repo.insert(changeset_contact)
                  Repo.update(changeset)
                  Repo.insert(address_changeset)
                  Repo.insert(id_changeset)
                  Repo.insert(add_changeset)

                  getotp = Repo.get_by(Kyclogin, directors_id: d_id)
                  # store OTP Code
                  generate_otp = Commontools.randnumber(6)
                  otp_code_map = %{"otp_code" => "#{generate_otp}", "otp_attempt" => 3}
                  otp_code = Poison.encode!(otp_code_map)

                  changeset_otp = %{"otp_code" => otp_code, "steps" => "OTP"}
                  otp = Kyclogin.stepsOTPChangeset(getotp, changeset_otp)
                  Repo.update(otp)

                  data = [
                    %{
                      section: "director_kyc_registration",
                      type: "S",
                      contact_code: "44",
                      contact_number: params["contact_number"],
                      data: %{
                        :otp_code => generate_otp
                      }
                      # Content
                    }
                  ]
                  V2AlertsController.main(data)

                  render(
                    conn,
                    ViolacorpWeb.SuccessView,
                    "success.json",
                    response: %{
                      message: "KYC Done.",
                      steps: changeset_otp["steps"]
                    }
                  )
                else
                  render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: add_changeset)
                end
              else
                render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: id_changeset)
              end
            else
              render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: address_changeset)
            end
          else
            render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        else
          render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: changeset_contact)
        end
      else
        render(conn, ViolacorpWeb.ErrorView, "recordNotFound.json")
      end
    else
      {:error, message} ->
        json conn, %{status_code: "4002", message: message}
      {:invalidMobile, message} ->
        json conn,
             %{
               status_code: "4003",
               errors: %{
                 contact_number: message
               }
             }
      {:addressproof, message} ->
        json conn,
             %{
               status_code: "4003",
               errors: %{
                 address_image_one: message
               }
             }
      {:idproof, message} ->
        json conn,
             %{
               status_code: "4003",
               errors: %{
                 image_one: message
               }
             }
    end
  end

  @doc "verify otp"
  def verifyOtp(conn, params) do
    %{"directors_id" => d_id} = conn.assigns[:current_user]

    case Repo.get_by(Kyclogin, directors_id: d_id) do
      nil -> json conn, %{status_code: "4002", message: "Otp not found"}
      director ->
        otpdecode = Poison.decode!(director.otp_code)
        if otpdecode["otp_code"] == params["otp_code"] do # Compare User given code with db value

          change_step = %{steps: "DONE"}
          changeset_step = Kyclogin.stepsChangeset(director, change_step)
          Repo.update(changeset_step)
          render(
            conn,
            ViolacorpWeb.SuccessView,
            "success.json",
            response: %{
              message: "Mobile Verification Complete.",
              steps: change_step.steps
            }
          )
        else
          json conn, %{status_code: "4002", message: "Incorrect OTP please re-enter or request a new OTP"}
        end
    end
  end



  def resend_otp(conn, _params) do
    %{"directors_id" => d_id} = conn.assigns[:current_user]
    directors_id = d_id
    case Repo.get_by(Kyclogin, directors_id: directors_id) do
      nil -> json conn, %{status_code: "4002", message: "Otp not found"}
      director ->
        generate_otp = Commontools.randnumber(6)
        otp_code_map = %{"otp_code" => "#{generate_otp}", "otp_attempt" => 3}
        new_otp = Poison.encode!(otp_code_map)
        otpmap = %{
          "otp_code" => new_otp,
        }
        changeset_new = Kyclogin.stepsOTPChangeset(director, otpmap)
        Repo.update(changeset_new)


        director_email = Repo.one(from d in Directors, where: d.id == ^directors_id)
        director_contact = Contactsdirectors
                           |> where([t], t.directors_id == ^directors_id and t.status == "A" and t.is_primary == "Y")
                           |> order_by(desc: :inserted_at)
                           |> limit(1)
                           |> Repo.one

        if !is_nil(director_email) and !is_nil(director_contact) do
          data = [
            %{
              section: "resend_registration_otp",
              type: "E",
              email_id: director_email.email_id,
              data: %{
                :otp_code => generate_otp
              }
              # Content
            },
            %{
              section: "resend_registration_otp",
              type: "S",
              contact_code: director_contact.code,
              contact_number: director_contact.contact_number,
              data: %{
                :otp_code => generate_otp
              }
              # Content
            }
          ]
          V2AlertsController.main(data)
        end
        json conn, %{status_code: "200", message: "Successfully reset and sent new otp"}
    end
  end

  @doc "change director contact"
  def changeContact(conn, params) do
    %{"directors_id" => d_id} = conn.assigns[:current_user]

#    dir_info = Repo.one(from d in Directors, where: d.id == ^d_id, limit: 1, select: d)
#    com_info = Repo.one(from c in Commanall, where: c.company_id == ^dir_info.company_id, select: c)

    mobile = case String.first(params["contact_number"]) do
      "0" -> case String.at(params["contact_number"], 1) do
               "7" -> {:ok, "yes"}
               _ -> {:error, "Please enter a valid mobile number"}
             end
      "7" -> {:ok, "yes"}
      _ -> {:error, "Please enter a valid mobile number"}
    end
    contact_data = Repo.one(
      from contact in Contactsdirectors, where: contact.contact_number == ^params["contact_number"],
                                         limit: 1,
                                         select: contact
    )

    check_mobile = if !is_nil(contact_data) do
      {:error, "Mobile number is already registered."}
    else
      {:ok, "yes"}
    end
    with {:ok, _value} <- mobile,
         {:ok, _value} <- check_mobile do
      contact_director = Repo.one(
        from con in Contactsdirectors, where: con.directors_id == ^d_id, limit: 1, select: con
      )
      contact_map = %{"contact_number" => params["contact_number"]}
      changeset_director = Contactsdirectors.changeset(contact_director, contact_map)
      if changeset_director.valid? do
        Repo.update(changeset_director)

        # Otp Store
        otp = Repo.get_by(Kyclogin, directors_id: d_id)
        generate_otp = Commontools.randnumber(6)
        otp_code_map = %{"otp_code" => "#{generate_otp}", "otp_attempt" => 3}
        otp_code = Poison.encode!(otp_code_map)
        otpmap = %{
          "otp_code" => otp_code,
        }
        otp = Kyclogin.updateOTP(otp, otpmap)
        Repo.update(otp)

        data = [
          %{
            section: "director_kyc_registration",
            type: "S",
            contact_code: "44",
            contact_number: params["contact_number"],
            data: %{
              :otp_code => generate_otp
            }
            # Content
          }
        ]
        V2AlertsController.main(data)
        render(
          conn,
          ViolacorpWeb.SuccessView,
          "success.json",
          response: %{
            message: "Success! Contact Updated.",
            steps: "DONE"
          }
        )
      else
        render(conn, ViolacorpWeb.ErrorView, "error.json", changeset: changeset_director)
      end
    else
      {:error, message} -> json conn, %{status_code: "4002", message: message}
    end
  end

#    def reset_password(conn, params) do
##  ON HOLD KK SAID NOT NEEDED
#      otp_mode = Application.get_env(:violacorp, :otp_mode)
#      _response = if otp_mode == "dev" do
#        if !is_nil(params["email_id"]) and params["email_id"] != "" do
#        case Repo.get_by(Kyclogin, username: params["email_id"]) do
#          nil -> json conn, %{status_code: 4002, error: %{message: "user not found"}}
#          found -> changeset = Kyclogin.passwordChangeset(found, %{password: "viola123$ABC"})
#                  Repo.update(changeset)
#                   json conn, %{status_code: 200, data: %{message: "Reset Completed"}}
#        end
#        else
#          json conn, %{status_code: 4002, error: %{message: "please send email_id"}}
#        end
#        else
#          json conn, %{status_code: 4002, error: %{message: "Unauthorized request"}}
#      end
#    end

end
