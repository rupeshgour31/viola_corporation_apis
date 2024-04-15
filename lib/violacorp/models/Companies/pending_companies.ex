defmodule Violacorp.Models.Companies.PendingCompanies do
  alias Violacorp.Repo
  import Ecto.Query
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Company
  #  alias Violacorp.Schemas.Countries
  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Intilaze
  alias Violacorp.Schemas.Administratorusers
  alias Violacorp.Schemas.Companydocumentinfo
  alias Violacorp.Schemas.Shareholder
  alias Violacorp.Schemas.Kycshareholder
  alias Violacorp.Schemas.Contactsdirectors
  alias Violacorp.Schemas.Kycdocuments
  alias Violacorp.Schemas.Kycdirectors
  alias Violacorp.Schemas.Kycopinion
  alias Violacorp.Schemas.Documenttype
  alias Violacorp.Schemas.Documentcategory
  alias Violacorp.Schemas.Fourstop
  alias Violacorp.Schemas.Kyclogin
  alias Violacorp.Schemas.Contacts
  alias Violacorp.Schemas.Commankyccomments
  alias Violacorp.Schemas.Devicedetails
  alias Violacorp.Schemas.Notifications
  alias Violacorp.Schemas.Mandate
  alias Violacorp.Schemas.Permissions
  alias Violacorp.Schemas.Departments
  alias Violacorp.Schemas.Otp
  alias Violacorp.Schemas.Kyccomments
  alias Violacorp.Schemas.Countries
  alias Violacorp.Schemas.Thirdpartylogs
  alias Violacorp.Schemas.Loginhistory

  alias Violacorp.Libraries.Commontools
  #  alias Violacorp.Models.Comman
  alias Violacorp.Schemas.Address
  alias Violacorp.Schemas.Addressdirectors


  defp check_value(params) do
    cond do
      params["image_one"] == "" and params["documentcategory_id"] == "" and params["documenttype_id"] == "" ->
        {:errors, %{image: ["can't be blank"], documenttype: ["can't be blank"], documentcategory: ["can't be blank"]}}
      #      params["image_two"] == "" -> {:errors, %{image: ["can't be blank"]}}
      params["documenttype_id"] == "" ->
        {:errors, %{documenttype: ["can't be blank"]}}
      params["documentcategory_id"] == "" ->
        {:errors, %{documentcategory: ["can't be blank"]}}
      params["image_base64"] != "" and params["documenttype_id"] != "" ->
        {:ok, "ok"}
    end
  end
  defp check_value_kyb(params) do
    cond do
      params["image_one"] == "" and params["documenttype_id"] == "" ->
        {:errors, %{image: ["can't be blank"], documenttype: ["can't be blank"]}}
      params["image_one"] == "" ->
        {:errors, %{image: ["can't be blank"]}}
      params["documenttype_id"] == "" or params["documenttype_id"] == nil ->
        {:errors, %{documenttype: ["can't be blank"]}}
      params["image_one"] != "" and params["documenttype_id"] != "" ->
        {:ok, "ok"}
    end
  end

  defp check_existing_email(params)do
    check = Repo.one(from k in Kyclogin, where: k.username == ^params["email_id"], limit: 1, select: k)
    check_email = Repo.one(from com in Directors, where: com.email_id == ^params["email_id"], limit: 1, select: com)
    check_coman = Repo.one(from co in Commanall, where: co.email_id == ^params["email_id"], limit: 1, select: co)

    if !is_nil(check_email) or !is_nil(check) or !is_nil(check_coman) do
      "N"
    else
      "Y"
    end
  end

  def getSingleShareholderInfo(params)do
    shareholder_id = params["company_id"]
    data = (
             from sh in Shareholder,
                  where: sh.company_id == ^shareholder_id,
                  select: %{
                    id: sh.id,
                    company_id: sh.company_id,
                    fullname: sh.fullname,
                    dob: sh.dob,
                    address: sh.address,
                    percentage: sh.percentage,
                    type: sh.type,
                    status: sh.status
                  })
           |> Repo.all
    _map = Enum.map(
      data,
      fn (x) ->
        id = x[:id]
        id_proof = Repo.all(
          from ky in Shareholder, where: ky.id == ^id,
                                  left_join: a in assoc(ky, :kycshareholder),
                                  where: a.type == ^"I",
                                  left_join: d in assoc(a, :documenttype),
                                  select: %{
                                    shareholder_id: a.shareholder_id,
                                    title: d.title,
                                    document_number: a.document_number,
                                    issue_date: a.issue_date,
                                    expiry_date: a.expiry_date,
                                    type: a.type,
                                    status: a.status,
                                    inserted_at: ky.inserted_at
                                  }
        )

        address = Repo.all(
          from k in Shareholder, where: k.id == ^id,
                                 left_join: aa in assoc(k, :kycshareholder),
                                 where: aa.type == ^"A",
                                 left_join: d in assoc(aa, :documenttype),
                                 select: %{
                                   shareholder_id: aa.shareholder_id,
                                   title: d.title,
                                   document_number: aa.document_number,
                                   issue_date: aa.issue_date,
                                   expiry_date: aa.expiry_date,
                                   type: aa.type,
                                   status: aa.status,
                                   inserted_at: aa.inserted_at
                                 }
        )
        company_kyb = Repo.all(
          from k in Shareholder, where: k.id == ^id,
                                 left_join: a in assoc(k, :kycshareholder),
                                 where: a.type == ^"C",
                                 left_join: d in assoc(a, :documenttype),
                                 select: %{
                                   shareholder_id: a.shareholder_id,
                                   title: d.title,
                                   document_number: a.document_number,
                                   country: a.country,
                                   issue_date: a.issue_date,
                                   expiry_date: a.expiry_date,
                                   type: a.type,
                                   status: a.status,
                                   inserted_at: a.inserted_at
                                 }
        )
        _response = %{
          shareholder_info: %{
            id: x.id,
            company_id: x.company_id,
            fullname: x.fullname,
            dob: x.dob,
            address: x.address,
            percentage: x.percentage,
            type: x.type,
            status: x.status
          },
          kyc: %{
            address: address,
            id: id_proof
          },
          company_kyb: company_kyb
        }
      end
    )
  end

  @doc""

  def getShareHolderKyc(params)do
    id = (
           from k in Shareholder,
                where: k.company_id == ^params["company_id"],
                left_join: a in assoc(k, :kycshareholder),
                where: a.type == ^"I",
                left_join: d in assoc(a, :documenttype),
                select: %{
                  shareholder_id: a.shareholder_id,
                  title: d.title,
                  document_number: a.document_number,
                  issue_date: a.issue_date,
                  expiry_date: a.expiry_date,
                  type: a.type,
                  status: a.status,
                  inserted_at: k.inserted_at

                })
         |> Repo.all
    address = (
                from k in Shareholder,
                     where: k.company_id == ^params["company_id"],
                     left_join: a in assoc(k, :kycshareholder),
                     where: a.type == ^"A",
                     left_join: d in assoc(a, :documenttype),
                     select: %{
                       shareholder_id: a.shareholder_id,
                       title: d.title,
                       document_number: a.document_number,
                       issue_date: a.issue_date,
                       expiry_date: a.expiry_date,
                       type: a.type,
                       status: a.status,
                       inserted_at: k.inserted_at

                     })
              |> Repo.all
    compay_kyb = (
                   from k in Shareholder,
                        where: k.company_id == ^params["company_id"],
                        left_join: a in assoc(k, :kycshareholder),
                        where: a.type == ^"A",
                        left_join: d in assoc(a, :documenttype),
                        select: %{
                          shareholder_id: a.shareholder_id,
                          title: d.title,
                          document_number: a.document_number,
                          issue_date: a.issue_date,
                          expiry_date: a.expiry_date,
                          type: a.type,
                          status: a.status,
                          inserted_at: k.inserted_at

                        })
                 |> Repo.all
    _map = %{id: id, address: address, company_kyb: compay_kyb}
  end


  @doc"add director"
  def addDirectorForCompany(params, admin_id) do
    country_code = Application.get_env(:violacorp, :country_code)

    check_kyc_email = check_existing_email(params)

    case check_kyc_email do
      "Y" ->
        chk_contact = Repo.one(
          from cd in Contactsdirectors, where: cd.contact_number == ^params["contact_number"], limit: 1, select: cd
        )
        if is_nil(chk_contact) do
          count = Repo.one(from a in Directors, where: a.company_id == ^params["company_id"], select: count(a.id))
          director_number = count + 1

          comp_type = Repo.one(from c in Company, where: c.id == ^params["company_id"], select: c.company_type)

          result = case comp_type do
            "STR" ->
              case params["position"] do
                "cap" -> "ok"
                "owner" -> "ok"
                _ -> {:position_message, "position not allowed for this company type"}
              end
            "LTD" ->
              case params["position"] do
                "cap" -> "ok"
                "director" -> "ok"
                _ -> {:position_message, "position not allowed for this company type"}
              end
          end
          case result do
            "ok" ->

              password = Commontools.generate_password()

              addressdirectors = %{
                addressdirectors: %{
                  address_line_one: Commontools.capitalize(params["address_line_one"]),
                  address_line_two: Commontools.capitalize(params["address_line_two"]),
                  address_line_three: Commontools.capitalize(params["address_line_three"]),
                  post_code: params["post_code"],
                  town: params["town"],
                  inserted_by: "99999#{admin_id}",
                  countries_id: params["countries_id"]
                }
              }

              contactsdirectors = %{
                contactsdirectors: %{
                  contact_number: params["contact_number"],
                  code: country_code,
                  inserted_by: "99999#{admin_id}"
                }
              }

              kyclogin = %{
                kyclogin: %{
                  username: params["email_id"],
                  password: password,
                  inserted_by: "99999#{admin_id}",
                  directors_company_id: params["company_id"]
                }
              }

              director = %{
                company_id: params["company_id"],
                position: params["position"],
                title: params["title"],
                first_name: params["first_name"],
                middle_name: params["middle_name"],
                last_name: params["last_name"],
                date_of_birth: params["date_of_birth"],
                gender: params["gender"],
                email_id: params["email_id"],
                signature: params["signature"],
                sequence: director_number,
                verify_kyc: "pending",
                inserted_by: "99999#{admin_id}",
                addressdirectors: addressdirectors,
                contactsdirectors: contactsdirectors,
                kyclogin: kyclogin
              }
              changeset = Directors.changeset_contact(%Directors{}, director)

              case Repo.insert(changeset)do
                {:ok, _data} -> {:ok, "Director Inserted Successfully"}
                {:error, data} -> {:error, data}
              end
            {:position_message, pos_type} -> {:position_message, pos_type}
          end
        else
          {:exist_contact, "already someone used."}
        end
      "N" ->
        {:exist_email, "already someone used."}
    end
  end

  @doc" List of Documents Available to upload for company KYC"

  def companyKybDocumentTypeList(params)do
    company_type = Repo.one(from c in Company, where: c.id == ^params["company_id"], select: c.company_type)
    case company_type do
      nil -> {:error, "No Record Found"}
      _ ->
        type = if company_type == "STR" do
          "SOL"
        else
          company_type
        end
        category_id = Repo.one(from cat in Documentcategory, where: cat.code == ^type, select: cat.id)

        case category_id do
          nil -> {:error, "Company Category type Not Found"}
          _ ->
            list = Repo.all(
              from a in Documenttype,
              where: a.documentcategory_id == ^category_id,
              select: %{
                id: a.id,
                title: a.title
              }
            )
            case list do
              [] -> {:error, "Company Category Not Found"}
              _ -> {:ok, list}
            end
        end
    end
  end
  @doc""
  def employeeKycDocumentUploadID(params, admin_id)do
    changeset = Kycdocuments.changesetIDProof(%Kycdocuments{}, params)
    if changeset.valid? do
      commanall_id = Repo.one(from a in Commanall, where: a.employee_id == ^params["employee_id"], select: a.id)
      existing = Repo.one(
        from a in Kycdocuments,
        where: a.commanall_id == ^commanall_id and a.documenttype_id == ^params["documenttype_id"] and a.status == "A" and a.type == "I",
        order_by: [desc: a.id],
        limit: 1,
        select: a.id
      )
      case existing do
        nil ->
          uploadEmployeeID(params, admin_id, commanall_id)
        _ ->
          deactivateEmployeeKyc(existing)
          uploadEmployeeID(params, admin_id, commanall_id)
      end
    else
      {:error, changeset}
    end
  end

  @doc""
  def employeeKycDocumentUploadAddress(params, admin_id)do
    changeset = Kycdocuments.changesetAddressProof(%Kycdocuments{}, params)
    if changeset.valid? do
      commanall_id = Repo.one(from a in Commanall, where: a.employee_id == ^params["employee_id"], select: a.id)
      existing = Repo.one(
        from a in Kycdocuments,
        where: a.commanall_id == ^commanall_id and a.documenttype_id == ^params["documenttype_id"] and a.status == "A" and a.type == "A",
        order_by: [desc: a.id],
        limit: 1,
        select: a.id
      )
      case existing do
        nil ->
          uploadEmployeeAddress(params, admin_id, commanall_id)
        _ ->
          deactivateEmployeeKyc(existing)
          uploadEmployeeAddress(params, admin_id, commanall_id)
      end
    else
      {:error, changeset}
    end
  end

  defp uploadEmployeeAddress(params, admin_id, commanall_id)do

    image_base64 = "#{params["image_one"]}"
    s3_url = ViolacorpWeb.Main.Assetstore.upload_image(image_base64)

    data = %{
      commanall_id: commanall_id,
      documenttype_id: params["documenttype_id"],
      document_number: params["document_number"],
      file_name: List.last(Regex.split(~r{/}, s3_url)),
      file_type: List.last(Regex.split(~r{\.}, s3_url)),
      file_location: s3_url,
      status: "D",
      type: "A",
      inserted_by: admin_id
    }

    changeset = Kycdocuments.changesetAddressProof(%Kycdocuments{}, data)
    case Repo.insert(changeset) do
      {:ok, _data} -> {:ok, "Employee Address Kyc Document Added Successfully"}
      {:error, changeset} -> {:error, changeset}
    end



  end


  defp deactivateEmployeeKyc(id)do
    record = Repo.get_by(Kycdocuments, id: id)
    deactivate = %{
      status: "D"
    }
    changeset = Kycdocuments.update_status(record, deactivate)
    Repo.update(changeset)
  end

  defp uploadEmployeeID(params, admin_id, commanall_id)do
    image_base64 = "#{params["image_one"]}"
    image2 = "#{params["image_two"]}"
    s3_url = ViolacorpWeb.Main.Assetstore.upload_image(image_base64)
    s3_url2 = if image2 !== "" do
      ViolacorpWeb.Main.Assetstore.upload_image(image2)
    else
      nil
    end
    request_id = "99999#{admin_id}"
    adminId = String.to_integer(request_id)
    data = %{
      commanall_id: commanall_id,
      documenttype_id: params["documenttype_id"],
      document_number: params["document_number"],
      issue_date: params["issue_date"],
      expiry_date: params["expiry_date"],
      country: params["country"],
      file_name: List.last(Regex.split(~r{/}, s3_url)),
      file_type: List.last(Regex.split(~r{\.}, s3_url)),
      file_location: s3_url,
      file_location_two: s3_url2,
      status: "D",
      type: "I",
      inserted_by: adminId
    }
    changeset = Kycdocuments.changesetIDProof(%Kycdocuments{}, data)
    case Repo.insert(changeset) do
      {:ok, _data} -> {:ok, "Employee ID Kyc Document Added Successfully"}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc""
  def shareholderKycDocumentUpload(params, admin_id) do

    shareholder_type = params["shareholder_type"]
    documentcategory_id = params["documentcategory_id"]
    documenttype_id = params["documenttype_id"]
    shareholder_id = params["shareholder_id"]

    type = if shareholder_type == "PERSON" do
      case documentcategory_id do
        1 -> "A"
        2 -> "I"
      end
    else
      "C"
    end

    existing = Repo.one(
      from a in Kycshareholder,
      where: a.shareholder_id == ^shareholder_id and a.documenttype_id == ^documenttype_id and a.status == "A" and a.type == ^type,
      select: a.id
    )

    case existing do
      nil -> uploadShareholderKyc(params, type, admin_id)

      _ -> {:ok, "DOCUMENTS ALREADY UPLOADED AND ARE PENDING OR APPROVED"}
    end

  end

  defp uploadShareholderKyc(params, type, admin_id)do

    s3_url = ViolacorpWeb.Main.Assetstore.upload_image(params["image_one"])
    request_id = "99999#{admin_id}"
    adminId = String.to_integer(request_id)
    data = %{
      shareholder_id: params["shareholder_id"],
      documenttype_id: params["documenttype_id"],
      document_number: params["document_number"],
      issue_date: params["issue_date"],
      expiry_date: params["expiry_date"],
      country: params["country"],
      file_name: List.last(Regex.split(~r{/}, s3_url)),
      file_type: List.last(Regex.split(~r{\.}, s3_url)),
      file_location: s3_url,
      type: type,
      status: "A",
      inserted_by: adminId
    }
    changeset = case type do
      "A" -> Kycshareholder.changesetAddress(%Kycshareholder{}, data)
      "I" -> Kycshareholder.changesetIdProof(%Kycshareholder{}, data)
      "C" -> Kycshareholder.changesetCompany(%Kycshareholder{}, data)
    end
    case Repo.insert(changeset) do
      {:ok, _data} -> {:ok, "Shareholder Kyc Document Added Successfully"}
      {:error, changeset} -> {:error, changeset}
    end

  end

  @doc""
  def directorKycDocumentUpload(params, admin_id)do
    documentcategory_id = params["documentcategory_id"]
    _documenttype_id = params["documenttype_id"]
    director_id = params["director_id"]
    case check_value(params) do
      {:ok, "ok"} ->
        type = case documentcategory_id do
          1 -> "A"
          2 -> "I"
        end

        existing = Repo.one(
          from a in Kycdirectors,
          where: a.directors_id == ^director_id and a.type == ^type, limit: 1, select: a.id
        )
        case existing do
          nil -> uploadDirectorKyc(params, admin_id, type)
          _ ->
            deactivateDirectorKyc(director_id, type)
            uploadDirectorKyc(params, admin_id, type)
        end
      {:errors, message} -> {:errors, message}
    end
  end

  defp uploadDirectorKyc(params, admin_id, type)do
    image_base64 = "#{params["image_one"]}"
    image2 = "#{params["image_two"]}"

    s3_url = ViolacorpWeb.Main.Assetstore.upload_image(image_base64)
    s3_url2 = if image2 !== "" do
      ViolacorpWeb.Main.Assetstore.upload_image(image2)
    else
      nil
    end
    request_id = "99999#{admin_id}"
    adminId = String.to_integer(request_id)

    data = %{
      directors_id: params["director_id"],
      documenttype_id: params["documenttype_id"],
      document_number: params["document_number"],
      expiry_date: params["expiry_date"],
      issue_date: params["issue_date"],
      country: params["country"],
      file_name: List.last(Regex.split(~r{/}, s3_url)),
      file_type: List.last(Regex.split(~r{\.}, s3_url)),
      file_location: s3_url,
      file_location_two: s3_url2,
      type: type,
      status: "D",
      inserted_by: adminId,
    }
    changeset = case type do
      "A" -> Kycdirectors.changeset_upload_kyc(%Kycdirectors{}, data)
      "I" -> Kycdirectors.changesetUploadIdProof(%Kycdirectors{}, data)
    end
    #            changeset = Kycdirectors.changeset_upload_kyc(%Kycdirectors{}, data)
    if changeset.valid? do

      #              _result = case type do
      #                          "A" ->
      #                              check_id = Repo.all(from k in Kycdirectors, where: k.directors_id == ^params["director_id"] and k.type == "I", select: k.id)
      #                              if check_id != [], do: "N", else: "Y"
      #                          "I" ->
      #                              check_ad = Repo.all(from k in Kycdirectors, where: k.directors_id == ^params["director_id"] and k.type == "A", select: k.id)
      #                              if check_ad != [], do: "N", else: "Y"
      #                        end

      #              case result do
      #                "Y" ->
      case Repo.insert(changeset) do
        {:ok, _data} ->
          ky_data = Repo.get_by(Kyclogin, directors_id: params["director_id"])
          if !is_nil(ky_data) do
            kyclogin = Kyclogin.stepsChangeset(ky_data, %{steps: "DONE"})
            Repo.update(kyclogin)
          end
          {:ok, "Kyc Document Added Successfully"}
        {:error, changeset} -> {:error, changeset}
      end
      #                "N" ->
      #                      case Repo.insert(changeset) do
      #                        {:ok, _data} -> {:ok, "Kyc Document Added Successfully"}
      #                        {:error, changeset} -> {:error, changeset}
      #                      end
      #              end
    else
      {:error, changeset}
    end
  end

  defp deactivateDirectorKyc(director_id, type)do
    existingKycFirst = Repo.all(from k in Kycdirectors, where: k.directors_id == ^director_id and k.type == ^type)
    if existingKycFirst do
      from(d in Kycdirectors, where: d.directors_id == ^director_id and d.type == ^type)
      |> Repo.update_all(
           set: [
             status: "R"
           ]
         )
    end
  end


  @doc""
  def companyKybDocumentUpload(params, admin_id)do
    documenttype_id = params["documenttype_id"]
    commanall_id = params["commanall_id"]
    map = %{
      documenttype_id: params["documenttype_id"],
      commanall_id: params["commanall_id"],
      file_location: params["image_one"]
    }
    changeset = Kycdocuments.changeset_upload_kyb(%Kycdocuments{}, map)
    if changeset.valid? do
      case check_value_kyb(params) do
        {:ok, "ok"} ->
          existing = Repo.all(
            from a in Kycdocuments,
            where: a.commanall_id == ^commanall_id and a.documenttype_id == ^documenttype_id and (
              a.status == "A" or a.status == "P")
          )
          case existing do
            [] ->
              image_base64 = "#{params["image_one"]}"
              s3_url = ViolacorpWeb.Main.Assetstore.upload_image(image_base64)
              request_id = "99999#{admin_id}"
              adminId = String.to_integer(request_id)
              data = %{
                commanall_id: commanall_id,
                documenttype_id: documenttype_id,
                file_location: s3_url,
                type: "C",
                status: "D",
                inserted_by: adminId,
              }
              changeset = Kycdocuments.changeset_upload_kyb(%Kycdocuments{}, data)
              case Repo.insert(changeset) do
                {:ok, _data} -> {:ok, "Kyb Document Added Successfully"}
                {:error, changeset} -> {:error, changeset}
              end
            _ -> {:exists, "Document Already Exists"}
          end
        {:errors, message} -> {:errors, message}
      end
    else
      {:error, changeset}
    end
  end

  @doc""

  def companyActivationOpinionAdd(params, admin_id)do
    #    request_id = "99999#{admin_id}"
    #    adminId = String.to_integer(request_id)
    insert = %{
      status: params["status"],
      description: params["description"],
      signature: params["signature"],
      commanall_id: params["commanall_id"],
      inserted_by: admin_id,
    }
    changeset = Kycopinion.changeset(%Kycopinion{}, insert)
    case Repo.insert(changeset) do
      {:ok, _data} -> {:ok, "Kyc Opinion Added Successfully"}
      {:error, changeset} -> {:error, changeset}
    end
  end


  @doc""
  @moduledoc false

  def pendingCompanyCheckList(params)do

    data = (
             from a in Commanall,
                  where: a.company_id == ^params["company_id"] and a.status == "P",
                  select: %{
                    commanall_id: a.id,
                    company_id: a.company_id
                  })
           |> Repo.one
    case data do
      [] -> {:error, "No Record Found"}
      #%{status_code: "4004", message: "No Record Found"}
      nil -> {:error, "No Record Found"}
      #%{status_code: "4004", message: "No Record Found"}
      data ->

        type1 = Repo.one(from c in Company, where: c.id == ^data.company_id, select: c.company_type)
        type = if type1 == "STR" do
          "SOL"
        else
          "LTD"
        end

        #gets list of document required
        category_id = Repo.one(from category in Documentcategory, where: category.code == ^type, select: category.id)
        documents = Repo.all(
          from docs in Documenttype, where: docs.documentcategory_id == ^category_id,
                                     select: %{
                                       id: docs.id,
                                       title: docs.title
                                     }
        )

        #Check if documents exist and create a check list with available and missing documents
        matchDocs = Enum.reduce(
          documents,
          [],
          fn (v, empty_list) ->
            listing = Repo.one(
              from d in Kycdocuments, where: d.commanall_id == ^data.commanall_id and d.documenttype_id == ^v.id,
                                      select: count(d.id)
            )
            check = if listing == 0 do
              "NO"
            else
              "YES"
            end
            empty_list ++ [%{title: "#{v.title}", value: check}]
          end
        )
        checkList = if type == "LTD" do
          ltdCompanyCheck(matchDocs, params["company_id"])
        else
          matchDocs
        end
        {:ok, checkList}
    end
  end

  defp ltdCompanyCheck(checklist, company_id)do
    #    #Check Directors KYC
    companyDirectors = Repo.all(from dir in Directors, where: dir.company_id == ^company_id, select: dir.id)
    matchDirectors = Enum.reduce(
      companyDirectors,
      [],
      fn (v, empty_list) ->
        listing = Repo.one(
          from kycd in Kycdirectors, where: kycd.directors_id == ^v and kycd.type == ^"I",
                                     select: count(kycd.id)
        )
        check = if listing == 0 do
          "Missing"
        else
          "Available"
        end
        empty_list ++ [check]
      end
    )
    # Add Director ID Check to Checklist
    kycAvailableDirectors = if matchDirectors !== [] do
      if Enum.member?(matchDirectors, "Available") == true do
        [
          %{
            "title" => "Proof of Identity for at least 1 Director",
            "value" => "YES"
          }
        ]
      else
        [
          %{
            "title" => "Proof of Identity for at least 1 Director",
            "value" => "NO"
          }
        ]
      end
    end

    #    #Checks if shareholders all have ID Proof and Address Proof
    shareholder = Repo.all(
      from s in Shareholder, where: s.company_id == ^company_id and (s.percentage == 25 or s.percentage > 25),
                             select: %{
                               id: s.id
                             }
    )

    shareholders = if !is_nil(shareholder) or shareholder !== [] do
      Enum.reduce(
        shareholder,
        [],
        fn (v, empty_list) ->

          idProof = Repo.one(
            from kycid in Kycshareholder,
            where: kycid.shareholder_id == ^v.id and kycid.type == ^"I" and kycid.status == "A", select: count(kycid.id)
          )
          addressProof = Repo.one(
            from kycadd in Kycshareholder,
            where: kycadd.shareholder_id == ^v.id and kycadd.type == ^"A" and kycadd.status == "A",
            select: count(kycadd.id)
          )

          checkdocs = if idProof > 0 and addressProof > 0 do
            "available"
          else
            "missing"
          end
          empty_list ++ [checkdocs]
        end
      )
    else
      []
    end

    #    # Add Shareholder Check to Check List
    shares = if shareholders !== [] do
      if Enum.member?(shareholders, "missing") == false do
        [
          %{
            "title" =>
              "Proof of Identity and Proof of Address Documentation for Shareholders/UBOs owning 25% or more of the business",
            "value" => "YES"
          }
        ]
      else
        [
          %{
            "title" =>
              "Proof of Identity and Proof of Address Documentation for Shareholders/UBOs owning 25% or more of the business",
            "value" => "NO"
          }
        ]
      end
    else
      []
    end
    checklistAddDirector = checklist ++ kycAvailableDirectors
    _finalChecklist = checklistAddDirector ++ shares

  end

  @doc" Model Of List of Pending Companies"
  def pendingCompanyAskMoreDetails(params, admin_id) do

    #    request_id = "99999#{admin_id}"
    #    adminId = String.to_integer(request_id)
    #    all = Repo.all(Companydocumentinfo)
    company_all = (from a in Companydocumentinfo, where: a.company_id == ^params["company_id"])
                  |> Repo.all
    insert = %{
      company_id: params["company_id"],
      contant: params["contant"],
      inserted_by: admin_id
    }

    changeset = Companydocumentinfo.changeset(%Companydocumentinfo{}, insert)

    case Repo.insert(changeset) do
      {:ok, _changeset} ->
        _status = Enum.each company_all, fn x ->
          record = Repo.get_by(Companydocumentinfo, id: x.id)
          update = %{
            status: "D"
          }
          changeset = Companydocumentinfo.changeset(record, update)
          Repo.update(changeset)
        end
        {:ok, "Successfully Inserted Details"}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc" Model Of List of Pending Companies"
  def pending_companies(params) do
    filtered = params
               |> Map.take(~w( username email_id status))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
    company_name = params["company_name"]
    company_type = params["company_type"]
    company_list = cond do
      params["added_by"] == "admin" ->
        Commanall |> join(:left, [a], b in assoc(a, :company)) |> where([a], a.status not in ["A", "D", "B", "U", "R"] and like(a.inserted_by, ^"%#{99999}%"))
      params["added_by"] == "user" ->
        Commanall |> join(:left, [a], b in assoc(a, :company)) |> where([a], not like(a.inserted_by, ^"%#{99999}%") or is_nil(a.inserted_by))
      !is_nil(company_name) and !is_nil(company_type) ->
        Commanall |> join(:left, [a], b in assoc(a, :company)) |> where([a,b], like(b.company_name, ^"%#{company_name}%") and like(b.company_type, ^"%#{company_type}%"))
      !is_nil(company_name) and is_nil(company_type) ->
        Commanall |> join(:left, [a], b in assoc(a, :company)) |> where([a,b], like(b.company_name, ^"%#{company_name}%"))
      is_nil(company_name) and !is_nil(company_type) ->
        Commanall |> join(:left, [a], b in assoc(a, :company))|> where([a,b], like(b.company_type, ^"%#{company_type}%"))
      true ->
        Commanall |> join(:left, [a], b in assoc(a, :company))
    end

    company_list
    |> having(^filtered)
    |> where([a], a.status not in ["A", "D", "B", "U", "R"] and  not is_nil(a.company_id))
    |> select(
         [a, b],
         %{
           commanall_id: a.id,
           username: a.username,
           company_id: b.id,
           email_id: a.email_id,
           company_name: b.company_name,
           contact_number: "n/a",
           company_type: b.company_type,
           date_added: a.inserted_at,
           status: a.status
         }
       )
    |> order_by(desc: :id)
    |> Repo.paginate(params)
  end
  #  @doc" Model for  profile of Pending Companies"
  #  def companyProfile(params) do
  #    Repo.all(
  #      from a in Commanall, where: a.company_id == ^params["company_id"] and a.status == "P",
  #                           left_join: b in assoc(a, :company),
  #                           inner_join: d in assoc(b, :directors),
  #                           inner_join: e in assoc(d, :contactsdirectors),
  #                           inner_join: add in assoc(d, :addressdirectors),
  #                           select: %{
  #                             email: a.email_id,
  #                             commanll_id: a.id,
  #                             status: a.status,
  #                             company_name: b.company_name,
  #                             company_type: b.company_type,
  #                             date_added: a.inserted_at,
  #                             directors_id: d.id,
  #                             director_first_name: d.first_name,
  #                             director_last_name: d.last_name,
  #                             director_dob: d.date_of_birth,
  #                             director_position: d.position,
  #                             directors_contact_no: e.contact_number,
  #                             director_add1: add.address_line_one,
  #                             director_add2: add.address_line_two,
  #                             post_code: add.post_code
  #                           }
  #    )
  #  end

  @doc "model for pending company profile "
  def pending_getOne_company(params) do
    data = Repo.one(
      from a in Commanall, where: a.company_id == ^params["company_id"],
                           left_join: b in assoc(a, :company),
                           left_join: c in assoc(b, :countries),
                           left_join: co in assoc(a, :contacts),
                           where: (a.status == "P" or a.status == "I"),
                           limit: 1,
                           select: %{
                             landline_number: b.landline_number,
                             commanall_id: a.id,
                             username: a.username,
                             company_id: a.company_id,
                             accomplish_userid: a.accomplish_userid,
                             company_name: b.company_name,
                             registration_number: b.registration_number,
                             email: a.email_id,
                             company_type: b.company_type,
                             registration_date: b.date_of_registration,
                             company_url: b.company_website,
                             telephone: co.contact_number,
                             country: c.country_name,
                             status: a.status,
                             reg_step: a.reg_step,
                             registration_step: a.step,
                             inserted_at: a.inserted_at,
                           }
    )
    director = Repo.one(
      from d in Directors, where: d.company_id == ^params["company_id"] and d.sequence == 1, select: d, limit: 1
    )
    merge = if !is_nil(director) && !is_nil(data) do
      position = String.downcase(director.position)
      step = cond do
        data.reg_step == "1" ->
          %{registration_step: "Email Verification"}
        data.reg_step == "11" ->
          %{registration_step: "Mobile Verification"}
        data.reg_step == "12" ->
          %{registration_step: "Vpin"}
        data.reg_step == "2" ->
          %{registration_step: "Business Details"}
        data.reg_step == "6" ->
          %{registration_step: "Done"}
        data.reg_step == "3" ->
          case position do
            "owner" -> %{registration_step: "Owner Details"}
            "cap" -> %{registration_step: "CAP Details"}
            "director" -> %{registration_step: "Director Details"}
            "significant" -> %{registration_step: "significant Details"}
          end
        data.reg_step == "4" ->
          case data.company_type do
            "STR" ->
              case position do
                "owner" -> %{registration_step: "Owner Details"}
                "cap" -> %{registration_step: "CAP Details"}
                "director" -> %{registration_step: "Director Details"}
              end
            "LTD" ->
              case position do
                "director" -> %{registration_step: "Director Details"}
                "cap" -> %{registration_step: "CAP Details"}
                "significant" -> %{registration_step: "Significant Person"}
              end
          end
        data.reg_step == "42" ->
          case data.company_type do
            "STR" ->
              case position do
                "owner" -> %{registration_step: "Owner Details"}
                "cap" -> %{registration_step: "CAP Details"}
                "director" -> %{registration_step: "Director Details"}
              end
            "LTD" ->
              case position do
                "director" -> %{registration_step: "Director Details"}
                "cap" -> %{registration_step: "CAP Details"}
                "significant" -> %{registration_step: "Significant Person"}
              end
          end
        data.reg_step == "IDINFO" or data.reg_step == "IDDOC1" or data.reg_step == "IDDOC2" ->
          %{registration_step: "Upload ID Proof"}
        data.reg_step == "ADINFO" or data.reg_step == "ADDOC1" ->
          %{registration_step: "Upload Address Proof"}
        data.reg_step >= "42" or data.reg_step <= "62" ->
          case data.company_type do
            "STR" ->
              case position do
                "owner" -> %{registration_step: "Owner Details"}
                "cap" -> %{registration_step: "CAP Details"}
                "director" -> %{registration_step: "Director Details"}
              end
            "LTD" ->
              case position do
                "director" -> %{registration_step: "Director Details"}
                "cap" -> %{registration_step: "CAP Details"}
                "significant" -> %{registration_step: "Significant Person"}
              end
          end
        true ->
          %{registration_step: "Done"}
      end
      Map.merge(data, step)
    else
      data
    end

    if !is_nil(data) do
      check = Repo.one(
        from i in Intilaze, where: i.commanall_id == ^data.commanall_id,
                            left_join: c in assoc(i, :commanall),
                            left_join: ad in assoc(i, :administratorusers),
                            select: %{
                              feedetail: i.feedetail,
                              role: ad.role,
                              unique_id: ad.unique_id,
                              Initialised_by: ad.fullname,
                              comment: i.comment,
                              inserted_at: i.inserted_at
                            }
      )
      is_authorized = checkCompanyApprovalAuthorize(data.commanall_id, params["company_id"])
      is_initilize = if !is_nil(check), do: "Yes", else: "No"
      map1 = %{
        initilize: is_initilize,
        initilize_detail: check,
        is_authorized: is_authorized,
        thirdpartysteps: thirdpartylogs(data.commanall_id)
      }
      _data = Map.merge(map1, merge)
    else
      data
    end
  end

  def get_all_directors_for_company(_params) do
    #    #director_list =
    #    Repo.all(
    #      from d in Directors, where: d.company_id == ^params["company_id"],
    #                           inner_join: c in assoc(d, :contactsdirectors),
    #                           inner_join: add in assoc(d, :addressdirectors),
    #                           inner_join: e in assoc(d, :contactsdirectors),
    #                           select: %{
    #                             directors_id: d.id,
    #                             title: d.title,
    #                             first_name: d.first_name,
    #                             last_name: d.last_name,
    #                             dob: d.date_of_birth,
    #                             email_id: d.email_id,
    #                             director_position: d.position,
    #                             directors_contact_no: e.contact_number,
    #                             director_add1: add.address_line_one,
    #                             director_add2: add.address_line_two,
    #                             post_code: add.post_code
    #                           }
    #    )
  end
  #
  def get_kyc_one_company(_params) do
    #    Repo.all(
    #      from c in Commanall, where: c.company_id == ^params["company_id"],
    #                              inner_join: k in assoc(c, :kycdocuments),
    #                              inner_join: dt in assoc(k, :documenttype),
    #                              inner_join: dc in assoc(dt, :documentcategory),
    #                              select: %{
    #                                company_id: c.company_id,
    #                                document_category: dc.title,
    #                                document_type: dt.title,
    #                                document_number: k.document_number,
    #                                expiry_date: k.expiry_date,
    #                                issue_date: k.issue_date,
    #                                date_added: k.inserted_at,
    #                                status: k.status
    #                              }
    #    )
  end

  def getCompanyAddress(params) do
    Repo.one(
      from c in Commanall,
      left_join: a in assoc(c, :address),
      on: a.is_primary == "Y",
      where: c.company_id == ^params["company_id"],
      limit: 1,
      select: %{
        id: a.id,
        address_line_one: a.address_line_one,
        address_line_two: a.address_line_two,
        address_line_three: a.address_line_three,
        city: a.city,
        town: a.town,
        county: a.county,
        post_code: a.post_code
      }
    )
  end


  def get_directors_kyc_company(params) do

    count = (
              from a in Directors,
                   order_by: [
                     asc: a.sequence
                   ],
                   where: a.company_id == ^params["company_id"],
                   left_join: b in assoc(a, :addressdirectors),
                   left_join: c in assoc(a, :contactsdirectors),
                   left_join: co in Countries,
                   on: co.id == b.countries_id,
                   select: %{
                     email_id: a.email_id,
                     id: a.id,
                     first_name: a.first_name,
                     last_name: a.last_name,
                     date_of_birth: a.date_of_birth,
                     status: a.status,
                     is_primary: a.is_primary,
                     sequence: a.sequence,
                     address_line_one: b.address_line_one,
                     addressdirectors_id: b.id,
                     address_line_two: b.address_line_two,
                     address_line_three: b.address_line_three,
                     county: b.county,
                     country_name: co.country_name,
                     countries_id: b.countries_id,
                     town: b.town,
                     post_code: b.post_code,
                     contact_number: c.contact_number,
                     position: a.position,
                     verify_kyc: a.verify_kyc
                   })
            |> Repo.all

    _address = Enum.map(
      count,
      fn (x) -> x[:id]

                data = Repo.all(
                  from kyc in Kycdirectors, where: kyc.directors_id == ^x[:id] and kyc.type == "A",
                                            left_join: dt in Documenttype,
                                            on: dt.id == kyc.documenttype_id,
                                            left_join: dc in assoc(dt, :documentcategory),
                                            order_by: [
                                              desc: kyc.id
                                            ],
                                            select: %{
                                              kycdirectors_id: kyc.id,
                                              file_location: kyc.file_location,
                                              type: kyc.type,
                                              issue_date: kyc.issue_date,
                                              document_number: kyc.document_number,
                                              title: dc.title,
                                              document_type: dt.title,
                                              reason: kyc.reason,
                                              expiry_date: kyc.expiry_date,
                                              inserted_at: kyc.inserted_at,
                                              kyc_status: kyc.status
                                            }
                )



                id_info = Repo.all(
                  from kc in Kycdirectors, where: kc.directors_id == ^x[:id] and kc.type == "I",
                                           left_join: adm2 in Administratorusers,
                                           on: adm2.id == kc.refered_id,
                                           left_join: dtt in Documenttype,
                                           on: dtt.id == kc.documenttype_id,
                                           left_join: dcc in assoc(dtt, :documentcategory),
                                           order_by: [
                                             desc: kc.id
                                           ],
                                           select: %{
                                             kycdirectors_id: kc.id,
                                             file_location: kc.file_location,
                                             file_location_two: kc.file_location_two,
                                             type: kc.type,
                                             issue_date: kc.issue_date,
                                             reason: kc.reason,
                                             refered_id: kc.refered_id,
                                             refered_by: adm2.fullname,
                                             document_number: kc.document_number,
                                             title: dcc.title,
                                             document_type: dtt.title,
                                             expiry_date: kc.expiry_date,
                                             inserted_at: kc.inserted_at,
                                             kyc_status: kc.status,
                                             country: kc.country,
                                             fourstop_response: kc.fourstop_response
                                           }
                )
                key = Enum.map(
                  id_info,
                  fn (q) ->
                    #      gbg_status = if x[:verify_kyc] == "gbg", do: getGBGStatus(q.fourstop_response), else: get_fourstop_info(x[:id])
                    gbg_status = checkThirdpartyResponse(q.fourstop_response)
                    new_key = if !is_nil(x[:date_of_birth]) and !is_nil(x[:contact_number]) and !is_nil(
                      x[:address_line_one]
                    ) and !is_nil(q.issue_date) do
                      %{call_gbg: "YES", gbg_status: gbg_status}
                    else
                      %{call_gbg: "NO", gbg_status: gbg_status}
                    end
                    Map.merge(q, new_key)
                  end
                )

                check_data = Repo.one(
                  from k in Kyclogin, where: k.directors_id == ^x[:id], limit: 1, select: k.inserted_at
                )
                send_mail = if !is_nil(check_data), do: "Yes", else: "No"
                mail_send_at = if !is_nil(check_data), do: check_data, else: ""
                %{
                  director_info: %{
                    first_name: x[:first_name],
                    email_id: x[:email_id],
                    director_id: x[:id],
                    addressdirectors_id: x[:addressdirectors_id],
                    last_name: x[:last_name],
                    sequence: x[:sequence],
                    position: x[:position],
                    date_of_birth: x[:date_of_birth],
                    status: x[:status],
                    town: x[:town],
                    is_primary: x[:is_primary],
                    address_line_one: x[:address_line_one],
                    address_line_two: x[:address_line_two],
                    address_line_three: x[:address_line_three],
                    county: x[:county],
                    country_name: x[:country_name],
                    countries_id: x[:countries_id],
                    post_code: x[:post_code],
                    contact_number: x[:contact_number],
                    send_mail: send_mail,
                    mail_send_at: mail_send_at,
                  },
                  kyc: %{
                    address: data,
                    id: key
                  }
                }
      end
    )
  end

  defp checkThirdpartyResponse(response) do
    if !is_nil(response) do
      check = if String.contains?(response, "http://schemas.xmlsoap.org/soap/envelope"), do: "GBG", else: "FS"
      case check do
        "GBG" -> getGBGStatus(response)
        "FS" -> get_fourstop_info(response)
      end
    else
      ""
    end
  end

  defp getGBGStatus(kyc_response) do
    if !is_nil(kyc_response) do
      gbg_data = Poison.decode!(kyc_response)
      _output = if !is_nil(gbg_data["response"]) do
        response = gbg_data["response"]
        string = response["{http://schemas.xmlsoap.org/soap/envelope/}Envelope"]["{http://schemas.xmlsoap.org/soap/envelope/}Body"]["AuthenticateSPResponse"]
        if !is_nil(string) do
          case string["AuthenticateSPResult"]["BandText"] do
            "Pass" -> "GBG Pass"
            "Refer" -> "GBG Refer"
            "Alert" -> "GBG Alert"
            _ -> "GBG #{string["AuthenticateSPResult"]["BandText"]}"
          end
        else
          "GBG Failed"
        end
      else
        ""
      end
    else
      ""
    end
  end

  def is_map?(map) when is_map(map), do: true
  def is_map?(map) when is_list(map), do: false

  def get_fourstop_info(response) do
    if !is_nil(response) do
      decode_response = Poison.decode!(response)
      case Map.has_key?(decode_response, "response") do
        true ->

          fourstop_data = Poison.decode!(decode_response["response"])
          if is_map?(fourstop_data) === true do
            case Map.has_key?(fourstop_data, "rec") do
              true ->
                case fourstop_data["rec"] do
                  "Approve" ->
                    "4s Success"
                  "Refer" ->
                    "4s refer"
                  _ ->
                    "4s failed"
                end
              false ->
                if Map.has_key?(fourstop_data, "reference_id") === true do
                  if fourstop_data["reference_id"] != "0", do: "4s Success", else: "4s failed"
                else
                  "4s failed"
                end
            end
          else
            [fs_data] = fourstop_data
            case Map.has_key?(fs_data, "rec") do
              true ->
                case fs_data["rec"] do
                  "Approve" ->
                    "4s Success"
                  "Refer" ->
                    "4s refer"
                  _ ->
                    "4s failed"
                end
              false ->
                if Map.has_key?(fs_data, "reference_id") === true do
                  if fs_data["reference_id"] != "0", do: "4s Success", else: "4s failed"
                else
                  "4s failed"
                end
            end
          end
        false ->
          case decode_response["rec"] do
            "Approve" ->
              "4s Success"
            "Refer" ->
              "4s refer"
            _ ->
              "4s failed"
          end
      end
    else
      ""
    end
  end
  def get_cap_kyc_company(_params) do
    #
    #    Repo.all(
    #    from d in Directors, where: d.company_id == ^params["company_id"] and d.position == "CAP",
    #                         inner_join: k in assoc(d, :kycdirectors),
    #                         inner_join: add in assoc(d, :addressdirectors),
    #                         inner_join: c in assoc(d, :contactsdirectors),
    #                         inner_join: dt in assoc(k, :documenttype),
    #                         inner_join: dc in assoc(dt, :documentcategory),
    #                    select: %{
    #                      title: d.title,
    #                      first_name: d.first_name,
    #                      last_name: d.last_name,
    #                      position: d.position,
    #                    company_id: d.company_id,
    #
    #                      DOB: d.date_of_birth,
    #                      contact: c.contact_number,
    #                      address1: add.address_line_one,
    #                      address2: add.address_line_two,
    #                      address3: add.address_line_three,
    #                      city: add.city,
    #                      town: add.town,
    #                      county: add.county,
    #                      post_code: add.post_code,
    #
    #                      document_number: k.document_number,
    #                      document_category: dc.title,
    #                      document_type: dt.title,
    #                      expiry_date: k.expiry_date,
    #                      issue_date: k.issue_date,
    #                      date_added: k.inserted_at,
    #                      status: k.status
    #                    }
    #    )
    #
    #
  end

  def addShareHolder(params) do
    type = params["type"]
    fullname = params["fullname"]
    dob = params["dob"]
    address = params["address"]
    percentage = params["percentage"]
    inserted_by = params["inserted_by"]
    person_map = %{
      "fullname" => fullname,
      "company_id" => params["company_id"],
      "dob" => dob,
      "type" => type,
      "status" => "A",
      "address" => address,
      "percentage" => percentage,
      "inserted_by" => inserted_by,
    }

    changeset = case type do
      "C" -> Shareholder.addChangeset(%Shareholder{}, person_map)
      "P" -> Shareholder.changeset(%Shareholder{}, person_map)
    end
    case Repo.insert(changeset) do
      {:ok, _data} -> {:ok, "Success, Share Holder Added"}
      {:error, changeset} -> {:error, changeset}
    end
  end


  def remove_pending_company(params, _admin_id)do
    _password = params["password"]
    commanall_id = params["commanall_id"]

    commanall = Repo.all(from c in Commanall, where: c.id == ^commanall_id and is_nil(c.accomplish_userid), limit: 1)

    if commanall != [] do
      _response = Enum.each commanall, fn x ->
        companydocumentinfo = Repo.all(from comp in Companydocumentinfo, where: comp.company_id == ^x.company_id)
        if companydocumentinfo != [] do
          from(from comp in Companydocumentinfo, where: comp.company_id == ^x.company_id)
          |> Repo.delete_all
        end
        four = Repo.all(from f in Fourstop, where: f.commanall_id == ^x.id)
        if four != [] do
          from(comm in Fourstop, where: comm.commanall_id == ^commanall_id)
          |> Repo.delete_all
        end
        get_director = Repo.all(from d in Directors, where: d.company_id == ^x.company_id)
        Enum.each get_director, fn v ->
          director = Repo.all(from cd in Contactsdirectors, where: cd.directors_id == ^v.id)
          if director != [] do
            from(dir in Contactsdirectors, where: dir.directors_id == ^v.id)
            |> Repo.delete_all
          end
          addressdirectors = Repo.all(from cd in Addressdirectors, where: cd.directors_id == ^v.id)
          if addressdirectors != [] do
            from(dir in Addressdirectors, where: dir.directors_id == ^v.id)
            |> Repo.delete_all
          end
          kycdirectors = Repo.all(from kycdirector in Kycdirectors, where: kycdirector.directors_id == ^v.id)
          if kycdirectors != [] do
            Enum.each kycdirectors, fn a ->
              kyccomments = Repo.all(from kyc in Kyccomments, where: kyc.kycdirectors_id == ^a.id)
              if kyccomments != [] do
                from(ky in Kyccomments, where: ky.kycdirectors_id == ^a.id)
                |> Repo.delete_all
              end
            end
            from(dir in Kycdirectors, where: dir.directors_id == ^v.id)
            |> Repo.delete_all
          end
          kycl = Repo.all(from kycl in Kyclogin, where: kycl.directors_id == ^v.id)
          if kycl != [] do
            from(kyc in Kyclogin, where: kyc.directors_id == ^v.id)
            |> Repo.delete_all
          end
          dir = Repo.all(from kycd in Directors, where: kycd.id == ^v.id)
          if dir != [] do
            from(di in Directors, where: di.id == ^v.id)
            |> Repo.delete_all
          end
        end
        address = Repo.all(from add in Address, where: add.commanall_id == ^x.id)
        if address != [] do
          from(ad in Address, where: ad.commanall_id == ^x.id)
          |> Repo.delete_all
        end
        contacts = Repo.all(from con in Contacts, where: con.commanall_id == ^x.id)
        if contacts != [] do
          from(ad in Contacts, where: ad.commanall_id == ^x.id)
          |> Repo.delete_all
        end
        kycdocuments = Repo.all(from kycd in Kycdocuments, where: kycd.commanall_id == ^x.id)
        Enum.each kycdocuments, fn z ->
          kycdocumentsa = Repo.all(from kyc in Commankyccomments, where: kyc.kycdocuments_id == ^z.id)
          if kycdocumentsa != [] do
            from(ad in Commankyccomments, where: ad.kycdocuments_id == ^z.id)
            |> Repo.delete_all
          end
        end
        (from kyy in Kycdocuments, where: kyy.commanall_id == ^x.id)
        |> Repo.delete_all
        initlize = Repo.all(from i in Intilaze, where: i.commanall_id == ^x.id)
        if initlize != [] do
          from(ini in Intilaze, where: ini.commanall_id == ^x.id)
          |> Repo.delete_all
        end
        opinion = Repo.all(from kop in Kycopinion, where: kop.commanall_id == ^x.id)
        if opinion != [] do
          from(ko in Kycopinion, where: ko.commanall_id == ^x.id)
          |> Repo.delete_all
        end
        otp = Repo.all(from otp in Otp, where: otp.commanall_id == ^x.id)
        if otp != [] do
          from(ko in Otp, where: ko.commanall_id == ^x.id)
          |> Repo.delete_all
        end
        devicedetails = Repo.all(from dd in Devicedetails, where: dd.commanall_id == ^x.id)
        if devicedetails != [] do
          from(ko in Devicedetails, where: ko.commanall_id == ^x.id)
          |> Repo.delete_all
        end
        notification = Repo.all(from nt in Notifications, where: nt.commanall_id == ^x.id)
        if notification != [] do
          from(ko in Notifications, where: ko.commanall_id == ^x.id)
          |> Repo.delete_all
        end
        mandate = Repo.all(from md in Mandate, where: md.commanall_id == ^x.id)
        if mandate != [] do
          from(ko in Mandate, where: ko.commanall_id == ^x.id)
          |> Repo.delete_all
        end
        permissions = Repo.all(from pr in Permissions, where: pr.commanall_id == ^x.id)
        if permissions != [] do
          from(ko in Permissions, where: ko.commanall_id == ^x.id)
          |> Repo.delete_all
        end
        shareholder = Repo.all(from sh in Shareholder, where: sh.company_id == ^x.company_id)
         _response = Enum.map shareholder, fn y ->
           _kycdocs = (from a in Kycshareholder, where: a.shareholder_id == ^ y.id)
                      |> Repo.delete_all
         end
        if shareholder != [] do
          from(ko in Shareholder, where: ko.company_id == ^x.company_id)
          |> Repo.delete_all
        end
        departments = Repo.all(from dp in Departments, where: dp.company_id == ^x.company_id)
        if departments != [] do
          from(ko in Departments, where: ko.company_id == ^x.company_id)
          |> Repo.delete_all
        end
        _kycdocs = (from a in Thirdpartylogs, where: a.commanall_id == ^x.id)
                   |> Repo.delete_all
        _kycdocs = (from aa in Loginhistory, where: aa.commanall_id == ^x.id)
                   |> Repo.delete_all

        commanall = Repo.all(from comm in Commanall, where: comm.id == ^commanall_id)
        if commanall != [] do
          from(ko in Commanall, where: ko.id == ^commanall_id)
          |> Repo.delete_all
        end
        company = Repo.one(from com in Company, where: com.id == ^x.company_id)
        if company != nil do
          from(ko in Company, where: ko.id == ^x.company_id)
          |> Repo.delete_all
        end
      end
      {:ok, "Company Deleted"}
    else
      {:error_message, "Company can't be deleted"}
    end
  end

  def getCompanyKycDetails(params) do

    kyc = Repo.all(
      from k in Kycdocuments, where: k.commanall_id == ^params["commanall_id"] and k.type == "C",
                              left_join: d in assoc(k, :documenttype),
                              order_by: [
                                desc: k.id
                              ],
                              select: %{
                                id: k.id,
                                inserted_at: k.inserted_at,
                                status: k.status,
                                title: d.title,
                                file_location: k.file_location
                              }
    )

    shareholder = Repo.all(
      from s in Shareholder, where: s.company_id == ^params["company_id"] and s.status == "A",
                             order_by: [
                               desc: s.id
                             ],
                             select: %{
                               fullname: s.fullname,
                               dob: s.dob,
                               id: s.id,
                               address: s.address,
                               percentage: s.percentage,
                               type: s.type
                             }
    )
    result = %{kyb: kyc, shareholder: shareholder}
    if (kyc == [] && shareholder == []) do
      {:not_found, result}
    else
      {:ok, result}
    end
  end

  def addDirectorAddress(params, admin_id) do

    data = Repo.get_by(Directors, id: params["directors_id"])
    if !is_nil(data) do

      addressdirectors = %{
        directors_id: params["directors_id"],
        address_line_one: Commontools.capitalize(params["address_line_one"]),
        address_line_two: Commontools.capitalize(params["address_line_two"]),
        address_line_three: Commontools.capitalize(params["address_line_three"]),
        town: params["town"],
        county: params["county"],
        post_code: params["post_code"],
        countries_id: params["locationId"],
        inserted_by: admin_id,
        is_primary: "Y"
      }
      changeset = Addressdirectors.changeset(%Addressdirectors{}, addressdirectors)
      case Repo.insert(changeset) do
        {:ok, _add} -> {:ok, "Address added"}
        {:error, changeset} -> {:error, changeset}
      end
    else
      {:error_message, "Record not found"}
    end
  end


  def editDirectorAddress(params) do

    data = Repo.get_by(Addressdirectors, id: params["id"])

    if !is_nil(data) do
      director = Repo.one(from c in Directors, where: c.id == ^data.directors_id, limit: 1, select: c)
      if !is_nil(director.email_id)do
        check_email = check_director_user(director.email_id)
        if check_email == "Y" do
          addressdirectors = %{
            address_line_one: Commontools.capitalize(params["address_line_one"]),
            address_line_two: Commontools.capitalize(params["address_line_two"]),
            address_line_three: Commontools.capitalize(params["address_line_three"]),
            town: params["town"],
            county: params["county"],
            post_code: params["post_code"],
            countries_id: params["locationId"],
          }

          changeset = Addressdirectors.changeset(data, addressdirectors)
          case Repo.update(changeset) do
            {:ok, _add} -> {:ok, "Address added"}
            {:error, changeset} -> {:error, changeset}
          end
        else
          {:error_message, "Address can't be update"}
        end
      else
        {:error_message, "Record not found"}
      end
    else
      {:error_message, "Record not found"}
    end
  end


  def addDirectorDob(params) do

    data = Repo.get_by(Directors, id: params["director_id"])
    if !is_nil(data) do

      date = %{
        date_of_birth: params["date_of_birth"]
      }
      changeset = Directors.updateDob(data, date)
      case Repo.update(changeset) do
        {:ok, _add} -> {:ok, "Date of birth added"}
        {:error, changeset} -> {:error, changeset}
      end
    else
      {:error_message, "Record not found"}
    end
  end


  def editDirectorEmail(params) do

    data = Repo.get_by(Directors, id: params["director_id"])
    if !is_nil(data) do
      email_id = params["email_id"]
      director_user = Repo.one(from c in Directors, where: c.id == ^params["director_id"], limit: 1, select: c)
      if !is_nil(director_user.email_id) do
        check_email_name = check_director_user(director_user.email_id)
        if check_email_name == "Y" do
          check = Repo.one(from c in Directors, where: c.email_id == ^email_id, limit: 1, select: c.id)
          case check do
            nil ->
              email = %{email_id: email_id}
              changeset = Directors.update_email(data, email)
              case Repo.update(changeset) do
                {:ok, _add} ->
                  if data.sequence == 1 do
                    check_email = Repo.one(
                      from cd in Commanall, where: cd.company_id == ^data.company_id, limit: 1, select: cd
                    )
                    if !is_nil(check_email) do
                      email = %{email_id: email_id}
                      changeset = Commanall.changesetEmail(check_email, email)
                      Repo.update(changeset)
                    end
                  else
                    check_kyclogin = Repo.one(
                      from cd in Kyclogin, where: cd.directors_id == ^params["director_id"], limit: 1, select: cd
                    )
                    if !is_nil(check_kyclogin) do
                      username_map = %{username: email_id}
                      changeset = Kyclogin.updateEmailID(check_kyclogin, username_map)
                      Repo.update(changeset)
                    end
                  end
                  {:ok, "email updated"}
                {:error, changeset} ->
                  {:error, changeset}
              end
            _check ->
              {:already_exist, "email already exist"}
          end
        else
          {:error_message, "Email ID can't be updated"}
        end
      else
        {:error_message, "Record not found"}
      end
    else
      {:error_message, "Record not found"}
    end
  end

  def editDirectorContact(params) do

    data = Repo.get_by(Directors, id: params["director_id"])
    if !is_nil(data) do
      contact = params["contact"]
      contactdirector = Repo.one(
        from con in Contactsdirectors, where: con.directors_id == ^params["director_id"], limit: 1
      )
      if !is_nil(contactdirector) do
        director_user = Repo.one(from c in Directors, where: c.id == ^params["director_id"], limit: 1, select: c)
        if !is_nil(director_user.email_id) do
          check_email = check_director_user(director_user.email_id)
          if check_email == "Y" do
            check = Repo.one(from c in Contactsdirectors, where: c.contact_number == ^contact, limit: 1, select: c.id)
            case check do
              nil ->
                number = %{contact_number: contact}
                changeset = Contactsdirectors.changeset(contactdirector, number)
                case Repo.update(changeset) do
                  {:ok, _add} ->

                    if data.sequence == 1 do

                      get_company = Repo.one(
                        from cd in Commanall, where: cd.company_id == ^data.company_id, limit: 1, select: cd
                      )
                      if !is_nil(get_company) do
                        check_contact = Repo.one(
                          from co in Contacts, where: co.commanall_id == ^get_company.id, limit: 1, select: co
                        )
                        if !is_nil(check_contact) do
                          number = %{contact_number: contact}
                          changeset = Contacts.changeset_number(check_contact, number)
                          Repo.update(changeset)
                        end
                      end
                    end
                    {:ok, "contact updated"}
                  {:error, changeset} ->
                    {:error, changeset}
                end
              _check ->
                {:already_exist, "contact number already exist"}
            end
          else
            {:error_message, "Contact number can't be update"}
          end
        else
          {:error_message, "Record not found"}
        end
      else
        {:error_message, "Record not found"}
      end
    else
      {:error_message, "Record not found"}
    end
  end

  def addDirectorContact(params, admin_id) do

    data = Repo.get_by(Directors, id: params["director_id"])
    if !is_nil(data) do
      contact = params["contact"]
      check = Repo.one(from c in Contactsdirectors, where: c.contact_number == ^contact, limit: 1, select: c.id)
      case check do
        nil ->
          country_code = Application.get_env(:violacorp, :country_code)
          number = %{
            directors_id: params["director_id"],
            code: country_code,
            contact_number: contact,
            is_primary: "Y",
            inserted_by: admin_id
          }
          changeset = Contactsdirectors.changeset(%Contactsdirectors{}, number)
          case Repo.insert(changeset) do
            {:ok, _add} -> {:ok, "contact added"}
            {:error, changeset} -> {:error, changeset}
          end
        _check ->
          {:already_exist, "contact number already exist"}
      end
    else
      {:error_message, "Record not found"}
    end
  end

  @doc"delete pending director"
  def deletePendingDirector(params) do

    director_check = Repo.one(
      from d in Directors,
      where: d.id == ^params["director_id"] and d.verify_kyc == ^"pending" and d.is_primary == "N" and d.sequence != 1
    )
    kycdirector_check = Repo.one(
      from k in Kycdirectors,
      where: k.directors_id == ^params["director_id"] and not is_nil(k.fourstop_response) and k.type == ^"I", limit: 1
    )

    if !is_nil(director_check) do
      if is_nil(kycdirector_check) do

        address = Repo.all(from a in Addressdirectors, where: a.directors_id == ^director_check.id)
        if address != [] do
          from(from ad in Addressdirectors, where: ad.directors_id == ^director_check.id)
          |> Repo.delete_all
        end

        contact = Repo.all(from co in Contactsdirectors, where: co.directors_id == ^director_check.id)
        if contact != [] do
          from(from con in Contactsdirectors, where: con.directors_id == ^director_check.id)
          |> Repo.delete_all
        end

        kyclogin = Repo.all(from k in Kyclogin, where: k.directors_id == ^director_check.id)
        if kyclogin != [] do
          from(from kyc in Kyclogin, where: kyc.directors_id == ^director_check.id)
          |> Repo.delete_all
        end

        mandate = Repo.all(from m in Mandate, where: m.directors_id == ^director_check.id)
        if mandate != [] do
          from(from man in Mandate, where: man.directors_id == ^director_check.id)
          |> Repo.delete_all
        end

        kycdirector = Repo.all(from kd in Kycdirectors, where: kd.directors_id == ^director_check.id)
        if kycdirector != [] do
          Enum.map(
            kycdirector,
            fn (x) ->
              kyccomments = Repo.all(from kycom in Kyccomments, where: kycom.kycdirectors_id == ^x.id)
              if kyccomments != [] do
                (from kyco in Kyccomments, where: kyco.kycdirectors_id == ^x.id)
                |> Repo.delete_all
              end
            end
          )
          from(from kyd in Kycdirectors, where: kyd.directors_id == ^director_check.id)
          |> Repo.delete_all
        end

        case Repo.delete(director_check) do
          {:ok, _del} ->

            company_id = director_check.company_id
            get_directors = Repo.all(
              from d in Directors, where: d.company_id == ^company_id,
                                   order_by: [
                                     asc: d.id
                                   ],
                                   select: d
            )
            get_directors
            |> Stream.with_index
            |> Enum.reduce(
                 0,
                 fn (num_idx, _acc) ->
                   {directors, idx} = num_idx

                   if directors.sequence != 1 && idx != 0 do
                     new_map = %{sequence: idx + 1}
                     changeset = Directors.changesetSequence(directors, new_map)
                     Repo.update(changeset)
                   end
                 end
               )

            {:ok, "director deleted"}
          {:error_message, message} ->
            {:error_message, message}
        end
      else
        {:error_message, "director can't be deleted"}
      end
    else
      {:error_message, "director can't be deleted"}
    end
  end

  @doc"delete primary director"
  def deletePrimaryDirector(params) do

    director_check = Repo.one(
      from d in Directors, where: d.id == ^params["director_id"] and d.verify_kyc == ^"pending" and d.is_primary == "Y"
    )

    kycdirector_check = Repo.one(
      from k in Kycdirectors,
      where: k.directors_id == ^params["director_id"] and not is_nil(k.fourstop_response) and k.type == ^"I", limit: 1
    )

    if !is_nil(director_check) do
      if is_nil(kycdirector_check) do
        company_id = director_check.company_id

        director_get = Repo.one(
          from d in Directors, where: d.company_id == ^company_id and d.is_primary == "N" and d.sequence == 2, select: d
        )
        if !is_nil(director_get) do
          check_sec = Repo.one(
            from dc in Contactsdirectors, where: dc.directors_id == ^director_get.id, limit: 1, select: dc
          )
          if !is_nil(check_sec) do
            address = Repo.all(from a in Addressdirectors, where: a.directors_id == ^director_check.id)
            if address != [] do
              from(from ad in Addressdirectors, where: ad.directors_id == ^director_check.id)
              |> Repo.delete_all
            end

            contact = Repo.all(from co in Contactsdirectors, where: co.directors_id == ^director_check.id)
            if contact != [] do
              from(from con in Contactsdirectors, where: con.directors_id == ^director_check.id)
              |> Repo.delete_all
            end

            kyclogin = Repo.all(from k in Kyclogin, where: k.directors_id == ^director_check.id)
            if kyclogin != [] do
              from(from kyc in Kyclogin, where: kyc.directors_id == ^director_check.id)
              |> Repo.delete_all
            end

            mandate = Repo.all(from m in Mandate, where: m.directors_id == ^director_check.id)
            if mandate != [] do
              from(from man in Mandate, where: man.directors_id == ^director_check.id)
              |> Repo.delete_all
            end

            kycdirector = Repo.all(from kd in Kycdirectors, where: kd.directors_id == ^director_check.id)
            if kycdirector != [] do
              Enum.map(
                kycdirector,
                fn (x) ->
                  kyccomments = Repo.all(from kycom in Kyccomments, where: kycom.kycdirectors_id == ^x.id)
                  if kyccomments != [] do
                    (from kyco in Kyccomments, where: kyco.kycdirectors_id == ^x.id)
                    |> Repo.delete_all
                  end
                end
              )
              from(from kyd in Kycdirectors, where: kyd.directors_id == ^director_check.id)
              |> Repo.delete_all
            end

            case Repo.delete(director_check) do
              {:ok, _del} ->

                commanall_data = Repo.one(
                  from co in Commanall, where: co.company_id == ^director_check.company_id, select: co
                )
                contacts_data = Repo.one(
                  from contacts in Contacts,
                  where: contacts.commanall_id == ^commanall_data.id and contacts.is_primary == ^"Y", select: contacts
                )
                #            company_id = director_check.company_id
                #
                #            director_get = Repo.one(from d in Directors, where: d.company_id == ^company_id and d.is_primary == "N" and d.sequence == 2, select: d)
                director_co = Repo.one(
                  from d in Contactsdirectors, where: d.directors_id == ^director_get.id and d.is_primary == "N",
                                               select: d
                )
                if !is_nil(director_get) do

                  email_id = director_get.email_id
                  commanall_params = %{email_id: email_id}
                  comanall_changeset = Commanall.changeset(commanall_data, commanall_params)
                  Repo.update(comanall_changeset)

                  primary = %{is_primary: "Y"}
                  dir_changeset = Directors.changesetPrimary(director_get, primary)
                  Repo.update(dir_changeset)
                end

                if !is_nil(director_co) do
                  contact = director_co.contact_number
                  contact_add = %{contact_number: contact}

                  cont_changeset = Contacts.changeset(contacts_data, contact_add)
                  Repo.update(cont_changeset)
                end

                get_directors = Repo.all(
                  from d in Directors, where: d.company_id == ^company_id,
                                       order_by: [
                                         asc: d.id
                                       ],
                                       select: d
                )
                get_directors
                |> Stream.with_index
                |> Enum.reduce(
                     0,
                     fn (num_idx, _acc) ->
                       {directors, idx} = num_idx

                       new_map = %{sequence: idx + 1}
                       changeset = Directors.changesetSequence(directors, new_map)
                       Repo.update(changeset)
                     end
                   )

                {:ok, "director deleted"}
              {:error_message, message} ->
                {:error_message, message}
            end
          else
            {:error_message, "director can't be deleted"}
          end
        else
          {:error_message, "director can't be deleted"}
        end
      else
        {:error_message, "director can't be deleted"}
      end
    else
      {:error_message, "director can't be deleted"}
    end
  end


  def addCompanyAddress(params, admin_id) do

    address = %{
      commanall_id: params["commanall_id"],
      address_line_one: Commontools.capitalize(params["address_line_one"]),
      address_line_two: Commontools.capitalize(params["address_line_two"]),
      address_line_three: Commontools.capitalize(params["address_line_three"]),
      town: params["town"],
      sequence: 1,
      county: params["county"],
      post_code: params["post_code"],
      countries_id: params["locationId"],
      inserted_by: admin_id,
      is_primary: "Y"
    }
    changeset = Address.changeset(%Address{}, address)
    case Repo.insert(changeset) do
      {:ok, _add} -> {:ok, "Address added"}
      {:error, changeset} -> {:error, changeset}
    end

  end

  def editCompanyAddress(params) do

    data = Repo.get_by(Address, id: params["id"])

    if !is_nil(data) do
      commanall_id = data.commanall_id
      check_id = Repo.one(
        from c in Commanall, where: c.id == ^commanall_id and not is_nil(c.accomplish_userid), select: c
      )
      if is_nil(check_id) do
        address = %{
          address_line_one: Commontools.capitalize(params["address_line_one"]),
          address_line_two: Commontools.capitalize(params["address_line_two"]),
          address_line_three: Commontools.capitalize(params["address_line_three"]),
          town: params["town"],
          county: params["county"],
          post_code: params["post_code"],
          countries_id: params["locationId"]
        }
        changeset = Address.updateChangeset(data, address)
        case Repo.update(changeset) do
          {:ok, _add} -> {:ok, "Address updated"}
          {:error, changeset} -> {:error, changeset}
        end
      else
        {:error_message, "Address can't be updated"}
      end
    else
      {:error_message, "Record not found"}
    end
  end

  def editRegistrationNumber(params) do

    data = Repo.get_by(Company, id: params["company_id"])
    if !is_nil(data) do

      number = %{registration_number: params["registration_number"]}
      changeset = Company.changesetregisteration(data, number)
      case Repo.update(changeset) do
        {:ok, _data} -> {:ok, "Registration number updated"}
        {:error, changeset} -> {:error, changeset}
      end
    else
      {:error_message, "Record not found"}
    end
  end

  def addCompanyEmail(params) do

    data = Repo.get_by(Company, id: params["company_id"])
    if !is_nil(data) do
      email_id = params["email_id"]
      check = Repo.one(from c in Commanall, where: c.email_id == ^email_id, limit: 1, select: c.id)
      case check do
        nil ->
          email = %{email_id: email_id}
          changeset = Commanall.changesetEmail(%Commanall{}, email)
          case Repo.insert(changeset) do
            {:ok, _add} -> {:ok, "email added"}
            {:error, changeset} -> {:error, changeset}
          end
        _check ->
          {:already_exist, "email id already exist"}
      end
    else
      {:error_message, "Record not found"}
    end
  end

  def editCompanyEmail(params) do

    data = Repo.one(
      from co in Commanall,
      where: co.id == ^params["commanall_id"] and co.company_id == ^params["company_id"] and is_nil(
        co.accomplish_userid
             )
    )
    if !is_nil(data) do
      email_id = params["email_id"]
      check = Repo.one(from c in Commanall, where: c.email_id == ^email_id, limit: 1, select: c.id)
      case check do
        nil ->
          email = %{email_id: email_id}
          changeset = Commanall.changesetEmail(data, email)
          case Repo.update(changeset) do
            {:ok, _add} ->
              check_director = Repo.one(
                from d in Directors, where: d.email_id == ^data.email_id and d.company_id == ^params["company_id"],
                                     limit: 1,
                                     select: d
              )
              if !is_nil(check_director) do
                email_map = %{email_id: email_id}
                changeset_email = Directors.update_email(check_director, email_map)
                Repo.update(changeset_email)
              end
              {:ok, "email updated"}
            {:error, changeset} ->
              {:error, changeset}
          end
        _check ->
          {:already_exist, "email id already exist"}
      end
    else
      {:error_message, "can't update this email"}
    end
  end

  def editCompanyContact(params) do

    data = Repo.one(from con in Contacts, where: con.commanall_id == ^params["commanall_id"], limit: 1, select: con)
    if !is_nil(data) do
      check_id = Repo.one(from co in Commanall, where: co.id == ^data.commanall_id and is_nil(co.accomplish_userid))
      if !is_nil(check_id) do
        contact = params["contact"]
        check = Repo.one(from co in Contacts, where: co.contact_number == ^contact, limit: 1, select: co.id)
        case check do
          nil ->
            number = %{contact_number: contact}
            changeset = Contacts.changeset_number(data, number)
            case Repo.update(changeset) do
              {:ok, _add} ->
                check_director = Repo.one(
                  from d in Contactsdirectors, where: d.contact_number == ^data.contact_number, limit: 1, select: d
                )
                if !is_nil(check_director) do
                  contact_map = %{contact_number: contact}
                  changeset_contact = Contactsdirectors.changeset(check_director, contact_map)
                  Repo.update(changeset_contact)
                end
                {:ok, "contact updated"}
              {:error, changeset} ->
                {:error, changeset}
            end
          _check ->
            {:already_exist, "contact number already exist"}
        end
      else
        {:error_message, "Contact can't be updated"}
      end
    else
      {:error_message, "Record not found"}
    end
  end

  @doc "check company Approval for Authorized "
  def checkCompanyApprovalAuthorize(commanall_id, company_id) do
    company_kyb = Repo.one(
      from kyb in Kycdocuments, where: kyb.commanall_id == ^commanall_id and kyb.type == ^"C" and kyb.status == ^"A",
                                select: count(kyb.id)
    )
    directors = Repo.all(from d in Directors, where: d.company_id == ^company_id, select: d.id)
    chk = 0
    director_kyc = if !is_nil(directors) do
      Enum.map(
        directors,
        fn d_id ->
          check_id_proof = Repo.one(
            from kyd in Kycdirectors, where: kyd.directors_id == ^d_id and kyd.type == ^"I" and kyd.status == ^"A",
                                      select: count(kyd.id)
          )
          check_add_proof = Repo.one(
            from ka in Kycdirectors, where: ka.directors_id == ^d_id and ka.type == ^"A" and ka.status == ^"A",
                                     select: count(ka.id)
          )
          new_val = if check_id_proof != 0 && check_add_proof != 0 do
            chk + 1
          else
            chk
          end
          new_val
        end
      )
    else
      chk
    end
    _result = if Enum.sum(director_kyc) > 0 && company_kyb > 0 && Enum.sum(director_kyc) == Enum.count(directors),
                 do: "Y", else: "N"
  end


  defp thirdpartylogs(commanall_id) do
    check_registration = Repo.one(
      from rlog in Thirdpartylogs,
      where: rlog.commanall_id == ^commanall_id and like(rlog.section, "%Registration%") and rlog.status == ^"S",
      limit: 1,
      select: count(rlog.id)
    )
    registration = if check_registration > 0, do: "Y", else: "N"
    case registration do
      "N" ->
        result = Repo.one(
          from reglog in Thirdpartylogs,
          where: reglog.commanall_id == ^commanall_id and like(
            reglog.section,
            "%Registration%"
                 ) and reglog.status == ^"F",
          order_by: [
            desc: reglog.id
          ],
          limit: 1,
          select: reglog.response
        )
        reason = if !is_nil(result) do
          decode_dat = Poison.decode!(result)
          decode_dat["result"]["message"]
        end
        registration_status = if !is_nil(result), do: "F", else: registration
        %{registration: registration_status, reason: reason}
      "Y" ->
        check_identification = Repo.one(
          from log in Thirdpartylogs,
          where: log.commanall_id == ^commanall_id and like(
            log.section,
            "%Create Identification%"
                 ) and log.status == ^"S",
          limit: 1,
          select: count(log.id)
        )
        identification = if check_identification > 0, do: "Y", else: "N"
        case identification do
          "N" ->
            result = Repo.one(
              from reglog in Thirdpartylogs,
              where: reglog.commanall_id == ^commanall_id and like(
                reglog.section,
                "%Create Identification%"
                     ) and reglog.status == ^"F",
              order_by: [
                desc: reglog.id
              ],
              limit: 1,
              select: reglog.response
            )
            reason = if !is_nil(result) do
              decode_dat = Poison.decode!(result)
              decode_dat["result"]["message"]
            end
            identification_status = if !is_nil(result), do: "F", else: identification
            %{registration: registration, identification: identification_status, reason: reason}
          "Y" ->
            check_id_proof = Repo.one(
              from idlog in Thirdpartylogs,
              where: idlog.commanall_id == ^commanall_id and like(idlog.section, "%Id Proof%") and idlog.status == ^"S",
              limit: 1,
              select: count(idlog.id)
            )
            proof_of_identity = if check_id_proof > 0, do: "Y", else: "N"
            case proof_of_identity do
              "N" ->
                result = Repo.one(
                  from reglog in Thirdpartylogs,
                  where: reglog.commanall_id == ^commanall_id and like(
                    reglog.section,
                    "%Id Proof%"
                         ) and reglog.status == ^"F",
                  order_by: [
                    desc: reglog.id
                  ],
                  limit: 1,
                  select: reglog.response
                )
                reason = if !is_nil(result) do
                  decode_dat = Poison.decode!(result)
                  decode_dat["result"]["message"]
                end
                identity_status = if !is_nil(result), do: "F", else: proof_of_identity
                %{
                  registration: registration,
                  identification: identification,
                  proof_of_identity: identity_status,
                  reason: reason
                }
              "Y" ->
                check_add_proof = Repo.one(
                  from addlog in Thirdpartylogs,
                  where: addlog.commanall_id == ^commanall_id and like(
                    addlog.section,
                    "%Address Proof%"
                         ) and addlog.status == ^"S",
                  limit: 1,
                  select: count(addlog.id)
                )
                proof_of_address = if check_add_proof > 0, do: "Y", else: "N"
                case proof_of_address do
                  "N" ->
                    result = Repo.one(
                      from reglog in Thirdpartylogs,
                      where: reglog.commanall_id == ^commanall_id and like(
                        reglog.section,
                        "%Address Proof%"
                             ) and reglog.status == ^"F",
                      order_by: [
                        desc: reglog.id
                      ],
                      limit: 1,
                      select: reglog.response
                    )
                    reason = if !is_nil(result) do
                      decode_dat = Poison.decode!(result)
                      decode_dat["result"]["message"]
                    end
                    address_status = if !is_nil(result), do: "F", else: proof_of_address
                    %{
                      registration: registration,
                      identification: identification,
                      proof_of_identity: proof_of_identity,
                      proof_of_address: address_status,
                      reason: reason
                    }
                  "Y" ->
                    %{
                      registration: registration,
                      identification: identification,
                      proof_of_identity: proof_of_identity,
                      proof_of_address: proof_of_address,
                      reason: nil
                    }
                end
            end
        end
    end
  end

  def directorKycOverride(params, admin_id) do

    data = Repo.get_by(Kycdirectors, id: params["kycdirectors_id"], directors_id: params["directors_id"])
    if !is_nil(data) do
      type = data.type
      check = Repo.one(
        from k in Kycdirectors,
        where: k.directors_id == ^params["directors_id"] and k.type == ^type and k.status == "A", select: k.id
      )
      case check do
        nil ->
          up = %{
            status: "A",
            reason: params["reason"],
            refered_id: admin_id
          }
          changeset = Kycdirectors.kycChangeset(data, up)
          case Repo.update(changeset) do
            {:ok, _add} -> {:ok, "Kyc override done"}
            {:error, changeset} -> {:error, changeset}
          end
        _data ->
          {:already_exist, "document already exist"}
      end
    else
      {:error_message, "Record not found"}
    end
  end

  def registration_steps_array(params)do
    data = Repo.one(
      from d in Commanall, where: d.company_id == ^params["company_id"],
                           left_join: b in assoc(d, :company),
                           on: b.id == d.company_id,
                           select: %{
                             company_type: b.company_type,
                             status: d.status,
                             reg_step: d.reg_step,
                           },
                           limit: 1
    )
    director_position = Repo.one(
      from d1 in Directors, where: d1.company_id == ^params["company_id"] and d1.sequence == ^1,
                            select: d1.position,
                            limit: 1
    )
    #     total_directors = Repo.one(from d2 in Directors, where: d2.company_id == ^params["company_id"] , select: count(d2.id), limit: 1)

    if !is_nil(data) do
      position = String.downcase(director_position)
      steps = case position do
        "owner" ->
          %{
            "1" => "Company Detail",
            "11" => "Email Confirmation OTP",
            "12" => "Mobile Confirmation OTP",
            "2" => "V-PIN",
            "3" => "Business Information",
            "5" => "Owner Details",
            "6" => "Legal Documents"
          }
        "director" ->
          %{
            "1" => "Company Detail",
            "11" => "Email Confirmation OTP",
            "12" => "Mobile Confirmation OTP",
            "2" => "V-PIN",
            "3" => "Company Information",
            "4" => "Add Directors",
            "5" => "Business Owner",
            "6" => "Legal Documents"
          }
        "cap" ->
          %{
            "1" => "Company Detail",
            "11" => "Email Confirmation OTP",
            "12" => "Mobile Confirmation OTP",
            "2" => "V-PIN",
            "3" => "Business Information",
            "5" => "Owner Details",
            "6" => "Legal Documents"
          }
        "significant" ->
          %{
            "1" => "Company Detail",
            "11" => "Email Confirmation OTP",
            "12" => "Mobile Confirmation OTP",
            "2" => "V-PIN",
            "3" => "Business Information",
            "5" => "Owner Details",
            "6" => "Legal Documents"
          }
      end
      {:ok, steps}
    else
      {:not_found, []}
    end
  end
  def edit_registration_step(params) do
    data = Repo.get_by(Commanall, id: params["commanall_id"], company_id: params["company_id"])
    if !is_nil(data) do
      reg_step = params["reg_step"]
      _check = Repo.one(from c in Commanall, where: c.reg_step == ^reg_step, limit: 1, select: c.id)
      reg_step = %{reg_step: reg_step}
      changeset = Commanall.changesetRegistrationStep(data, reg_step)
      case Repo.update(changeset) do
        {:ok, _add} -> {:ok, "Step updated"}
        {:error, changeset} -> {:error, changeset}
      end
    else
      {:error_message, "Record not found"}
    end
  end

  def check_director_user(params)do
    data = Repo.one(from c in Commanall, where: c.email_id == ^params and not is_nil(c.accomplish_userid))
    if is_nil(data) do
      "Y"
    else
      "N"
    end
  end
end
