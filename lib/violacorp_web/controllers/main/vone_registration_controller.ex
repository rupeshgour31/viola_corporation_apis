defmodule ViolacorpWeb.Main.VoneRegistrationController do
  use ViolacorpWeb, :controller

  alias Violacorp.Models.Registration

  alias Violacorp.Libraries.Sectors

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


    case Registration.stepOne(reg_request) do
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
    end

  end

  def step_one(conn, _) do
    conn
    |> render(ViolacorpWeb.ErrorView, "somethingWrong.json")
  end

  @doc "Verify OTP"
  def step_two(conn, params) do
    case Registration.stepTwo(params) do
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
  def step_two(conn, _) do
    conn
    |> render(ViolacorpWeb.ErrorView, "somethingWrong.json")
  end

  @doc "Setup VPIN"
  def step_three(conn, params) do
    case Registration.stepThree(params) do
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
  def step_three(conn, _) do
    conn
    |> render(ViolacorpWeb.ErrorView, "somethingWrong.json")
  end



  @doc "Business Details"
  def step_four(conn, params) do
    case Registration.stepFour(params) do
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
    end
  end

  def step_four(conn, _) do
    conn
    |> render(ViolacorpWeb.ErrorView, "somethingWrong.json")
  end


  @doc "CAP/Directors/Owner details"
  def step_five(conn, params) do
    case Registration.stepFive(params) do
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

  def step_five(conn, _) do
    conn
    |> render(ViolacorpWeb.ErrorView, "somethingWrong.json")
  end

  @doc "Cards Allocation"
  def step_six(conn, params) do

    case Registration.stepSix(params) do
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
  def step_six(conn, _) do
    conn
    |> render(ViolacorpWeb.ErrorView, "somethingWrong.json")
  end

  @doc "Terms and conditions"
  def step_seven(conn, params) do

    case Registration.stepSeven(params) do
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

  def step_seven(conn, _) do
    conn
    |> render(ViolacorpWeb.ErrorView, "somethingWrong.json")
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

    case Registration.directorsList(params) do
      {:ok, data} ->
        conn
        |> put_status(:ok)
        |> put_view(ViolacorpWeb.ErrorView)
        |> json(%{status_code: 200, data: data})
    end
  end

  def get_first_director(conn, params) do

    case Registration.firstDirector(params) do
      {:ok, data} ->
        conn
        |> put_status(:ok)
        |> put_view(ViolacorpWeb.ErrorView)
        |> json(%{status_code: 200, data: data})
    end
  end

  def get_fee_rule(conn, _params) do

    case Registration.monthlyFeeRule() do
      {:ok, data} ->
        conn
        |> put_status(:ok)
        |> put_view(ViolacorpWeb.ErrorView)
        |> json(%{status_code: 200, data: data})
    end
  end

end