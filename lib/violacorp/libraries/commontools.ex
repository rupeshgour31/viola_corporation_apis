defmodule Violacorp.Libraries.Commontools do

  require Logger
  import Ecto.Query
  alias Violacorp.Repo
  @moduledoc "Commontools Library i.e get_lastfour; random number, random string, get_fromPostcode"

  alias Violacorp.Schemas.Contacts
  alias Violacorp.Schemas.Contactsdirectors
  alias Violacorp.Schemas.Kyclogin
  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Administratorusers
  alias Violacorp.Schemas.Countries

  @accomplish_country_code Application.get_env(:violacorp, :accomplish_country_code)
  @country_code Application.get_env(:violacorp, :country_code)
  def ipaddress(conn, _params) do
    to_string(:inet_parse.ntoa(conn.remote_ip))
  end

  #  SEND STRING GET STRING VALUE BACK
  def lastfour(params) do

    #OLD METHOD USING STRING TO INT
    #    number  = String.to_integer(params) |> Integer.digits()
    #    Enum.take(number, -4) |> Integer.undigits()

    #NEW METHOD USING STRING SPLIT
    params
    |> String.split("", trim: true)
    |> Enum.take(-4)
    |> Enum.join()
  end

  def sort_amount(amount, decimal_points, desired_datatype) do

    from_type = cond do
      is_integer(amount) ->
        "integer"
      is_float(amount) ->
        "float"
      Decimal.decimal?(amount) ->
        "decimal"
      true ->
        "string"
    end
    convert_amount(amount, from_type, desired_datatype, decimal_points)
  end

  defp convert_amount(amount, from, to, decimal_points) do
    case from do
      "decimal" -> case to do
                     "decimal" ->
                       Decimal.round(amount, decimal_points, :down)
                     "integer" ->
                       if decimal_points <= 0 do
                         Decimal.to_integer(amount)
                       else
                         amount / 1
                         |> Float.round(decimal_points)
                       end

                     "string" ->
                       Decimal.to_string(amount)
                     "float" ->
                       amount / 1
                       |> Float.round(decimal_points)
                   end
      "integer" ->
        case to do
          "decimal" ->
            Decimal.new(amount)
            |> Decimal.round(decimal_points)
          "integer" ->
            if decimal_points <= 0 do
              amount
            else
              amount / 1
              |> Float.round(decimal_points)
            end
          "string" ->
            amount / 1
            |> :erlang.float_to_binary([decimals: decimal_points])
          "float" ->
            amount / 1
            |> Float.round(decimal_points)
        end
      "string" -> case to do
                    "decimal" ->
                      Decimal.new(amount)
                      |> Decimal.round(decimal_points, :down)
                    "integer" ->
                      if decimal_points == 0 do
                        String.to_float(amount)
                        |> Kernel.trunc()
                      else
                        String.to_float(amount)
                        |> Float.round(decimal_points)
                      end
                    "string" ->
                      if amount =~ ".", do: amount, else: "#{amount}.00"
                    "float" ->
                      String.to_float(amount)
                      |> Float.round(decimal_points)
                  end
      "float" -> case to do
                   "decimal" ->
                     Decimal.new(amount)
                     |> Decimal.round(decimal_points, :down)
                   "integer" ->
                     if decimal_points == 0 do
                       Kernel.trunc(amount)
                     else
                       Float.round(amount, decimal_points)
                     end
                   "string" ->
                     :erlang.float_to_binary(amount, [decimals: decimal_points])
                   "float" ->
                     Float.round(amount, decimal_points)
                 end
    end
  end

  def randnumber(length) do
    otp_mode = Application.get_env(:violacorp, :otp_mode)
    _response = if otp_mode == "dev" and length == 6 do
      code = "111111"
      String.to_integer(code)
    else
      chars = "123456789"
              |> String.split("", trim: true)
      reduced = Enum.reduce(
        (1..length),
        [],
        fn (_i, acc) ->
          [Enum.random(chars) | acc]
        end
      )
      reduced
      |> Enum.join()
      |> String.to_integer()
    end

  end

  def randnumberlimit(length) do
    chars = "123456789"
            |> String.split("", trim: true)
    reduced = Enum.reduce(
      (1..length),
      [],
      fn (_i, acc) ->
        [Enum.random(chars) | acc]
      end
    )
    reduced
    |> Enum.join()
    |> String.to_integer()
  end

  def generate_password() do
    lower = [
      "a",
      "b",
      "c",
      "d",
      "e",
      "f",
      "g",
      "h",
      "i",
      "j",
      "k",
      "l",
      "m",
      "n",
      "o",
      "p",
      "q",
      "r",
      "s",
      "t",
      "u",
      "v",
      "w",
      "x",
      "y",
      "z"
    ]
    upper = [
      "A",
      "B",
      "C",
      "D",
      "E",
      "F",
      "G",
      "H",
      "I",
      "J",
      "K",
      "L",
      "M",
      "N",
      "O",
      "P",
      "Q",
      "R",
      "S",
      "T",
      "U",
      "V",
      "W",
      "X",
      "Y",
      "Z"
    ]
    number = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
    special = ["!", "#", "$", "%", "&", "(", ")", "*", "+", ",", "-", ".", ":", ";"]

    "#{Enum.random(upper)}#{Enum.random(lower)}#{Enum.random(lower)}#{Enum.random(lower)}#{Enum.random(lower)}#{
      Enum.random(lower)
    }#{Enum.random(number)}#{Enum.random(special)}"
  end

  def capitalize(string) do
    if is_nil(string) do
      string
    else
      string
      |> String.split(~r{ })
      |> Enum.map(&String.capitalize(&1))
      |> Enum.join(" ")
    end
  end

  def is_mobile_number(mobile_number) do
    with false <- is_nil(mobile_number),
         false <- mobile_number == ""
      do
      case String.first(mobile_number) do
        "0" -> case String.at(mobile_number, 1) do
                 "7" -> true
                 _ -> false
               end
        "7" -> true
        _ -> false
      end
    else
      true -> false
    end
  end

  def trim_all_whitespaces(string) do
    if is_nil(string) do
    else
      string
      |> String.split(~r{ })
      |> Enum.map(&String.trim(&1))
      |> Enum.join(" ")
    end
  end


  def transaction_type(type) do
    case type do
      "A2O" -> "Fee"
      "A2C" -> "TopUp"
      "C2A" -> "Move Fund"
      "C2O" -> "Point of sale"
      "C2I" -> "Internet"
      "C2F" -> "Fee"
      "B2A" -> "Account TopUp"
      "A2A" -> "Account To Account"
    end
  end

  def status(type) do
    case type do
      "A" -> "Active"
      "D" -> "Deactive"
      "B" -> "Block"
    end
  end

  def beneficiary_type(type) do
    case type do
      "E" -> "External"
      "I" -> "Internal"
    end
  end

  def remark(data) do
    ###send transaction_type as type and transaction_remark as remark and description too.
    if is_nil(data.remark) do
      %{"from" => nil, "to" => nil}
    else
      description = "#{data.description}"
      #        response_notes = String.split(description, "- on ", trim: true)
      #        notes_last_value = response_notes
      #                           |> Enum.take(-1)
      #                           |> Enum.join()
      #        output = String.slice(notes_last_value, 8..-1)

      #        val = String.replace(description, ~r[((.*?)(- on).*(- ))], "")
      val = String.replace(description, ~r[((.*?)(- on).(.+?-))], "")
      val = String.replace(val, ~r/\s+/, " ")
      val = String.replace(val, "General Credit: ", " ")
      output = String.trim(val)

      map = case Poison.decode(data.remark) do
        {:ok, datas} -> datas
        {:error, _datas} -> data.remark
      end
      from = case data.type do
        "A2C" -> "#{map["from"]}"
        "C2A" -> "#{map["to"]}"
        "C2O" -> "#{output}"
        "C2I" -> "#{output}"
        "C2F" -> "Remark: #{output}"
        "B2A" -> "#{output}"
        "A2O" -> "#{output}"
        "A2A" -> map["from"]
      end
      to = case data.type do
        "A2C" -> "XXXX #{map["to"]}"
        "C2A" -> "XXXX #{map["from"]}"
        "C2O" -> "XXXX #{map["from"]}"
        "C2I" -> "XXXX #{map["from"]}"
        "C2F" -> "XXXX #{map["from"]}"
        "B2A" -> "Account TopUp"
        "A2O" -> "Fee"
        "A2A" -> map["to"]
      end
      %{"from" => from, "to" => to}
    end
  end

  def transaction_mode(mode) do
    case mode do
      "D" -> "Debit"
      "C" -> "Credit"
    end
  end

  def transaction_status(status) do
    case status do
      "S" -> "Success"
      "P" -> "Pending"
      "F" -> "Failed"
      "R" -> "Refund"
      "V" -> "Void"
      "E" -> "Error"
      "C" -> "Cancelled"
    end
  end

  def getTagStatus() do

    [
      %{status: "Inbound Call"},
      %{status: "Outbound Call"},
      %{status: "Inbound Email"},
      %{status: "Outbound Email"},
      %{status: "Document request"},
      %{status: "Account suspended"},
      %{status: "Customer failed Security questions"},
      %{status: "Complaint"},
      %{status: "System Issue"},
      %{status: "Fees"},
      %{status: "Escalated"},
      %{status: "Complement"},
      %{status: "Transaction Rejected"},
      %{status: "OBT Reject"},
      %{status: "Account Suspended"},
      %{status: "Account Closed"},
      %{status: "Completed"},
      %{status: "Others"}
    ]
  end

  def random_string(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64
  end

  def getFromPostcode(params) do

    url = "https://api.getaddress.io/find/#{params}?api-key=#{Application.get_env(:violacorp, :get_address_key)}"

    _response = gets_http(url)
  end

  def getUniqueNumber(user_id, length) do
    currentdatetime = NaiveDateTime.utc_now()
                      |> NaiveDateTime.truncate(:millisecond)
                      |> to_string()
                      |> String.replace(~r/[-.: ]+/, "")
                      |> String.slice(2..14)

    chars = "#{user_id}#{currentdatetime}123456789"
            |> String.replace("0", "")
            |> String.split("", trim: true)

    reduced = Enum.reduce(
      (1..length),
      [],
      fn (_i, acc) ->
        [Enum.random(chars) | acc]
      end
    )
    reduced
    |> Enum.join()
    |> String.to_integer()
  end

  def account_number(account_number) do
    count = String.length("#{account_number}")
    if count < 10 do
      new_count = 10 - String.length("#{account_number}")
      prefix = String.duplicate("0", new_count)
      "#{prefix}#{account_number}"
    else
      account_number
    end
  end

  @doc """
    this function for check unique contact in our system
  """
  def contact_is_unique?(contact_number) do
    check_coman = Repo.one(
      from c in Contacts, where: c.contact_number == ^contact_number, limit: 1, select: c.contact_number
    )
    contact_data = Repo.one(
      from con in Contactsdirectors, where: con.contact_number == ^contact_number, limit: 1, select: con.contact_number
    )
    if is_nil(check_coman) && is_nil(contact_data) do
      "Y"
    else
      "N"
    end
  end

  @doc """
    this function for check unique email in our system
  """
  def email_is_unique?(email_id) do
    check = Repo.one(from k in Kyclogin, where: k.username == ^email_id, limit: 1, select: k.id)
    check_email = Repo.one(from com in Directors, where: com.email_id == ^email_id, limit: 1, select: com.id)
    check_coman = Repo.one(from co in Commanall, where: co.email_id == ^email_id, limit: 1, select: co.id)
    if is_nil(check_email) && is_nil(check) && is_nil(check_coman) do
      "Y"
    else
      "N"
    end
  end

  @doc """
    this function for get accomplish address proof document type id and document type name
  """
  def address_document_type(document_id) do
    case document_id do
      1 -> {"5", "Utility Bill"}
      2 -> {"10", "Council Tax"}
      21 -> {"4", "Driving Licence"}
      4 -> {"7", "Bank Statement"}
      _ -> {"5", "Utility Bill"}
    end
  end

  @doc """
    this function for get accomplish ID document type id and document type name
  """
  def id_document_type(document_id) do
    case document_id do
      19 -> {"4", "Driving Licence"}
      10 -> {"2", "Passport"}
      9 -> {"3", "National ID"}
      _ -> {"3", "National ID"}
    end
  end
  @doc """
    this function for check admin own password
  """
  def checkOwnPassword(password, admin_id) do
    get = Repo.one(from a in Administratorusers, where: a.secret_password == ^password and a.id == ^admin_id)
    if !is_nil(get)do
      {:ok, "Password Matched"}
    else
      {:not_matched, "Invalid Password"}
    end
  end

  def get_acc_country_code(country_id) do
    case Repo.get(Countries, country_id) do
      nil -> [@accomplish_country_code, @country_code]
      data -> [data.accomplish_code, data.country_isdcode]
    end
  end

  defp gets_http(url) do
    case HTTPoison.get(url, [recv_timeout: 50_000]) do
      {:ok, %{status_code: 200, body: body}} -> Poison.decode!(body)
      {:ok, %{status_code: 404}} -> "404 not found!"
      {:ok, %{status_code: 401}} -> "Unauthorized!"
      {:ok, %{status_code: 400}} -> "Bad request!"
      {:ok, %{status_code: 429}} -> "Limit Reached!"
      {:ok, %{status_code: 500}} -> "Getaddress Internal Server Error"
      {:error, %{reason: reason}} -> reason
    end
  end

end
