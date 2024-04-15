defmodule ViolacorpWeb.Main.V3RegistrationController do
  use ViolacorpWeb, :controller

  alias Violacorp.Models.Registrationv3

  alias Violacorp.Libraries.Sectors


  def step_one(conn, params) when map_size(params) == 0 do
    conn
    |> render(ViolacorpWeb.ErrorView, "somethingWrong.json")
  end

  @doc "Initial Details"
  def step_one(conn, params) do

    # DEFINE IP ADDRESS
    ex_ip_address = conn.remote_ip
                    |> Tuple.to_list
                    |> Enum.join(".")

    ht_ip_address = get_req_header(conn, "ip_address")
                    |> List.first

    ip_address_merge = %{ex_ip: ex_ip_address, ht_ip: ht_ip_address}
                       |> Poison.encode!()

    ip_address = %{"ip_address" => ip_address_merge}

    reg_request = Map.merge(params, ip_address)


    case Registrationv3.stepOne(reg_request) do
      {:ok, data} ->
        conn
        |> put_status(:ok)
        |> put_view(ViolacorpWeb.ErrorView)
        |> json(%{status_code: 200, data: data})
      {:error, changeset} ->
        conn
        |> put_status(:not_acceptable)
        |> put_view(ViolacorpWeb.ErrorView)
        |> render("error.json", changeset: changeset)
      {:not_acceptable, message} ->
        conn
        |> put_status(:not_acceptable)
        |> put_view(ViolacorpWeb.ErrorView)
        |> render("4002.json", message: message)
      {:mobile_number_error, message} ->
        conn
        |> put_status(:not_acceptable)
        |> put_view(ViolacorpWeb.ErrorView)
        |> render("invalid.json", error: %{contact_number: message})
      {:email_error, message} ->
        conn
        |> put_status(:not_acceptable)
        |> put_view(ViolacorpWeb.ErrorView)
        |> render("invalid.json", error: %{emailId: message})
    end

  end


  def step_two(conn, params) when map_size(params) == 0 do
    conn
    |> render(ViolacorpWeb.ErrorView, "somethingWrong.json")
  end

  @doc "Verify Email OTP"
  def step_two(conn, params) do
    case Registrationv3.stepTwo(params) do
      {:ok, data} ->
        conn
        |> put_status(:ok)
        |> put_view(ViolacorpWeb.ErrorView)
        |> json(%{status_code: 200, message: data})
      {:error, changeset} ->
        conn
        |> put_status(:not_acceptable)
        |> put_view(ViolacorpWeb.ErrorView)
        |> render("error.json", changeset: changeset)
      {:not_acceptable, message} ->
        conn
        |> put_status(:not_acceptable)
        |> put_view(ViolacorpWeb.ErrorView)
        |> render("4002.json", message: message)
    end
  end

  @doc "Verify Email OTP"
  def step_two_v2(conn, params) do
    case Registrationv3.stepTwoV2(params) do
      {:ok, data} ->
        conn
        |> put_status(:ok)
        |> put_view(ViolacorpWeb.ErrorView)
        |> json(%{status_code: 200, message: data})
      {:error, changeset} ->
        conn
        |> put_status(:not_acceptable)
        |> put_view(ViolacorpWeb.ErrorView)
        |> render("error.json", changeset: changeset)
      {:not_acceptable, message} ->
        conn
        |> put_status(:not_acceptable)
        |> put_view(ViolacorpWeb.ErrorView)
        |> render("4002.json", message: message)
    end
  end


  def step_three(conn, params) when map_size(params) == 0 do
    conn
    |> render(ViolacorpWeb.ErrorView, "somethingWrong.json")
  end

  @doc "Verify Mobile"
  def step_three(conn, params) do
    case Registrationv3.stepThree(params) do
      {:ok, data} ->
        conn
        |> put_status(:ok)
        |> put_view(ViolacorpWeb.ErrorView)
        |> json(%{status_code: 200, message: data})
      {:error, changeset} ->
        conn
        |> put_status(:not_acceptable)
        |> put_view(ViolacorpWeb.ErrorView)
        |> render("error.json", changeset: changeset)
      {:not_acceptable, message} ->
        conn
        |> put_status(:not_acceptable)
        |> put_view(ViolacorpWeb.ErrorView)
        |> render("4002.json", message: message)
    end
  end

  @doc "Change Mobile"
  def changeMobileNumber(conn, params) do
    case check_params(params, ["commanall_id", "mobile_number", "directors_id"]) do
      true -> case Registrationv3.changeMobileNumber(params) do
                {:ok, data} ->
                  conn
                  |> put_status(:ok)
                  |> put_view(ViolacorpWeb.ErrorView)
                  |> json(%{status_code: 200, message: data})
                {:error, changeset} ->
                  conn
                  |> put_status(:not_acceptable)
                  |> put_view(ViolacorpWeb.ErrorView)
                  |> render("error.json", changeset: changeset)
                {:not_acceptable, message} ->
                  conn
                  |> put_status(:not_acceptable)
                  |> put_view(ViolacorpWeb.ErrorView)
                  |> render("4002.json", message: message)
              end
      false ->
        conn
        |> put_status(:ok)
        |> put_view(ViolacorpWeb.ErrorView)
        |> render("invalidFiled.json", message: "Invalid parameters")
    end
  end

  def check_params(available, required) do
    case Enum.all?(required, &(Map.has_key?(available, &1))) do
      true -> case Enum.any?(available, fn {_k, v} -> v == "" end) do
                true -> false
                false -> true
              end
      false -> false
    end
  end


  def step_four(conn, params) when map_size(params) == 0 do
    conn
    |> render(ViolacorpWeb.ErrorView, "somethingWrong.json")
  end

  @doc "Create Passcode"
  def step_four(conn, params) do
    case Registrationv3.stepFour(params) do
      {:ok, data} ->
        conn
        |> put_status(:ok)
        |> put_view(ViolacorpWeb.ErrorView)
        |> json(%{status_code: 200, message: data})
      {:error, changeset} ->
        conn
        |> put_status(:not_acceptable)
        |> put_view(ViolacorpWeb.ErrorView)
        |> render("error.json", changeset: changeset)
      {:not_acceptable, message} ->
        conn
        |> put_status(:not_acceptable)
        |> put_view(ViolacorpWeb.ErrorView)
        |> render("4002.json", message: message)
    end
  end



  def step_five(conn, params) when map_size(params) == 0 do
    conn
    |> render(ViolacorpWeb.ErrorView, "somethingWrong.json")
  end

  @doc "Company Detail"
  def step_five(conn, params) do
    case Registrationv3.stepFive(params) do
      {:ok, data} ->
        conn
        |> put_status(:ok)
        |> put_view(ViolacorpWeb.ErrorView)
        |> json(%{status_code: 200, message: data})
      {:error, changeset} ->
        conn
        |> put_status(:not_acceptable)
        |> put_view(ViolacorpWeb.ErrorView)
        |> render("error.json", changeset: changeset)
      {:not_acceptable, message} ->
        conn
        |> put_status(:not_acceptable)
        |> put_view(ViolacorpWeb.ErrorView)
        |> render("4002.json", message: message)
      {:landlineNumber_error, message} ->
        conn
        |> put_status(:not_acceptable)
        |> put_view(ViolacorpWeb.ErrorView)
        |> render("landlineNumberExist.json", message: message)
    end
  end


  def step_six(conn, params) when map_size(params) == 0 do
    conn
    |> render(ViolacorpWeb.ErrorView, "somethingWrong.json")
  end

  @doc "extra directors/owner"
  def step_six(conn, params) do

    case Registrationv3.stepSix(params) do
      {:ok, data} ->
        conn
        |> put_status(:ok)
        |> put_view(ViolacorpWeb.ErrorView)
        |> json(%{status_code: 200, message: data})
      {:error, changeset} ->
        conn
        |> put_status(:not_acceptable)
        |> put_view(ViolacorpWeb.ErrorView)
        |> render("error.json", changeset: changeset)
      {:not_acceptable, message} ->
        conn
        |> put_status(:not_acceptable)
        |> put_view(ViolacorpWeb.ErrorView)
        |> render("4002.json", message: message)
      {:invalid, message} ->
        conn
        |> put_status(:not_acceptable)
        |> put_view(ViolacorpWeb.ErrorView)
        |> render("invalid.json", error: message)
    end
  end


  def step_seven(conn, params) when map_size(params) == 0 do
    conn
    |> render(ViolacorpWeb.ErrorView, "somethingWrong.json")
  end

  @doc "Significant Persons"
  def step_seven(conn, params) do

    case Registrationv3.stepSeven(params) do
      {:ok, data} ->
        conn
        |> put_status(:ok)
        |> put_view(ViolacorpWeb.ErrorView)
        |> json(%{status_code: 200, message: data})
      {:error, changeset} ->
        conn
        |> put_status(:not_acceptable)
        |> put_view(ViolacorpWeb.ErrorView)
        |> render("error.json", changeset: changeset)
      {:not_acceptable, message} ->
        conn
        |> put_status(:not_acceptable)
        |> put_view(ViolacorpWeb.ErrorView)
        |> render("4002.json", message: message)
      {:invalid, message} ->
        conn
        |> put_status(:not_acceptable)
        |> put_view(ViolacorpWeb.ErrorView)
        |> render("invalid.json", error: message)
    end

  end



  def step_eight(conn, params) when map_size(params) == 0 do
    conn
    |> render(ViolacorpWeb.ErrorView, "somethingWrong.json")
  end

  @doc "Terms and conditions"
  def step_eight(conn, params) do

    case Registrationv3.stepEight(params) do
      {:ok, data} ->
        conn
        |> put_status(:ok)
        |> put_view(ViolacorpWeb.ErrorView)
        |> json(%{status_code: 200, message: data})
      {:error, changeset} ->
        conn
        |> put_status(:not_acceptable)
        |> put_view(ViolacorpWeb.ErrorView)
        |> render("error.json", changeset: changeset)
      {:not_acceptable, message} ->
        conn
        |> put_status(:not_acceptable)
        |> put_view(ViolacorpWeb.ErrorView)
        |> render("4002.json", message: message)
    end
  end




  def get_sector(conn, _params) do
    details =  Sectors.get_sector()
    conn
    |> put_status(:ok)
    |> json(%{status_code: 200, data: details})
  end

  def get_monthly_value(conn, _params) do
    details =  Sectors.get_value_monthly_transfer()
    conn
    |> put_status(:ok)
    |> json(%{status_code: 200, data: details})
  end

  def get_directors_list(conn, params) do

    case Registrationv3.directorsList(params) do
      {:ok, data} ->
        conn
        |> put_status(:ok)
        |> put_view(ViolacorpWeb.ErrorView)
        |> json(%{status_code: 200, data: data})
    end
  end

  def get_first_director(conn, params) do

    case Registrationv3.firstDirector(params) do
      {:ok, data} ->
        conn
        |> put_status(:ok)
        |> put_view(ViolacorpWeb.ErrorView)
        |> json(%{status_code: 200, data: data})
    end
  end

  def get_first_company_director(conn, params) do

    case Registrationv3.firstCompanyDirector(params) do
      {:ok, data} ->
        conn
        |> put_status(:ok)
        |> put_view(ViolacorpWeb.ErrorView)
        |> json(%{status_code: 200, data: data})
      {:not_acceptable, message} ->
        conn
        |> put_status(:not_acceptable)
        |> put_view(ViolacorpWeb.ErrorView)
        |> render("4002.json", message: message)
    end
  end

  def get_fee_rule(conn, _params) do

    case Registrationv3.monthlyFeeRule() do
      {:ok, data} ->
        conn
        |> put_status(:ok)
        |> put_view(ViolacorpWeb.ErrorView)
        |> json(%{status_code: 200, data: data})
    end
  end

  def addMoreDirectors(conn, params) do
    %{"id" => _company_id, "commanall_id" => commanid} = conn.assigns[:current_user]
    case Registrationv3.addNewDirector(params, commanid) do
      {:ok, data} ->
        conn
        |> put_status(:ok)
        |> put_view(ViolacorpWeb.ErrorView)
        |> json(%{status_code: 200, message: data})
      {:error, changeset} ->
        conn
        |> put_status(:not_acceptable)
        |> put_view(ViolacorpWeb.ErrorView)
        |> render("error.json", changeset: changeset)
      {:not_acceptable, message} ->
        conn
        |> put_status(:not_acceptable)
        |> put_view(ViolacorpWeb.ErrorView)
        |> render("4002.json", message: message)
      {:invalid, message} ->
        conn
        |> put_status(:not_acceptable)
        |> put_view(ViolacorpWeb.ErrorView)
        |> render("invalid.json", error: message)
    end
  end
end