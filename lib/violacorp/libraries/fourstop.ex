defmodule Violacorp.Libraries.Fourstop do

  alias Violacorp.Repo
  alias Violacorp.Schemas.Thirdpartylogs

  def fregister(party_id, postdata_params) do
    get_url = Application.get_env(:violacorp, :fourstop_url_2)
    url = "#{get_url}customerregistration"
    merchant_id = Application.get_env(:violacorp, :fourstop_merchant_id)
    password = Application.get_env(:violacorp, :fourstop_password)

    postdata = Enum.concat(postdata_params, [merchant_id: merchant_id, password: password])

    headers = %{
      "content-type" => "multipart/form-data",
      "cache-control" => "no-cache",
    }
    response = post_http(url, headers, postdata)
    {act_response, status} =  case response do
      {:ok, body} ->
        rspnse = Poison.decode!(body)
        if rspnse["status"] < 0 do
          {body, "F"}
        else
          {body, "S"}
        end
      {:error, body} -> {body, "F"}
    end

    %Thirdpartylogs{}
    |> Thirdpartylogs.changeset(
         %{
           "commanall_id" => party_id,
           "section" => "4STOP",
           "method" => "POST",
           "request" => ~s({"request": "4S Registration"}),
           "response" => act_response,
           "status" => status,
           "inserted_by" => "99999"
         }
       )
    |> Repo.insert()
    response
  end

  def update_registration(params) do
    get_url = Application.get_env(:violacorp, :fourstop_url_2)
    url = "#{get_url}updateregistration"
    merchant_id = Application.get_env(:violacorp, :fourstop_merchant_id)
    password = Application.get_env(:violacorp, :fourstop_password)
    pfc_status = 1
    reason = "For Testing"
    internal_trans_id = params["internal_trans_id"]

    headers = %{
      "content-type" => "multipart/form-data",
      "Content-Type" => "application/json",
      "cache-control" => "no-cache",
    }
    postdata = [merchant_id: merchant_id,
      password: password,
      internal_trans_id: internal_trans_id,
      pfc_status: pfc_status,
      reason: reason
    ]

    post_http(url, headers, postdata)
  end

  def document_upload(party_id, postdata_params) do

    get_url = Application.get_env(:violacorp, :fourstop_url_2)
    url = "#{get_url}documentIdVerify"
    merchant_id = Application.get_env(:violacorp, :fourstop_merchant_id)
    password = Application.get_env(:violacorp, :fourstop_password)

    postdata = Enum.concat(postdata_params, [{"", merchant_id, {"form-data", [{"name", "\"merchant_id\""}]}, []},
      {"", "1", {"form-data", [{"name", "\"method\""}]}, []},
      {"", password, {"form-data", [{"name", "\"password\""}]}, []}])
    response = doc_post_http(url, {:multipart, postdata})
    {act_response, status} =  case response do
      {:ok, body} ->
        rspnse = Poison.decode!(body) |> List.first()
        if rspnse["status"] < 0 do
          {body, "F"}
        else
          {body, "S"}
        end
      {:error, body} -> {body, "F"}
    end

    %Thirdpartylogs{}
    |> Thirdpartylogs.changeset(
         %{
           "commanall_id" => party_id,
           "section" => "4STOP DOC UPLOAD",
           "method" => "POST",
           "request" => ~s({"request": "Document upload"}),
           "response" => act_response,
           "status" => status,
           "inserted_by" => "99999"
         }
       )
    |> Repo.insert()

    response
  end


  defp post_http(url, header, body) do
    response = HTTPoison.post(url, {:form, body}, header, [recv_timeout: 400_000])
    case response do
      {:ok, %{status_code: 200, body: body}} -> {:ok, body}
      {:ok, %{status_code: 404}} -> {:error, "404 not found!"}
      {:ok, %{status_code: 401, body: body}} -> {:error, body}
      {:ok, %{status_code: 400, body: body}} -> {:error, body}
      {:ok, %{status_code: 500, body: body}} -> {:error, body}
      {:error, %{reason: reason}} -> {:error, reason}
    end
  end

  defp doc_post_http(url, body) do
    response = HTTPoison.post(url, body, [recv_timeout: 50_400_000])
    case response do
      {:ok, %{status_code: 200, body: body}} -> {:ok, body}
      {:ok, %{status_code: 404}} -> {:error, "404 not found!"}
      {:ok, %{status_code: 401, body: body}} -> {:error, body}
      {:ok, %{status_code: 400, body: body}} -> {:error, body}
      {:ok, %{status_code: 500, body: body}} -> {:error, body}
      {:error, %{reason: reason}} -> {:error, reason}
    end
  end


end