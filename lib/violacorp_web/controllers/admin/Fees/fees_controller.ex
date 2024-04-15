defmodule ViolacorpWeb.Admin.Fees.FeesController do
  use Phoenix.Controller

  alias Violacorp.Models.Fees
  alias ViolacorpWeb.SuccessView
  alias ViolacorpWeb.ErrorView
  alias ViolacorpWeb.FeeheadView

  @doc "get all feehead"
  def getAllFeeHead(conn, params)do
    %{"id" => _admin_id,"type" => type} = conn.assigns[:current_user]
    if type == "A"  do
      data = Fees.get_all_feehead(params)
      json conn, %{status_code: "200",total_pages: data.total_pages,total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number,data: data.entries}
    else
      json conn, %{status_code: "4002", errors: %{
        message: "Update Permission Required, Please Contact Administrator."}
      }
    end
  end

  @doc "get all group fees"
  def getAllGroupHead(conn, params)do
      data = Fees.get_all_group_head(params)
      json conn, %{status_code: "200",total_pages: data.total_pages,total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end

  @doc "update fee  HEAD"
   def updateFeehead(conn, params)do
    %{"id" => admin_id,"type" => type} = conn.assigns[:current_user]
    if type == "A"  do
            unless map_size(params) == 0 do
                  case Fees.edit_fee_head(params,admin_id)do
                    {:ok, message} ->
                      conn
#                      |> put_status(:ok)
                      |> put_view(SuccessView)
                      |> render("success.json", response: message)
                    {:error, changeset}->
                      conn
#                      |> put_status(:not_acceptable)
                      |> put_view(ErrorView)
                      |> render("error.json", changeset: changeset)
                    {:not_found, changeset} ->
                      conn
#                      |> put_status(:not_found)
                      |> put_view(ErrorView)
                      |> render("recordNotFound.json", error: changeset)
                  end
             else
              conn
              |> render(ErrorView, "errorNoParameter.json")
            end
     else
      json conn, %{status_code: "4002", errors: %{
        message: "Update Permission Required, Please Contact Administrator."}
      }
    end

  end

  def getSingleFees(conn, params)do
         data = Fees.get_single_feehead(params)
        case data do
              {:ok, data} ->
                conn
                |> put_status(:ok)
                |> put_view(FeeheadView)
                |> render("show.json", feehead: data)
              {:not_found, _message} ->
                conn
                |> put_status(:not_found)
                |> put_view(ErrorView)
                |> render("recordNotFound.json")
        end
  end

  @doc """
    ** FEE **
    Add Fee head
  """
  def insertFeeHead(conn, params)do
    %{"type" => type, "id" => admin_id} = conn.assigns[:current_user]
    request = Map.merge(params, %{"inserted_by" => "99999#{admin_id}"})
    if type == "A"  do
      case Fees.add_fee_head(request)do
        {:ok, _message} -> json conn, %{status_code: "200", message: "FeeHead Added."}
        {:error, changeset}->
          conn
          |>put_view(ErrorView)
          |>render("error.json", changeset: changeset)
      end
    else
      json conn, %{status_code: "4002", errors: %{
        message: "Update Permission Required, Please Contact Administrator."}
      }
    end
end

   def getFeeHead(conn, params) do
    %{"type" => type} = conn.assigns[:current_user]
    if type == "A"  do
           data = Fees.feeHeadList(params)
            case data do
              []->  json conn, %{status_code: "4003", message: "Record not found!"}
              _data ->
                json conn, %{status_code: "200",data: data}
            end
      else
      json conn, %{status_code: "4002", errors: %{
        message: "Update Permission Required, Please Contact Administrator."}
      }
    end
  end
  @doc """
    add group fees
  """
  def insertGroupFees(conn, params) do
    %{"id" => admin_id} = conn.assigns[:current_user]
    request = Map.merge(params, %{"inserted_by" => "99999#{admin_id}"})
    case Fees.insertGroupFees(request)do
      {:ok, message} ->
        conn
        |> render(ViolacorpWeb.SuccessView, "success.json", response: message)
      {:error, changeset} ->
        conn
        |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      {:error_message, error_message} ->
        json conn, %{status_code: "4004", errors: %{ message: error_message}}
    end
  end

  @doc """
    update group fee
  """
  def updateGroupFees(conn, params) do
    case Fees.updateGroupFees(params)do
      {:ok, message} ->
        conn
        |> render(ViolacorpWeb.SuccessView, "success.json", response: message)
      {:error, changeset} ->
        conn
        |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
      {:error_message, error_message} ->
        json conn, %{status_code: "4004", errors: %{ message: error_message}}
    end
  end
end