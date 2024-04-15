defmodule Violacorp.Models.KycDocuments do

  import Ecto.Query, warn: false
  alias Violacorp.Repo
  #  alias Violacorp.Schemas.Company
  alias Violacorp.Schemas.Kyclogin
  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Kycdocuments
  alias Violacorp.Schemas.Kycdirectors
  alias Violacorp.Schemas.Kyccomments
  alias Violacorp.Schemas.Commankyccomments

  def updateEmployeeKycAndComment(director_id, map, status)do

    employee = Repo.one(from d in Directors, where: d.id == ^director_id, select: d.employee_id)
    if !is_nil(employee)do

      kycemployeeId = Repo.one(
        from k in Kycdirectors,
        left_join: ekyc in Kycdocuments,
        on: ekyc.document_number == k.document_number,
        where: k.directors_id == ^director_id and k.id == ^map["kycdirectors_id"],
        select: ekyc.id
      )

      if !is_nil kycemployeeId do
        case status do
          "R" ->
            kyc = Repo.get_by(Kycdocuments, id: kycemployeeId)
            changeset_kyc_doc = Kycdocuments.update_status(kyc, map)
            case Repo.update(changeset_kyc_doc)do
              {:ok, _data} ->
                insert_common_comment = %{
                  "comments" => map["comment"],
                  "kycdocuments_id" => kycemployeeId,
                  "inserted_by" => map["inserted_by"]
                }
                changeset = Commankyccomments.changeset(%Commankyccomments{}, insert_common_comment)
                Repo.insert(changeset)
              {:error, changeset} -> {:error, changeset}
            end

          _ ->
            insert_map_employee_comment = %{
              "comments" => map["comment"],
              "kycdocuments_id" => kycemployeeId,
              "inserted_by" => map["inserted_by"]
            }
            changeset = Commankyccomments.changeset(%Commankyccomments{}, insert_map_employee_comment)
            case Repo.insert(changeset)do
              {:ok, _data} ->
                kyc = Repo.get_by(Kycdocuments, id: kycemployeeId)
                if !is_nil(kyc) do
                  map = case status do
                    "A" ->
                      status = case kyc.type do
                        "I" -> "AC"
                        "A" -> "A"
                      end
                      %{"status" => status}
                    "R" ->
                      %{"status" => "R"}
                    _ -> :error
                  end
                  case map do
                    :error -> {:status_error, "Invalid Status, Value Must be 'A' or 'R'"}
                    _ -> changeset_kyc_doc = Kycdocuments.update_status(kyc, map)
                         Repo.update(changeset_kyc_doc)
                         {:ok, "Success, Comment Added"}
                  end
                else
                  {:document_error, "Kyc Document does not exist"}
                end
              {:error, changeset} -> {:error, changeset}
            end
        end
      end
    end
  end

  def  director_kyc_comments(params, admin_id)do
    kycdirectors_id = params["kycdirectors_id"]
    director_id = params["director_id"]
    status = params["status"]
    comments = params["comments"]

    insert_map = %{
      "comment" => comments,
      "kycdirectors_id" => kycdirectors_id,
      "inserted_by" => admin_id
    }
    changeset = Kyccomments.changeset(%Kyccomments{}, insert_map)
    case Repo.insert(changeset)do
      {:ok, _data} ->
        case status do
          "A" ->
            x = Repo.one(from k in Kycdirectors, where: k.id == ^kycdirectors_id, select: k)
            if x.type == "A" do
              map = %{"status" => "A"}
              changeset_address = Kycdirectors.changeset_addess(x, map)
              case Repo.update(changeset_address) do
                {:ok, _changeset} -> updateEmployeeKycAndComment(director_id, insert_map, status)
                {:error, changeset} -> {:error, changeset}
              end
            end
            if x.type == "I" do
              map = %{"status" => "AC"}
              changeset_kyc_doc = Kycdirectors.kycStatusChangeset(x, map)

              case Repo.update(changeset_kyc_doc) do
                {:ok, _changeset} -> updateEmployeeKycAndComment(director_id, insert_map, status)
                {:error, changeset} -> {:error, changeset}
              end
            end

          "R" ->
            get = Repo.one(from k in Kycdirectors, where: k.id == ^kycdirectors_id)
            map = %{"status" => "R", "director_id" => String.to_integer(director_id)}
            changeset_kyc_doc = Kycdirectors.kycStatusChangeset(get, map)
            new_map = Map.merge(
              map,
              %{"kycdirectors_id" => kycdirectors_id, "comment" => params["comments"], "inserted_by" => admin_id}
            )
            case Repo.update(changeset_kyc_doc) do
              {:ok, _changeset} -> updateEmployeeKycAndComment(map["director_id"], new_map, "R")
              {:error, changeset} -> {:error, changeset}
            end
          _ -> ""
        end
        {:ok, "Success, Comment Added"}

      {:error, changeset} -> {:error, changeset}
    end
  end


  defp checkValidation(params) do
    cond do
      (params["status"] == "" and params["comments"] == "") ->
        {
          :error_message,
          %{
            status_code: "4003",
            errors: %{
              status: ["can't be blank"],
              comments: ["can't be blank"]
            }
          }
        }
      #      (params["director_id"]) == ""-> {:error_message, %{status_code: "4003", errors: %{director_id: ["can't be blank"]}}}
      (params["status"]) == "" ->
        {
          :error_message,
          %{
            status_code: "4003",
            errors: %{
              status: ["can't be blank"]
            }
          }
        }
      (params["comments"]) == "" ->
        {
          :error_message,
          %{
            status_code: "4003",
            errors: %{
              comments: ["can't be blank"]
            }
          }
        }
      true ->
        {:ok, "done"}
    end
  end
  @doc "insert_active_user_kyc_proof_comment"
  def  insert_active_user_kyc_proof_comment(params, admin_id) do

    case checkValidation(params) do
      {:ok, _add} ->

        kycdocuments_id = params["kycdocuments_id"]
        _director_id = params["director_id"]
        status = params["status"]
        comments = params["comments"]
        insert_map = %{
          "comments" => comments,
          "kycdocuments_id" => kycdocuments_id,
          "inserted_by" => admin_id
        }
        kyc = Repo.get_by(Kycdocuments, id: kycdocuments_id)
        if !is_nil(kyc) do
          changeset = Commankyccomments.changeset(%Commankyccomments{}, insert_map)
          case Repo.insert(changeset)do
            {:ok, _data} ->
              map = case status do
                "A" ->
                  status = case kyc.type do
                    "I" -> "AC"
                    "A" -> "A"
                  end
                  #                                    %{"status" => status, "director_id" => director_id}
                  %{"status" => status}
                "R" ->
                  #                                      %{"status" => "R", "director_id" => director_id}
                  %{"status" => "R"}
                _ -> :error
              end

              case map do
                :error -> {:status_error, "Invalid Status, Value Must be 'A' or 'R'"}
                _ -> changeset_kyc_doc = Kycdocuments.update_status(kyc, map)
                     Repo.update(changeset_kyc_doc)
                     #-------------------------------------
                     # check if employee is also director, if yes then update director kyc comment and kyc record

                     employee_id = Repo.one(
                       from a in Kycdocuments,
                       left_join: c in Commanall,
                       on: a.commanall_id == c.id,
                       where: a.id == ^kycdocuments_id,
                       select: c.employee_id
                     )

                     director_id = isEmployeeAlsoDirector?(employee_id)
                     if !is_nil(director_id)do
                       kycdirector = Repo.get_by(
                         Kycdirectors,
                         document_number: kyc.document_number,
                         directors_id: director_id
                       )
                       if !is_nil(kycdirector)do
                         insert_map = %{
                           "comment" => comments,
                           "kycdirectors_id" => kycdirector.id,
                           "inserted_by" => admin_id
                         }
                         changeset = Kyccomments.changeset(%Kyccomments{}, insert_map)
                         case Repo.insert(changeset)do
                           {:ok, _changeset} ->
                             map = %{"status" => "R"}
                             changeset_kyc_doc = Kycdirectors.kycStatusChangeset(kycdirector, map)
                             Repo.update(changeset_kyc_doc)
                           {:error, changeset} -> {:error, changeset}
                         end
                       end
                     end

                     #-------------------------------------
                     {:ok, "Success, Comment Added"}
              end
            {:error, changeset} -> {:error, changeset}
          end
        else
          {:document_error, "Kyc Document does not exist"}
        end
      {:error_message, message} -> {:validation_error, message}
    end
  end

  @doc""

  def directorKycOverride(params, admin_id)do

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
            refered_id: "99999#{admin_id}"
          }
          employee = Repo.one(
            from k in Kycdirectors, left_join: d in assoc(k, :directors),
                                    where: k.id == ^params["kycdirectors_id"] and k.type == ^type,
                                    select: d.employee_id
          )
          changeset = Kycdirectors.kycChangeset(data, up)
          case Repo.update(changeset) do
            {:ok, _add} ->
              if !is_nil(employee)do
                kycemployee = Repo.one(
                  from s in Kycdocuments,
                  where: s.document_number == ^data.document_number and s.type == ^type
                )
                changeset = Kycdocuments.changesetKycOverride(kycemployee, up)
                case Repo.update(changeset) do
                  {:ok, _add} -> {:ok, "director and employee override done"}
                  {:error, changeset} -> {:error, changeset}
                end
              else
                {:ok, "director override done"}
              end
            {:error, changeset} -> {:error, changeset}
          end
        _data -> {:already_exist, "document already exist"}
      end
    else
      {:error_message, "Record not found"}
    end
  end

  @doc """
    employee kyc override by admin
  """
  def employeeKycOverride(params, admin_id) do
    data = Repo.get_by(Kycdocuments, id: params["kycdocument_id"], commanall_id: params["commanall_id"])
    if !is_nil(data) do
      type = data.type
      check = Repo.one(
        from k in Kycdocuments,
        where: k.commanall_id == ^params["commanall_id"] and k.type == ^type and k.status == "A", limit: 1, select: k.id
      )
      case check do
        nil ->

          director = Repo.all(
            from k in Kycdocuments, where: k.id == ^params["kycdocument_id"],
                                    left_join: c in Commanall,
                                    on: c.id == k.commanall_id,
                                    left_join: director in Directors,
                                    on: director.company_id == c.company_id,
                                    left_join: d in Kycdirectors,
                                    on: k.document_number == d.document_number,
                                    where: k.type == ^type,
                                    select: %{
                                      document_number: k.document_number,
                                      company_id: c.company_id,
                                      directors_id: director.id
                                    }
          )
          new_changeset = %{
            status: "A",
            reason: params["reason"],
            refered_id: "99999#{admin_id}"
          }
          changeset = Kycdocuments.changesetKycOverride(data, new_changeset)
          case Repo.update(changeset) do
            {:ok, _add} ->

              if !is_nil(director)do
                first = List.first(director)
                kycdirector = Repo.get_by(
                  Kycdirectors,
                  document_number: first.document_number,
                  directors_id: first.directors_id
                )

                if !is_nil(kycdirector)do
                  changesetkycdirector = Kycdirectors.kycChangeset(kycdirector, new_changeset)
                  case Repo.update(changesetkycdirector) do
                    {:ok, _add} -> {:ok, "director and employee override done"}
                    {:error, changesetkycdirector} -> {:error, changesetkycdirector}
                  end
                else
                  {:ok, "employee override done"}
                end
              else
                {:ok, "employee override done"}
              end

            {:error, changeset} -> {:error, changeset}
          end
        _data -> {:already_exist, "document already exist"}
      end
    else
      {:error_message, "Record not found"}
    end
  end

  @doc""
  def isDirectorAnEmployee?(director_id)do
    check = Repo.one(from d in Directors, where: d.id == ^director_id, select: d.employee_id)
    case check do
      nil -> nil
      _ -> check
    end
  end

  def isEmployeeAlsoDirector?(employee_id)do
    check = Repo.one(
      from e in Employee,
      left_join: d in Directors,
      on: e.id == d.employee_id,
      where: e.id == ^employee_id,
      select: d.id
    )

    case check do
      nil -> :notDirector
      director_id -> director_id
    end
  end

  defp check_value(params) do
    cond do
      params["image_one"] == "" and params["documentcategory_id"] == "" and params["documenttype_id"] == "" ->
        {:errors, %{image: ["can't be blank"], documenttype: ["can't be blank"], documentcategory: ["can't be blank"]}}
      params["image_two"] == "" ->
        {:errors, %{image: ["can't be blank"]}}
      params["documenttype_id"] == "" ->
        {:errors, %{documenttype: ["can't be blank"]}}
      params["documentcategory_id"] == "" ->
        {:errors, %{documentcategory: ["can't be blank"]}}
      params["image_base64"] != "" and params["documenttype_id"] != "" ->
        {:ok, "ok"}
    end
  end

  defp deactivateDirectorKyc(id)do
    Enum.each id, fn x ->
      record = Repo.get_by(Kycdirectors, id: x)
      deactivate = %{
        status: "R"
      }
      changeset = Kycdirectors.kycStatusUpdateChangeset(record, deactivate)
      Repo.update(changeset)
    end
  end

  defp existingDirector?(director_id)do
    case Repo.get_by(Directors, id: director_id) do
      nil -> :doesNotExist
      _ -> :exists
    end
  end
  defp existingEmployee?(employee_id)do
    case Repo.get_by(Employee, id: employee_id) do
      nil -> :doesNotExist
      _ -> :exists
    end
  end


  @doc""
  def directorKycDocumentUpload(params, director_id, admin_id)do

    documentcategory_id = params["documentcategory_id"]
    #    documenttype_id = params["documenttype_id"]
    #    director_id = params["director_id"]
    case check_value(params) do
      {:ok, "ok"} ->

        #        type = case documentcategory_id do
        #          1 -> "A"
        #          2 -> "I"
        #        end
        #        documentcategory_id = params["documentcategory_id"]

        type = if Map.has_key?(params, "type")do
          params["type"]
        else
          case documentcategory_id do
            1 -> "A"
            2 -> "I"
          end
        end


        existing = Repo.all(
          from a in Kycdirectors,
          where: a.directors_id == ^director_id and (
            a.status == "A" or a.status == "P" or a.status == "D") and a.type == ^type,
          select: a.id
        )
        #        IO.inspect([5555, existing])
        case existing do
          [] ->
            uploadDirectorKyc(params, admin_id, type)
          _ ->

            #            #----------------REJECT ALL PREVIOUS UPLOADS-----------#
            #            w = Repo.all(from r in Kycdirectors,
            #                         where: r.directors_id == ^director_id  and r.type == ^type#and r.documenttype_id == ^documenttype_id and (r.status == "A" or r.status == "P" or r.status == "D") and r.type == ^type
            #            )
            #            Enum.each w, fn x ->
            #              deactivate = %{
            #                status: "R"
            #              }
            #              changeset = Kycdirectors.kycStatusUpdateChangeset(x, deactivate)
            #              Repo.update(changeset)
            #            end
            #            #----------------REJECT ALL PREVIOUS UPLOADS END-----------#


            deactivateDirectorKyc(existing)
            uploadDirectorKyc(params, admin_id, type)
        end

      {:errors, message} -> {:errors, message}

    end
  end

  @doc""

  def directorDocUpload(params, admin_id)do



    director_id = params["director_id"]
    documentcategory_id = params["documentcategory_id"]
    type = if Map.has_key?(params, "type")do
      params["type"]
    else
      case documentcategory_id do
        1 -> "A"
        2 -> "I"
      end
    end
    case existingDirector?(director_id) do
      :exists ->
        case directorKycDocumentUpload(params, director_id, admin_id)do
          {:errors, changeset} -> {:errors, changeset}
          {:ok, _changeset} -> :ok
        end

        case isDirectorAnEmployee?(director_id)do

          nil -> {:ok, "Director Document Uploaded Successfully"}

          employee_id ->
            if type == "A" do
              employeeKycDocumentUploadAddress(params, employee_id, admin_id)
            else
              if type == "I" do
                employeeKycDocumentUploadID(params, employee_id, admin_id)
              end
            end
            {:ok, "Director and Employee Docs Uploaded Successfully"}

        end

      :doesNotExist -> {:errors, "No director found with id #{director_id}"}

    end
  end

  @doc""


  def employeeDocUpload(params, admin_id, type)do

    employee_id = params["employee_id"]
    case existingEmployee?(employee_id) do
      :exists ->
        case isEmployeeAlsoDirector?(employee_id)do
          :notDirector ->
            case type do
              "I" -> employeeKycDocumentUploadID(params, employee_id, admin_id)
              "A" -> employeeKycDocumentUploadAddress(params, employee_id, admin_id)
            end
          director_id -> #{:ok, "123456767"}
            category_id = if type == "I" do
              2
            else
              1
            end
            newParams = Map.merge(params, %{"director_id" => director_id, "documentcategory_id" => category_id})
            #                          deactivateDirectorKyc(director_id)
            #                          IO.inspect([2, newParams])
            directorDocUpload(newParams, admin_id)

            #                          directorKycDocumentUpload(newParams, director_id, admin_id)
            {:ok, "Director and Employee Docs Uploaded Successfully"}
        end
      :doesNotExist -> {:doesNotExist, "No employee found with id #{employee_id}"}
    end
  end


  @doc""
  def directorKycDocumentUploadv2(params, admin_id)do
    documentcategory_id = params["documentcategory_id"]
    #    documenttype_id = params["documenttype_id"]
    director_id = params["director_id"]

    check_director = existingDirector?(director_id)
    check = isDirectorAnEmployee?(director_id)
    #    IO.inspect(check)
    case check_director do
      :exists ->
        case check_value(params) do
          {:ok, "ok"} ->
            type = case documentcategory_id do
              1 -> "A"
              2 -> "I"
            end

            existing = Repo.all(
              from a in Kycdirectors,
              where: a.directors_id == ^director_id and (
                a.status == "A" or a.status == "P" or a.status == "D") and a.type == ^type,
              select: a.id
            )
            case existing do
              [] ->
                if !is_nil(check) and type == "I" do

                  employeeKycDocumentUploadID(params, check, admin_id)
                else
                  if !is_nil(check) and type == "A" do
                    employeeKycDocumentUploadAddress(params, check, admin_id)
                  end

                end
                uploadDirectorKyc(params, admin_id, type)
              _ ->

                deactivateDirectorKyc(existing)

                if !is_nil(check) and type == "I" do

                  employeeKycDocumentUploadID(params, check, admin_id)
                else
                  if !is_nil(check) and type == "A" do
                    employeeKycDocumentUploadAddress(params, check, admin_id)
                  end
                end
                uploadDirectorKyc(params, admin_id, type)
            end
          {:errors, message} -> {:errors, message}
        end
      :doesNotExist ->
        {:errors, "No director found with id #{director_id}"}
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
    #    request_id = "99999#{admin_id}"
    #    adminId = String.to_integer(request_id)

    data = %{
      directors_id: params["director_id"],
      documenttype_id: params["documenttype_id"],
      document_number: params["document_number"],
      expiry_date: params["expiry_date"],
      issue_date: params["issue_date"],
      file_name: List.last(Regex.split(~r{/}, s3_url)),
      file_type: List.last(Regex.split(~r{\.}, s3_url)),
      file_location: s3_url,
      file_location_two: s3_url2,
      type: type,
      status: "D",
      inserted_by: "99999#{admin_id}",
    }
    changeset = case type do
      "A" -> Kycdirectors.changeset_upload_kyc(%Kycdirectors{}, data)
      "I" -> Kycdirectors.changesetUploadIdProof(%Kycdirectors{}, data)
    end

    #            changeset = Kycdirectors.changeset_upload_kyc(%Kycdirectors{}, data)
    if changeset.valid? do

      result = case type do
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
              {:ok, "Kyc Document Added Successfully"}
            {:error, changeset} -> {:error, changeset}
          end
        "N" ->
          case Repo.insert(changeset) do
            {:ok, _data} -> {:ok, "Kyc Document Added Successfully"}
            {:error, changeset} -> {:error, changeset}
          end
      end
    else
      {:error, changeset}
    end
  end

  @doc""
  def employeeKycDocumentUploadID(params, employee_id, admin_id)do
    changeset = Kycdocuments.changesetIDProof(%Kycdocuments{}, params)
    if changeset.valid? do
      commanall_id = Repo.one(from a in Commanall, where: a.employee_id == ^employee_id, select: a.id)
      existing = Repo.all(
        from a in Kycdocuments,
        where: a.commanall_id == ^commanall_id and a.documenttype_id == ^params["documenttype_id"] and (
          a.status == "A" or a.status == "D") and a.type == "I",
        select: a.id
      )

      case existing do
        [] ->
          uploadEmployeeID(params, admin_id, commanall_id)
        _ ->
          #          #----------------REJECT ALL PREVIOUS UPLOADS-----------#
          #
          #          q = Repo.all(from a in Kycdocuments,
          #                       where: a.commanall_id == ^commanall_id and a.type == "I")# and a.documenttype_id == ^params["documenttype_id"] and a.status == "A" and a.type == "A")
          #          Enum.each q, fn x ->
          #            deactivate = %{
          #              status: "R"
          #            }
          #            changeset = Kycdocuments.update_status_changeset(x, deactivate)
          #            Repo.update(changeset)
          #          end
          #          #----------------REJECT ALL PREVIOUS UPLOADS END-----------#
          deactivateEmployeeKyc(existing)
          uploadEmployeeID(params, admin_id, commanall_id)
      end
    else
      {:error, changeset}
    end
  end

  @doc""
  def employeeKycDocumentUploadAddress(params, employee_id, admin_id)do
    changeset = Kycdocuments.changesetAddressProof(%Kycdocuments{}, params)
    if changeset.valid? do
      commanall_id = Repo.one(from a in Commanall, where: a.employee_id == ^employee_id, select: a.id)
      existing = Repo.all(
        from a in Kycdocuments,
        where: a.commanall_id == ^commanall_id and a.documenttype_id == ^params["documenttype_id"] and (
          a.status == "A" or a.status == "D") and a.type == "A",
        order_by: [
          desc: a.inserted_at
        ],
        select: a.id
      )

      case existing do
        [] ->
          uploadEmployeeAddress(params, admin_id, commanall_id)
        _ ->
          #          #----------------REJECT ALL PREVIOUS UPLOADS-----------#
          #          q = Repo.all(from a in Kycdocuments,
          #                       where: a.commanall_id == ^commanall_id and a.type == "A")# and a.documenttype_id == ^params["documenttype_id"] and a.status == "A" and a.type == "A")
          #          Enum.each q, fn x ->
          #            deactivate = %{
          #              status: "R"
          #            }
          #            changeset = Kycdocuments.update_status_changeset(x, deactivate)
          #            Repo.update(changeset)
          #          end
          #          #----------------REJECT ALL PREVIOUS UPLOADS END-----------#
          deactivateEmployeeKyc(existing)
          uploadEmployeeAddress(params, admin_id, commanall_id)
      end
    else
      {:error, changeset}
    end
  end

  defp deactivateEmployeeKyc(id)do
    Enum.each id, fn x ->
      record = Repo.get_by(Kycdocuments, id: x)
      deactivate = %{
        status: "R"
      }
      changeset = Kycdocuments.update_status_changeset(record, deactivate)
      Repo.update(changeset)
    end
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
    #    request_id = "99999#{admin_id}"
    #    adminId = String.to_integer(request_id)
    data = %{
      commanall_id: commanall_id,
      documenttype_id: params["documenttype_id"],
      document_number: params["document_number"],
      issue_date: params["issue_date"],
      expiry_date: params["expiry_date"],
      file_name: List.last(Regex.split(~r{/}, s3_url)),
      file_type: List.last(Regex.split(~r{\.}, s3_url)),
      file_location: s3_url,
      file_location_two: s3_url2,
      status: "D",
      type: "I",
      inserted_by: admin_id
    }
    changeset = Kycdocuments.changesetIDProof(%Kycdocuments{}, data)
    case Repo.insert(changeset) do
      {:ok, _data} -> {:ok, "Employee ID Kyc Document Added Successfully"}
      {:error, changeset} -> {:error, changeset}
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
end
