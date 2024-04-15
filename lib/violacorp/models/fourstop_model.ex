defmodule Violacorp.Models.FourstopModel do
  import Ecto.Query, warn: false

  alias Violacorp.Repo
  import Ecto.Query
  require Logger
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Countries
  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Kycdocuments
  alias Violacorp.Schemas.Kycdirectors
  alias Violacorp.Schemas.Fourstop
  alias Violacorp.Schemas.Fourstopcallback
  alias Violacorp.Libraries.Fourstop, as: FourstopLibrary
  alias Violacorp.Libraries.Commontools
  alias Violacorp.Libraries.FourstopErrormessages


  def main_vetting(commanall_id, dir_id, doc_id) do
    case Repo.get(Commanall, commanall_id) do
      nil -> {:error, "User not found"}
      commanall ->
        {type, userdata} = cond do
          !is_nil(commanall.company_id) and is_nil(commanall.employee_id) -> {"D", Repo.get(Directors, dir_id)}
          !is_nil(commanall.employee_id) -> {"E", Repo.get(Employee, commanall.employee_id)}
        end

        with {reg_exists, req, res} <- pre_start_checks(commanall_id, type, userdata),
             {:ok, registration_details, request, response, userdata} <- (
               if is_nil(reg_exists) do
                 fourstop_registration_initialise(commanall_id, commanall, dir_id)
               else
                 {:ok, reg_exists, req, res, userdata}
               end) do
          {stopid, kyc_entry_id, kyc_verify} = unless !is_nil(reg_exists) do
            map_response = Poison.decode!(registration_details)
            stopid = map_response["id"]
            description = map_response["description"]
            score = map_response["score"]
            rec = map_response["rec"]
            confidence_level = map_response["confidence_level"]
            status = map_response["status"]

            director_id = if type == "D" and !is_nil(userdata) do
              %Directors{id: userdata.id}
              |> Ecto.Changeset.cast(
                   %{
                     "verify_kyc" => "4s"
                   },
                   [:verify_kyc]
                 )
              |> Repo.update()
              userdata.id
            else
              %Employee{id: userdata.id}
              |> Ecto.Changeset.cast(
                   %{
                     "verify_kyc" => "4s"
                   },
                   [:verify_kyc]
                 )
              |> Repo.update()
              nil
            end
            new_response = %{response: response}
            store_response = Poison.encode!(new_response)

            _update_document = if type == "D" and !is_nil(userdata) do
              %Kycdirectors{id: doc_id}
              |> Ecto.Changeset.cast(
                  %{
                    "fourstop_response" => "#{store_response}"
                  },
                  [:fourstop_response]
                )
              |> Repo.update()
            else
              %Kycdocuments{id: doc_id}
              |> Ecto.Changeset.cast(
                   %{
                     "fourstop_response" => "#{store_response}"
                   },
                   [:fourstop_response]
                 )
              |> Repo.update()
            end
            kyc_entry = %Fourstop{}
                        |> Fourstop.changesetv2(
                             %{
                               "commanall_id" => commanall_id,
                               "stopid" => stopid,
                               "director_id" => director_id,
                               "stop_status" => "#{status}",
                               "description" => description,
                               "score" => "#{score}",
                               "rec" => "#{rec}",
                               "confidence_level" => "#{confidence_level}",
                               "request" => "#{request}",
                               "response" => "#{response}",
                               "status" => "A",
                               "inserted_by" => "99999"
                             }
                           )
                        |> Repo.insert!()

            {stopid, kyc_entry.id, kyc_entry}
          else
            {reg_exists.stopid, reg_exists.id, reg_exists}
          end
          with {:ok, _document_up_response} <- fourstop_upload_doc(commanall_id, stopid, kyc_entry_id, kyc_verify, type, doc_id) do
            {:ok, "all done"}
          else
            {:error_4s_upload_doc, _response} ->
              {:error, "4S DOC Upload Failed"}
            {:error, _response} ->
              {:error, "Document not available"}
            {:error_status, data_response} ->
              error_message = FourstopErrormessages.error_messages(data_response["status"])
              {:error, error_message}
          end

        else
          {:error_4s_registration, _response} ->
            {:error, "Registration Failed"}
          {:error, _response} ->
            {:error, "User not found"}
          {:error_status, data_response} ->
            error_message = FourstopErrormessages.error_messages(data_response["status"])
            {:error, error_message}
        end
    end
  end

  def pre_start_checks(commanall_id, type, user) do
    query = case type do
      "E" -> Repo.get_by(Fourstop, commanall_id: commanall_id)
      "D" -> Repo.get_by(Fourstop, commanall_id: commanall_id, director_id: user.id)
    end

    case query do
      nil -> {nil, nil, nil}
      kyc_verify ->
        {kyc_verify, kyc_verify.request, kyc_verify.request}
    end
  end

  def fourstop_registration_initialise(commanall_id, user, dir_id) do
    userdata = cond do
      !is_nil(user.company_id) and is_nil(user.employee_id) -> Repo.one from d in Directors, where: d.company_id == ^user.company_id and d.id == ^dir_id,
                                                                                             left_join: dr in assoc(d, :addressdirectors),
                                                                                             left_join: c in assoc(d, :contactsdirectors),
                                                                                             where: c.is_primary == "Y",
                                                                                             select: %{
                                                                                               id: d.id,
                                                                                               title: d.title,
                                                                                               first_name: d.first_name,
                                                                                               middle_name: d.middle_name,
                                                                                               last_name: d.last_name,
                                                                                               gender: d.gender,
                                                                                               birth_date: d.date_of_birth,
                                                                                               address_line_one: dr.address_line_one,
                                                                                               address_line_two: dr.address_line_two,
                                                                                               town: dr.town,
                                                                                               post_code: dr.post_code,
                                                                                               mobile_number: c.contact_number,
                                                                                               email_id: ^user.email_id
                                                                                             }
      !is_nil(user.employee_id) ->   Repo.one from commanall in Commanall, where: commanall.id == ^commanall_id,
                                                                           left_join: address in assoc(commanall, :address),
                                                                           where: address.is_primary == "Y",
                                                                           left_join: c in assoc(commanall, :contacts),
                                                                           where: c.is_primary == "Y",
                                                                           left_join: e in assoc(commanall, :employee),
                                                                           limit: 1,
                                                                           select: %{
                                                                             id: e.id,
                                                                             email_id: commanall.email_id,
                                                                             address_line_one: address.address_line_one,
                                                                             address_line_two: address.address_line_two,
                                                                             city: address.city,
                                                                             post_code: address.post_code,
                                                                             county: address.county,
                                                                             town: address.town,
                                                                             mobile_number: c.contact_number,
                                                                             employee_id: e.id,
                                                                             title: e.title,
                                                                             first_name: e.first_name,
                                                                             last_name: e.last_name,
                                                                             middle_name: e.middle_name,
                                                                             birth_date: e.date_of_birth,
                                                                             gender: e.gender,
                                                                             company_id: e.company_id
                                                                           }

    end

    if !is_nil(userdata) do
      country = Repo.get_by(Countries, id: 53)
      user_name = "#{userdata.first_name} #{userdata.last_name}"
      user_number = Commontools.getUniqueNumber(commanall_id, 15)
      today = Date.to_string(Date.utc_today())
      device_fingerprint_type = 1
      pfc_status = 3
      pfc_type = 1
      ex_ip_address = if !is_nil(user.ip_address) do
        Poison.decode!(user.ip_address)["ex_ip"]
      else
        nil
      end

      postdata = [
        user_name: user_name,
        user_number: user_number,
        reg_date: today,
        reg_ip_address: ex_ip_address,
        device_fingerprint_type: device_fingerprint_type,
        pfc_status: pfc_status,
        pfc_type: pfc_type,
        'customer_information["city"]': userdata.town,
        'customer_information["country"]': country.country_iso_2,
        'customer_information["dob"]': "#{userdata.birth_date}",
        'customer_information["email"]': userdata.email_id,
        'customer_information["first_name"]': userdata.first_name,
        'customer_information["last_name"]': userdata.last_name,
        'customer_information["gender"]': userdata.gender,
        'customer_information["phone1"]': userdata.mobile_number,
        'customer_information["postal_code"]': userdata.post_code,
        'customer_information["province"]': "",
      ]
      case FourstopLibrary.fregister(commanall_id, postdata) do
        {:ok, data_response} ->
          rspnse = Poison.decode!(data_response)
          if rspnse["status"] < 0 do
            {:error_status, data_response}
          else
            {:ok, data_response, "4Stop Registration", data_response, userdata}
          end
        {:error, error_response} -> {:error_4s_registration, error_response}
      end
    else
      {:error, "User not found!."}
    end
  end

  def fourstop_upload_doc(commanall_id, stopid, _kyc_entry_id, _kyc_verify, type, doc_id) do
    # start document upload on 4stop
    #    image_bucket = Application.get_env(:violacorp, :aws_s_bucket)
    #    mode = Application.get_env(:violacorp, :aws_mode)
    #    region = Application.get_env(:violacorp, :aws_s_region)
    #    aws_url = "https://#{image_bucket}.#{region}/#{mode}/"

    id_document = case type do
      "D" ->
        comp_id = Repo.one(from cm in Commanall, where: cm.id == ^commanall_id, select: cm.company_id)
        Repo.one from d in Directors, where: d.company_id == ^comp_id and d.is_primary == "Y",
                                      left_join: kyc in assoc(d, :kycdirectors),
                                      where: kyc.type == "I" and kyc.id == ^doc_id,
                                      limit: 1,
                                      select: %{
                                        id: kyc.id,
                                        documenttype_id: kyc.documenttype_id,
                                        document_number: kyc.document_number,
                                        expiry_date: kyc.expiry_date,
                                        issue_date: kyc.issue_date,
                                        country: kyc.country,
                                        file_location: kyc.file_location,
                                        file_name: kyc.file_name
                                      }
      "E" -> Repo.one from k in Kycdocuments,
                      where: k.commanall_id == ^commanall_id and k.id == ^doc_id and k.type == "I",
                      select: %{
                        id: k.id,
                        documenttype_id: k.documenttype_id,
                        document_number: k.document_number,
                        expiry_date: k.expiry_date,
                        file_location: k.file_location,
                        issue_date: k.issue_date,
                        file_name: k.file_name
                      }
    end

    if !is_nil(id_document) and !is_nil(id_document.file_location) do
      #      file_data = Poison.decode!(id_document.file_location)
      file_name = if is_nil(id_document.file_name) do
        "#{Commontools.getUniqueNumber(commanall_id, 15)}"
      else
        id_document.file_name
      end


      file_url = id_document.file_location
      %HTTPoison.Response{body: body} = HTTPoison.get!(file_url)
      content = Base.encode64(body)
      _user_name = "Simon Jenkins"
      _user_number = Commontools.getUniqueNumber(commanall_id, 15)
      customer_registration_id = stopid

      rep_dat = String.replace(content, "/9j/", "")
      doc_data = "data:image/jpeg;base64 #{rep_dat}"

      postdata = [
        {"", customer_registration_id, {"form-data", [{"name", "\"customer_registration_id\""}]}, []},
        {
          "doc",
          body,
          {
            "form-data",
            [
              {"name", "\"doc\""},
              {"filename", "\"#{file_name}\""}
            ]
          },
          [{"Content-Type", doc_data}]
        }
      ]

      case FourstopLibrary.document_upload(commanall_id, postdata) do
        {:ok, data_response} ->
          refrence_id = Poison.decode!(data_response)
                        |> List.first()
          {doc, doc_response} = case Repo.get_by(Fourstopcallback, stopid: stopid) do
            nil -> {nil, [
              %{
                doc_id: id_document.id,
                response: Poison.decode!(data_response),
                reference_id: refrence_id["reference_id"],
                status: "P",
                date: "#{NaiveDateTime.utc_now()}"
              }
            ]}
            fc ->
              dc_new = Poison.decode!(fc.response)
                       |> Enum.concat(
                            [
                              %{
                                doc_id: id_document.id,
                                response: Poison.decode!(data_response),
                                reference_id: refrence_id["reference_id"],
                                status: "P",
                                date: "#{NaiveDateTime.utc_now()}"
                              }
                            ]
                          )
              {fc, dc_new}
          end

          if is_nil(doc) do
            %Fourstopcallback{}
            |> Fourstopcallback.changeset(
                 %{
                   "stopid" => stopid,
                   "request" => "4Stop Doc Upload",
                   "response" => Poison.encode!(doc_response),
                   "reference_id" => refrence_id["reference_id"]
                 }
               )
            |> Repo.insert!()
          else
            doc
            |> Fourstopcallback.changeset(
                 %{
                   "response" => Poison.encode!(doc_response),
                   "reference_id" => refrence_id["reference_id"]
                 }
               )
            |> Repo.update()
          end


          if type == "E" do
            %Kycdocuments{id: id_document.id}
          else
            %Kycdirectors{id: id_document.id}
          end   |> Ecto.Changeset.cast(
                     %{
                       "status" => "4P"
                     },
                     [:status]
                   )
          |> Repo.update()

          rspnse = Poison.decode!(data_response) |> List.first()
          if rspnse["status"] < 0 do
            {:error_status, data_response}
          else
            {:ok, data_response}
          end
        {:error, error_response} -> {:error_4s_upload_doc, error_response}
      end
    else
      {:error, "Document not available"}
    end
  end

end