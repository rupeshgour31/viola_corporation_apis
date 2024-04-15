defmodule Violacorp.Models.KycDocumentsV2 do

  import Ecto.Query, warn: false
  alias Violacorp.Repo
  #  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Kyclogin
  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Kycdocuments
  alias Violacorp.Schemas.Kycdirectors
  alias Violacorp.Schemas.Employee
    alias Violacorp.Schemas.Kyccomments
    alias Violacorp.Schemas.Commankyccomments

  @doc""
  # Check to see if Director is also an Employee
  # If so then return Directors Employee id
  def isDirectorAlsoEmployee?(id)do
    check = Repo.one(from d in Directors, where: d.id == ^id, select: d.employee_id)
    case check do
      nil -> 0
      _ -> check
    end
  end

  # Check to see if Employee is also a Director
  # If so then return Directors Employee id
  def isEmployeeAlsoDirector?(id)do
    check = Repo.one(from d in Directors, where: d.employee_id == ^id, select: d.id)
    case check do
      nil -> 0
      _ -> check
    end
  end

  # Reject all Director documents with given id and type
  def rejectALlExistingDirectorKyc(director_id, type)do
    case Repo.all(
           from a in Kycdirectors,
           where: a.directors_id == ^director_id and (a.status == "A" or a.status == "D") and a.type == ^type
         ) do
      [] -> "No pending or active documents available for director"
      _ ->
        (
          from a in Kycdirectors,
               where: a.directors_id == ^director_id and (a.status == "A" or a.status == "D") and a.type == ^type
          )
        |> Repo.update_all(
             set: [
               status: "R"
             ]
           )
    end
  end

  # Reject all Employee documents with given id and type
  def rejectALlExistingEmployeeKyc(id, type)do
    commanall_id = Repo.one(from a in Commanall, where: a.employee_id == ^id, select: a.id)
    case Repo.all(
           from a in Kycdocuments,
           where: a.commanall_id == ^commanall_id and (a.status == "A" or a.status == "D") and a.type == ^type
         ) do
      [] -> "No pending or active documents available for employee"
      _ ->
        (
          from a in Kycdocuments,
               where: a.commanall_id == ^commanall_id and (a.status == "A" or a.status == "D") and a.type == ^type
          )
        |> Repo.update_all(
             set: [
               status: "R"
             ]
           )
    end
    #Return Commanall id for employee
    commanall_id
  end

  #Check if Director Exists on Database
  defp existingDirector?(director_id)do
    case Repo.get_by(Directors, id: director_id) do
      nil -> :doesNotExist
      _ -> :exists
    end
  end

  #Check if Employee Exists on Database
  defp existingEmployee?(employee_id)do
    case Repo.get_by(Employee, id: employee_id) do
      nil -> :doesNotExist
      _ -> :exists
    end
  end

  #Upload to AWS and get file paths
  def uploadDocumentToAws(images)do

    url_doc1 = ViolacorpWeb.Main.Assetstore.upload_image(images.doc1)
    url_doc2 = if !is_nil(images.doc2) do
      ViolacorpWeb.Main.Assetstore.upload_image(images.doc2)
    else
      nil
    end

    %{
      url_doc1: url_doc1,
      url_doc2: url_doc2
    }

  end

  #Upload Director document to database
  def uploadDirectorDocument(params, images)do

    data = %{
      directors_id: params["director_id"],
      documenttype_id: params["documenttype_id"],
      document_number: params["document_number"],
      expiry_date: params["expiry_date"],
      issue_date: params["issue_date"],
      file_name: List.last(Regex.split(~r{/}, images.url_doc1)),
      file_type: List.last(Regex.split(~r{\.}, images.url_doc1)),
      file_location: images.url_doc1,
      file_location_two: images.url_doc2,
      type: params["type"],
      status: "D",
      inserted_by: params["admin_id"],
    }
    changeset = case params["type"] do
      "A" -> Kycdirectors.changeset_upload_kyc(%Kycdirectors{}, data)
      "I" -> Kycdirectors.changesetUploadIdProof(%Kycdirectors{}, data)
    end

    if changeset.valid? do
      result = case params["type"] do
        "A" ->
          check_id = Repo.all(
            from k in Kycdirectors, where: k.directors_id == ^params["director_id"] and k.type == "I", select: k.id
          )
          if check_id != [], do: "N", else: "Y"
        "I" ->
          check_ad = Repo.all(
            from k in Kycdirectors, where: k.directors_id == ^params["director_id"] and k.type == "A", select: k.id
          )
          if check_ad != [], do: "N", else: "Y"
      end

      case result do
        "Y" ->
          case Repo.insert(changeset) do
            {:ok, _data} ->

              ky_data = Repo.get_by(Kyclogin, directors_id: params["director_id"])
              if !is_nil(ky_data) do
                kyclogin = Kyclogin.stepsChangeset(ky_data, %{steps: "DONE"})
                Repo.update(kyclogin)
              end

              docName = case params["type"] do
                "A" -> "Address"
                "I" -> "ID"
              end
              {:ok, "Director #{docName} document uploaded"}
            {:error, changeset} -> {:error, changeset}
          end
        "N" ->
          case Repo.insert(changeset) do
            {:ok, _data} ->
              docName = case params["type"] do
                "A" -> "Address"
                "I" -> "ID"
              end
              {:ok, "Director #{docName} document uploaded"}
            {:error, changeset} -> {:error, changeset}
          end
      end
    else
      {:error, changeset}
    end
  end

  # Upload Employee Document to Database
  def uploadEmployeeDocument(params, images)do
      data = %{
        commanall_id: params["commanall_id"],
        documenttype_id: params["documenttype_id"],
        document_number: params["document_number"],
        issue_date: params["issue_date"],
        expiry_date: params["expiry_date"],
        file_name: List.last(Regex.split(~r{/}, images.url_doc1)),
        file_type: List.last(Regex.split(~r{\.}, images.url_doc1)),
        file_location: images.url_doc1,
        file_location_two: images.url_doc2,
        status: "D",
        type: params["type"],
        inserted_by: params["admin_id"]
      }
      changeset = case params["type"] do
        "I" -> Kycdocuments.changesetIDProof(%Kycdocuments{}, data)
        "A" -> Kycdocuments.changesetAddressProof(%Kycdocuments{}, data)
      end

      case Repo.insert(changeset) do
        {:ok, _data} ->
          docName = case params["type"] do
          "A" -> "Address"
          "I" -> "ID"
          end
          {:ok, "Employee #{docName} document uploaded"}
        {:error, changeset} -> {:error, changeset}
      end
  end

  # This is Main Steps to take for uploading all director documents
  def directorUploadSteps(params, admin_id)do

    stepOneParams = Map.merge(params, %{"admin_id" => admin_id})

    #check if Director Exists
    case existingDirector?(params["director_id"]) do
      :exists ->
          #if Director exists on db then upload documents onto AWS
          images = %{doc1: params["image_one"], doc2: params["image_two"]}
          image_url = uploadDocumentToAws(images)

          #check if director is employee, if true then return employee_id
          employee_id = isDirectorAlsoEmployee?(params["director_id"])

          case employee_id do
            0 ->
              #Director is not employee
              #reject existing director kyc documents on db
              rejectALlExistingDirectorKyc(params["director_id"], params["type"])

              #Upload Director documents onto db
              uploadDirectorDocument(params, image_url)

            employee_id ->

              #Director is employee
              #reject existing director kyc documents on db
              rejectALlExistingDirectorKyc(params["director_id"], params["type"])

              #Upload Director documents onto db
              uploadDirectorDocument(stepOneParams, image_url)

              #reject existing employee kyc documents on db
              commanall_id = rejectALlExistingEmployeeKyc(employee_id, params["type"])
              eParams = Map.merge(stepOneParams, %{"commanall_id" => commanall_id})

              #Upload Employee documents onto db
              uploadEmployeeDocument(eParams, image_url)
              {:ok, "Director and employee documents uploaded"}
          end
      :doesNotExist ->
        #Director with given id does not exist
        {:errors, "No director found with id: #{params["director_id"]}"}
    end
  end

  # This is Main Steps to take for uploading all employee documents
  def employeeUploadSteps(params, admin_id)do

    stepOneParams = Map.merge(params, %{admin_id: admin_id})

    #check if Employee Exists
    case existingEmployee?(params["employee_id"]) do
      :exists ->
        #if Director exists on db then upload documents onto AWS
        images = %{doc1: params["image_one"], doc2: params["image_two"]}
        image_url = uploadDocumentToAws(images)

        #check if employee is also director, if true then return director_id
        director_id = isEmployeeAlsoDirector?(params["employee_id"])

        case director_id do
          0 ->
            #Employee is NOT also a director
            #reject existing employee kyc documents on db
            commanall_id = rejectALlExistingEmployeeKyc(params["employee_id"], params["type"])
            eParams = Map.merge(stepOneParams, %{"commanall_id" => commanall_id})

            #Upload Employee documents onto db
            uploadEmployeeDocument(eParams, image_url)

          director_id ->

            #Employee IS also director
            #reject existing employee kyc documents on db
            commanall_id = rejectALlExistingEmployeeKyc(params["employee_id"], params["type"])
            eParams = Map.merge(stepOneParams, %{"commanall_id" => commanall_id})

            #Upload Employee documents onto db
            uploadEmployeeDocument(eParams, image_url)

            #reject existing director kyc documents on db
            rejectALlExistingDirectorKyc(director_id, params["type"])
            dParams = Map.merge(stepOneParams, %{"director_id" => director_id})

            #Upload Director documents onto db
            uploadDirectorDocument(dParams, image_url)
            {:ok, "Director and employee documents uploaded"}
        end

      :doesNotExist -> {:errors, "No employee found with id: #{params["employee_id"]}"}
    end
  end

  def employeeKycOverride(params, admin_id)do
    #check if document exists with given document id
    data = Repo.get_by(Kycdocuments, id: params["kycdocument_id"], commanall_id: params["commanall_id"])
    case data do
      nil -> {:error_message, "Record not found"}
        _ ->
        #document Exists
          case data.status do
            "A" -> {:ok, "Document is already active"}
            "D" -> {:ok, "Document is pending"}
            "R" ->
              #if document status is Rejected then override
              override = %{
                status: "A",
                reason: params["reason"],
                refered_id: "99999#{admin_id}"
              }
              #reject all documents with the same type if they exist
              rejectALlExistingEmployeeKyc(params["commanall_id"], data.type)

              #update record with override document with Active status
              changeset = Kycdocuments.changesetKycOverride(data, override)
              case Repo.update(changeset) do
                {:ok, _add} ->
                    #check if also director
                    director_id = Repo.one(from c in Commanall,
                                           left_join: d in Directors,
                                           on: d.employee_id == c.employee_id,
                                           where: c.id == ^params["commanall_id"],
                                           select: d.id)
                    case director_id do
                      nil ->  #employee is not director then send success message
                             {:ok, "Employee document override done"}

                      director_id ->

                      #When Employee is also director, override director documents with Active status
                        kycDirector = Repo.one(from k in Kycdirectors,
                                               where: k.document_number == ^data.document_number
                                               and k.directors_id == ^director_id
                                               and k.type == ^data.type,
                                               order_by: [desc: k.inserted_at],
                                               limit: 1,
                                               select: %{id: k.id, status: k.status}
                        )
                        if !is_nil kycDirector do

                          #when same director document is found
                          case kycDirector.status do

                            #if status is already active then send success message
                            "A" -> {:ok, "Employee document override done"}
                              _ ->

                              #if document is not active then reject all documents with same type
                                rejectALlExistingDirectorKyc(director_id, data.type)

                                #update override document with active status
                            record = Repo.get_by(Kycdirectors, id: kycDirector.id)
                            changesetkycdirector = Kycdirectors.kycChangeset(record, override)
                            case Repo.update(changesetkycdirector)do
                              {:ok, _add} -> {:ok, "Employee and Director document override done"}

                              #error with updating director document
                              {:error, changeset} -> {:error, changeset}
                            end
                          end
                          else
                          {:ok, "Employee document override done"}
                        end
                    end
                 #Error with updating employee document
                {:error, changeset} -> {:error, changeset}
              end
          end
    end
  end

  def directorKycOverride(params, admin_id)do

    #check if document exists with given document id
    data = Repo.get_by(Kycdirectors, id: params["kycdirectors_id"], directors_id: params["directors_id"])

    case data do
      nil -> {:error_message, "Document not found"}
        _ ->

          #document Exists
          case data.status do
            "A" -> {:ok, "Document is already active"}
            "D" -> {:ok, "Document is pending"}
            "R" ->
              #if document status is Rejected then override
              override = %{
                status: "A",
                reason: params["reason"],
                refered_id: "99999#{admin_id}"
              }

              #reject all documents with the same type if they exist
              rejectALlExistingDirectorKyc(params["directors_id"], data.type)

              #update record with override document with Active status
              changeset = Kycdirectors.kycChangeset(data, override)
              case Repo.update(changeset) do
                {:ok, _add} ->
                #check if also employee
                employee = Repo.one(from d in Directors,
                                       where: d.id == ^params["directors_id"],
                                       left_join: c in Commanall,
                                       on: d.employee_id == c.employee_id,
                                       select: %{employee_id: d.employee_id, commanall_id: c.id})
                case employee do
                    nil ->   #director is not employee then send success message
                      {:ok, "Director document override done"}
                  employee ->
                  #When director is also employee, override employee documents with Active status
                  kycEmployee = Repo.one(from k in Kycdocuments,
                                         where: k.document_number == ^data.document_number
                                         and k.commanall_id == ^employee.commanall_id
                                         and k.type == ^data.type,
                                         order_by: [desc: k.inserted_at],
                                         limit: 1,
                                         select: %{id: k.id, status: k.status}
                                         )
                  if !is_nil kycEmployee do

                    #when same director document is found in employee kycdocuments
                    case kycEmployee.status do
                      #if status is already active then send success message
                      "A" -> {:ok, "Director document override done"}
                      _ ->

                      #if document is not active then reject all documents with same type
                      rejectALlExistingEmployeeKyc(employee.commanall_id, data.type)

                      #update override document with active status
                      record = Repo.get_by(Kycdocuments, id: kycEmployee.id)
                      changesetkycemployee = Kycdocuments.changesetKycOverride(record, override)
                      case Repo.update(changesetkycemployee)do
                        {:ok, _add} -> {:ok, "Director and Employee document override done"}
                        #error with updating employee document
                        {:error, changeset} -> {:error, changeset}
                      end
                    end
                  else
                    {:ok, "Director document override done"}
                  end
                end
                {:error, changeset} -> {:error, changeset}
              end
          end
    end
  end

  def director_kyc_comments(params, admin_id)do
    comment = %{
      "comment" => params["comments"],
      "kycdirectors_id" => params["kycdirectors_id"],
      "inserted_by" => admin_id
    }
    kycDirector = Repo.get_by(Kycdirectors, id: params["kycdirectors_id"])

    case kycDirector do
      nil -> {:ok, "KYC not found"}
        _ ->
        case kycDirector.status do
          "D" ->
                  changeset = Kyccomments.changeset(%Kyccomments{}, comment)
                  case Repo.insert(changeset)do
                    {:ok, _data} ->
                       map = case params["status"]do
                          "A" ->
                                status = case kycDirector.type do
                                  "A" -> "A"
                                  "I" -> "AC"
                                end
                                %{"status" => status}

                          "R" ->
                                %{"status" => "R"}

#                          _ -> :error
                       end

                       status = Kycdirectors.kycStatusChangeset(kycDirector, map)

                       case Repo.update(status) do
                         {:ok, _changeset} ->
                           if Map.has_key?(params, "employee")do
                             empKycId = getEmployeeKycid(kycDirector, params["director_id"])
                             empKycId.id
                           else
                             {:ok, "Director KYC Comment Complete"}
                           end
                         {:error, changeset} -> {:error, changeset}
                       end
                    {:error, changeset} -> {:error, changeset}
                  end
          "A" -> {:ok, "Document is already active"}
          "R" -> {:ok, "Document already rejected"}
          end
    end
  end

  def employee_kyc_comments(params, admin_id)do

    comment = %{
      "comments" => params["comments"],
      "kycdocuments_id" => params["kycdocuments_id"],
      "inserted_by" => admin_id
    }
    kycEmployee = Repo.get_by(Kycdocuments, id: params["kycdocuments_id"])
    case kycEmployee do
      nil -> {:ok, "KYC not found"}
      _ ->
              case kycEmployee.status do
                "D" ->
                  changeset_comment = Commankyccomments.changeset(%Commankyccomments{}, comment)
                  case Repo.insert(changeset_comment)do
                    {:ok, _data} ->

                        map = case params["status"]do
                          "A" ->
                            status = case kycEmployee.type do
                              "I" -> "AC"
                              "A" -> "A"
                            end
                            %{"status" => status}#, "director_id" => director_id}
                          "R" ->
                            %{"status" => "R"}#, "director_id" => director_id}
#                          _ -> :error
                        end
                        changeset_kyc = Kycdocuments.update_status(kycEmployee, map)
                        case Repo.update(changeset_kyc)do
                          {:ok, _changeset} ->
                            IO.inspect([22222222222, params])
                          if Map.has_key?(params, "director")do

                            dirKycId = getDirectorKycid(kycEmployee, params["director"])
                            dirKycId.id

                          else
                            {:ok, "Employee KYC Comment Complete"}
                          end


                          {:error, changeset} -> {:error, changeset}
                        end
                    {:error, changeset} -> {:error, changeset}
                  end

                "A" -> {:ok, "Document is already active"}
                "R" -> {:ok, "Document already rejected"}
              end
    end
  end

  def getEmployeeKycid(data, directors_id)do

    employee = Repo.one(from d in Directors,
                        where: d.id == ^directors_id,
                        left_join: c in Commanall,
                        on: d.employee_id == c.employee_id,
                        select: %{employee_id: d.employee_id, commanall_id: c.id})
    case employee do
      nil ->   #director is not employee then send success message
        {:ok, "Director document override done"}
      employee ->
        #When director is also employee, override employee documents with Active status
        _kycEmployee = Repo.one(from k in Kycdocuments,
                               where: k.document_number == ^data.document_number
                                      and k.commanall_id == ^employee.commanall_id
                               and k.type == ^data.type,
                               order_by: [desc: k.inserted_at],
                               limit: 1,
                               select: %{id: k.id, status: k.status}
        )


  end
  end

  def getDirectorKycid(data, directors_id)do
    _kycDirector = Repo.one(from k in Kycdirectors,
                           where: k.document_number == ^data.document_number
                                  and k.directors_id == ^directors_id
                           and k.type == ^data.type,
                           order_by: [desc: k.inserted_at],
                           limit: 1,
                           select: %{id: k.id, status: k.status}
    )
  end

  def directorCommentSteps(params, admin_id)do

    case existingDirector?(params["director_id"])do
      :doesNotExist -> {:ok, "Director Does not Exist"}
      :exists ->
                 case isDirectorAlsoEmployee?(params["director_id"])do
                   0 ->

                     #if Director is NOT employee do this
                     director_kyc_comments(params, admin_id)


                   _employee_id ->

                     #if Director is employee do this
                     kycParams = Map.merge(params, %{"employee" => "yes"})
                     case director_kyc_comments(kycParams, admin_id)do

                       {:ok, message} -> {:ok, message}

                       kycid ->

                         #when matching document is found for employee do this
                         empKycParams = Map.merge(params, %{"kycdocuments_id" => kycid})
                         employee_kyc_comments(empKycParams, admin_id)
                         {:ok, "Director & Employee KYC Comment Complete"}
                     end
                 end
    end
  end

  def employeeCommentSteps(params, admin_id)do

    employee_id = Repo.one(from c in Commanall,
                           where: c.id == ^params["commanall_id"],
                           select: c.employee_id)
    #Check if emplyee Exisits
    case employee_id do
      nil -> "employee does not exist"

      employee_id ->
      #check if employee is also director
        case isEmployeeAlsoDirector?(employee_id)do
          0 ->
            #if not a director do this
            employee_kyc_comments(params, admin_id)

          director_id ->
           #if employee is ALSO director do this

           #insert Employee Comment and get directorkyc ID
            kycParams = Map.merge(params, %{"director" => director_id})
            case employee_kyc_comments(kycParams, admin_id) do
              {:ok, message} -> {:ok, message}
              kycid ->

              #insert director kyc comment
                dirKycParams = Map.merge(params, %{"kycdirectors_id" => kycid})
                director_kyc_comments(dirKycParams, admin_id)
                {:ok, "Director & Employee KYC Comment Complete"}
            end
        end


    end

  end
end
