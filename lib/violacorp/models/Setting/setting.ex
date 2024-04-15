defmodule Violacorp.Models.Setting do
 import Ecto.Query

 alias Violacorp.Repo
 alias Violacorp.Schemas.Countries
 alias Violacorp.Schemas.Currencies
 alias Violacorp.Schemas.Documentcategory
 alias Violacorp.Schemas.Documenttype
 alias Violacorp.Schemas.Departments
# alias Violacorp.Schemas.Thirdpartylogs
# alias Violacorp.Schemas.Companies
 alias Violacorp.Schemas.Versions
 alias Violacorp.Schemas.Projects
 alias Violacorp.Schemas.Appversions
 alias Violacorp.Schemas.Alertswitch
# alias Violacorp.Schemas.Assignproject

 @doc "add country"
 def country_add(params) do

       country = %{
        "country_name" => params["country_name"],
        "country_iso_3" => params["country_iso_3"],
        "country_iso_2" => params["country_iso_2"],
        "country_isdcode" => params["country_isdcode"],
         "status"  => params["status"],
        "inserted_by" => params["inserted_by"]
       }
      changeset = Countries.changeset(%Countries{}, country)
    if changeset.valid? do
        country_name = Repo.one(from c in Countries, where: c.country_name == ^params["country_name"],limit: 1, select: c)
        if is_nil(country_name) do
            country_iso_2 = Repo.one(from c in Countries, where: c.country_iso_2 == ^params["country_iso_2"],limit: 1, select: c)
            if is_nil(country_iso_2) do
                country_iso_3 = Repo.one(from c in Countries, where: c.country_iso_3 == ^params["country_iso_3"],limit: 1, select: c)
                if is_nil(country_iso_3) do
                    country_isdcode = Repo.one(from c in Countries, where: c.country_isdcode == ^params["country_isdcode"],limit: 1, select: c)
                    if is_nil(country_isdcode)do
                        changeset = Countries.changeset(%Countries{}, country)
                        case Repo.insert(changeset) do
                        {:ok, _changeset} -> {:ok, "Record Inserted"}
                        {:error, changeset} -> {:error, changeset}
                        end
                    else
                    {:country_isdcode, "already exist"}
                    end
                else
                {:country_iso_3, "already exist"}
                end
            else
            {:country_iso_2, "already exist"}
            end
        else
        {:country_name, "already exist"}
        end
    else
    {:error, changeset}
    end
 end

 @doc "edit country "
 def edit_country(params) do

     country = Repo.get_by(Countries, id: params["id"])
     if !is_nil(country) do

       check = Repo.all(from c in Countries, where: (c.country_iso_2 == ^params["country_iso_2"] or c.country_iso_3 == ^params["country_iso_3"] or c.country_name == ^params["country_name"])
                                                    and c.id != ^params["id"],
                                             select: c.id)

       case check do
        [] ->
         map = %{
           "country_name" => params["country_name"],
           "country_iso_2" => params["country_iso_2"],
           "country_iso_3" => params["country_iso_3"],
           "status" => params["status"],
           "country_isdcode" => params["country_isdcode"],
         }
         changeset = Countries.changeset(country, map)

         case Repo.update(changeset) do
           {:ok, _changeset} -> {:ok, "Record updated"}
           {:error, changeset} -> {:error, changeset}
         end
       _data ->
         {:error_message, "country already inserted"}
       end
     else
       {:not_found, "Record not found!"}
     end
 end

 @doc "country list"
 def countries_list(_params)do
               _country = Repo.all(from c in Countries, where: c.status == "A",
                                     order_by: [
                                       asc: c.country_name
                                     ],
                       select: %{
                               id: c.id,
                              country_name: c.country_name,
                              status: c.status,
                         country_iso_2: c.country_iso_2,
                         country_iso_3: c.country_iso_3,
                       })
 end

 @doc "get all active company"
 def single_country(params)do
          _country = Repo.one(from c in Countries, where: c.id == ^params["id"],
                                   select: %{
                                             id: c.id,
                                            country_name: c.country_name,
                                            country_iso_2: c.country_iso_2,
                                            country_iso_3: c.country_iso_3,
                                            status: c.status,
                                            country_isdcode: c.country_isdcode

          })
 end

 @doc "get all Deactive company"
 def active_country(params)do
   filtered = params
              |> Map.take(~w(country_isdcode  country_name status ))
              |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
   _country = (from c in Countries, where: c.status == "A",
               having: ^filtered,
                                   order_by: [
                                     asc: c.country_name
                                   ]
               )
             |>Repo.paginate(params)
 end

 @doc "add currency"
 def add_currency(params,admin_id) do

     currency = %{
       countries_id:  params["countries_id"],
       currency_name: params["currency_name"],
       currency_code: params["currency_code"],
       currency_symbol: params["currency_symbol"],
       status: params["status"],
       inserted_by: "99999#{admin_id}"
     }
    check = Repo.all(from c in Currencies, where:  c.currency_symbol == ^params["currency_symbol"] or c.currency_code == ^params["currency_code"] or
                                                  c.currency_name == ^params["currency_name"],
                                          select: c.id)

    if check == [] do
       changeset = Currencies.changeset(%Currencies{}, currency)
       case Repo.insert(changeset) do
         {:ok, _changeset} ->   {:ok, "Record Inserted"}
         {:error, changeset} -> {:error, changeset}
       end
    else
       {:error_message, "Currency already exists"}
    end
 end

 @doc "update currency"

 def edit_currency(params) do

         currency = Repo.get_by(Currencies, id: params["id"])
          if is_nil(currency)do
               {:not_found, "Record not found!"}
          else
               currency_map = %{
                 currency_name: params["currency_name"],
                 currency_code: params["currency_code"],
                 currency_symbol: params["currency_symbol"],
                 countries_id:  params["countries_id"],
                 status: params["status"]
               }
               changeset = Currencies.changeset(currency,currency_map)
               if changeset.valid? do

                 check = Repo.all(from c in Currencies, where: (c.currency_symbol == ^params["currency_symbol"] or c.currency_code == ^params["currency_code"] or
                                                               c.currency_name == ^params["currency_name"]) and c.id != ^params["id"],
                                                        select: c.id)

                 case check do
                   [] ->
                     changeset = Currencies.changeset(currency,currency_map)
                     case Repo.update(changeset) do
                       {:ok, _changeset} -> {:ok, "Record updated"}
                       {:error, changeset} -> {:error, changeset}
                     end
                   _data ->
                     {:error_message, "Currency already exists"}
                 end
               else
                 {:error, changeset}
               end
         end
 end

 @doc "add document category"
 def add_document_category(params)do
    doc_category = %{
      "title" => params["title"],
      "code" => params["code"],
      "inserted_by" => params["inserted_by"],
    }
   check = Repo.one(from d in Documentcategory, where: d.title == ^params["title"] or d.code == ^params["code"], limit: 1, select: d.id)
   case check do
    nil ->
     changeset = Documentcategory.changeset(%Documentcategory{}, doc_category)
     case Repo.insert(changeset) do
       {:ok, _changeset} ->   {:ok, "DocumentCategory add successfully."}
       {:error, changeset} -> {:error, changeset}
     end
    _data -> {:error_message, "DocumentCategory already exists"}
   end
 end

 @doc "edit document category"
 def edit_documentcategory(params) do

   documentcategory = Repo.get_by(Documentcategory, id: params["id"])

   if !is_nil(documentcategory) do
       doc_category =
       %{
         "title" => params["title"],
         "code" => params["code"],
       }
     check = Repo.all(from d in Documentcategory, where: (d.title == ^params["title"] or d.code == ^params["code"]) and d.id != ^params["id"], select: d.id)
     case check do
       [] ->
         changeset = Documentcategory.changeset(documentcategory, doc_category)
         case Repo.update(changeset) do
           {:ok, _changeset} -> {:ok, "Record updated"}
           {:error, changeset} -> {:error, changeset}
         end
       _data -> {:error_message, "DocumentCategory already exists"}
     end
   else
     {:not_found, "Record not found!"}
   end
 end

 @doc "get all document category"
def get_all_documentCategory(_params)do
                  _category =Repo.all(from c in Documentcategory, select: %{ id: c.id,title: c.title, code: c.code})
 end

 @doc "add new document type"
 def add_document_type(params) do

    document_type = %{
                  "title"  =>              params["title"],
                  "code" =>                params["code"],
                  "description" =>         params["description"],
                  "documentcategory_id" => params["documentcategory_id"],
                  "inserted_by" =>         params["inserted_by"]
    }
   check = Repo.all(from d in Documenttype, where: d.title == ^params["title"] or d.code == ^params["code"], select: d.id)
   case check do
    [] ->
       changeset = Documenttype.changeset(%Documenttype{}, document_type)
       case Repo.insert(changeset)do
          {:ok, _changeset} -> {:ok, "Record inserted"}
          {:error, changeset}-> {:error, changeset}
        end
    _data -> {:error_message, "DocumentType already exists"}
   end
 end

 @doc "edit document type"
 def edit_document_type(params) do

    document_type = Repo.get_by(Documenttype, id: params["id"])
     map = %{
             "title" => params["title"],
             "code" => params["code"],
             "description" => params["description"],
             "documentcategory_id" => params["documentcategory"],
     }
     if !is_nil(document_type)do
        check = Repo.all(from d in Documenttype, where: (d.title == ^params["title"] or d.code == ^params["code"]) and d.id != ^params["id"], select: d.id)
        case check do
          [] ->
              changeset = Documenttype.changeset(document_type, map)
              case Repo.update(changeset)do
                {:ok, _changeset}->     {:ok, "Record Updated"}
                {:error, changeset} -> {:error, changeset}
              end
          _data -> {:error_message, "DocumentType already exists"}
        end
     else
      {:not_found, "Record not found!"}
     end
   end

 @doc "get ALL document type"
 def get_document(params)do
             document_type = params
              |> Map.take(~w(title  code))
              |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
              document_category = params["category"]
             _document_type = (from d in Documenttype, having: ^document_type,
                             order_by: [asc: d.title],
                             left_join: c in assoc(d, :documentcategory),
                             where: c.id == d.documentcategory_id and like(c.category, ^"%#{document_category}%"),
                         select: %{title: d.title,
                                   description: d.description,
                                   inserted_at: d.inserted_at,
                                   code: d.code,
                                   category: c.title}
                          )
             |>Repo.paginate(params)
 end

 @doc "add  new  department"
  def add_department(params)do
       department = %{
         "company_id" => params["company_id"],
         "department_name" => params["department_name"],
         "number_of_employee" => params["number_of_employee"],
         "status" => params["status"],
         "inserted_by" => params["inserted_by"]
       }
       check = Repo.all(from d in Departments, where: d.department_name == ^params["department_name"], select: d.id)
    case check do
         [] ->
           changeset = Departments.changeset(%Departments{}, department)
           case Repo.insert(changeset)do
             {:ok, _changeset} -> {:ok, "Record inserted"}
             {:error, changeset}-> {:error, changeset}
           end
         _check -> {:error_message, "Department already exists"}
       end
 end

 @doc "edit department"
 def edit_departments(params)do
   department = Repo.get_by(Departments, id: params["id"])
      if !is_nil(department)do
        map = %{department_name: params["department_name"],status:  params["status"]}

        check = Repo.all(from d in Departments, where: d.department_name == ^params["department_name"] and d.id != ^params["id"], select: d.id)
        case check do
          [] ->
            changeset = Departments.changeset(department, map)
            case Repo.update(changeset)do
              {:ok, _changeset}->     {:ok, "Record Updated"}
              {:error, changeset} -> {:error, changeset}
            end
          _check -> {:error_message, "Department already exists"}
        end
      else
          {:not_found, "Record not found!!"}
     end
 end

 @doc"edit versions"
 def edit_version(params) do

   data = Repo.get_by(Versions, id: params["id"])

   if !is_nil(data) do

     add = %{
          android: params["android"],
          iphone: params["iphone"],
          live_email: params["live_email"],
          dev_email: params["dev_email"],
          ekyc: params["ekyc"],
          api_enable: params["api_enable"]
       }

     changeset = Versions.changeset(data, add)
     case Repo.update(changeset) do
       {:ok, _ad} -> {:ok, "version updated"}
       {:error, changeset} -> {:error, changeset}
     end
   else
     {:not_found, "Record not found!!"}
   end
 end

@doc"get version detail"

 def get_version(params)do

   _get = (from v in Versions, select: %{
                    android: v.android,
                    iphone: v. 	iphone,
                    devlopment_email: v.dev_email,
                    live_email: v.live_email,
                    ekyc: v.ekyc,
                    id: v.id
   })
   |>Repo.paginate(params)
 end
@doc" ADD NEW PROJECT"

 def add_project(params,admin_id) do
     project = %{
       "company_id" => params["company_id"],
       "project_name" => params["project_name"],
       "start_date" => params["start_date"],
       "inserted_by" =>"99999#{admin_id}"
     }
   changeset = Projects.changeset(%Projects{}, project)
   if changeset.valid? do
     check = Repo.all(from p in Projects, where: p.company_id == ^params["company_id"] and p.project_name == ^params["project_name"], select: p.id)
     case check do
       [] ->
            case Repo.insert(changeset)do
              {:ok, _data} -> {:ok, "Success,Record inserted."}
              {:error, changeset}-> {:error, changeset}
            end
       _check -> {:error_message, "Project already exists"}
     end
   else
     {:error, changeset}
   end
 end

 @doc" ADD APPLICATION VERSION"

 def add_appVersion(params,admin_id) do
         map = %{"type" => params["type"], "version" => params["version"], "inserted_by" => admin_id, "is_active" => "Y"}
         changeset =  Appversions.changeset(%Appversions{}, map)
         if changeset.valid? do
             type = map["type"]
               check_version = Repo.one(from v in Appversions, where: v.type == ^type and v.is_active == ^"Y")
               if is_nil(check_version) do
                       changeset_insert = Appversions.changeset(%Appversions{}, map)
                       case Repo.insert(changeset_insert)do
                         {:ok, _changeset_insert} -> {:ok, "Record inserted"}
                         {:error, changeset_insert}-> {:error, changeset_insert}
                       end
                       else
                       is_active = %{"is_active" => "N" , "inserted_by" => admin_id}
                       changeset = Appversions.changesetUpdate(check_version, is_active)
                       case Repo.update(changeset)do
                           {:ok, _changeset} ->
                              changeset_insert = Appversions.changeset(%Appversions{}, map)
                             case Repo.insert(changeset_insert)do
                               {:ok, _changeset_insert} -> {:ok, "Record inserted"}
                               {:error, changeset_insert}-> {:error, changeset_insert}
                             end
                           {:ok, "Record inserted"}
                           {:error, changeset}-> {:error, changeset}
                       end
               end
            else
             {:error, changeset}
          end
 end

  @doc"END OF MODULE"
  def add_alert_switch(params, admin_id)do
     check_section = Repo.get_by(Alertswitch, section: params["section"])
     if is_nil(check_section) do
       alert_switch = %{
         "section" => params["section"],
         "email"  => params["email"],
         "notification"  => params["notification"],
         "sms"   => params["sms"],
         "subject"   => params["subject"],
         "templatefile"   => params["templatefile"],
         "sms_body"   => params["sms_body"],
         "notification_body"   => params["notification_body"],
         "layoutfile"   => params["layoutfile"],
         "inserted_by" =>  admin_id
       }
       changeset = Alertswitch.changeset(%Alertswitch{}, alert_switch)
       case Repo.insert(changeset) do
         {:ok, _message} -> {:ok, "Section Added"}
         {:error, changeset} -> {:error, changeset}
       end
     else
       {:exist_section, "already exist"}
     end
  end
 def updateProjectDetail(params) do
   getproject = Repo.get_by(Projects, id: params["id"])
   if !is_nil(getproject) do
     project = %{
       "project_name" => params["project_name"],
       "start_date" => params["start_date"],
     }
     changeset = Projects.changeset(getproject, project)
     case Repo.update(changeset) do
       {:ok, _project} -> {:ok, "Project Details Updated."}
       {:error, changeset} -> {:error, changeset}
     end
   else
     {:error_message, "Record Not Found."}
   end
 end
end