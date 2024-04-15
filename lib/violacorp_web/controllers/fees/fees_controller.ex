defmodule ViolacorpWeb.Fees.FeesController do
  use ViolacorpWeb, :controller
  import Ecto.Query

  alias Violacorp.Repo
  alias Violacorp.Schemas.Employee
  alias Violacorp.Schemas.Employeecards
  alias Violacorp.Schemas.Fee
  alias Violacorp.Schemas.Transactionsfee
  alias Violacorp.Schemas.Transactions
  alias Violacorp.Libraries.Commontools

  alias Violacorp.Schemas.Feehead
  alias ViolacorpWeb.Comman.FeeheadView
  alias Violacorp.Schemas.Groupfee
  alias ViolacorpWeb.Comman.GroupfeeView

  def insertFees(conn, params) do
    unless map_size(params) == 0 do
      username = params["username"]
      password = params["sec_password"]
      request_id = params["request_id"]
      viola_username = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)
      if username == viola_username and password == viola_password do
        feehead = %{
          "title" => params["title"],
          "status" => "A",
          "inserted_by" => request_id
        }
        changeset = Feehead.changeset(%Feehead{}, feehead)
        case Repo.insert(changeset) do
          {:ok, _feehead} -> json conn, %{status_code: "200", message: "Feehead Added."}
          {:error, changeset} ->
            conn
            |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
        end
      else
        json conn, %{status_code: "4002", errors: %{message: "You do not have permission to any update, Please contact to administrator."}}
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  def updateFees(conn, params) do
    unless map_size(params) == 0 do
      username = params["username"]
      password = params["sec_password"]
      _request_id = params["request_id"]
      viola_username = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)
      if username == viola_username and password == viola_password do
        getFeehead = Repo.get_by(Feehead, id: params["id"])
        if !is_nil(getFeehead) do
            feehead = %{
              "title" => params["title"],
            }
            changeset = Feehead.changeset(getFeehead, feehead)
            case Repo.update(changeset) do
              {:ok, _feehead} ->  json conn, %{status_code: "200", message: "Feehead Updated."}
              {:error, changeset} ->
                conn
                |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
            end
        else
          json conn, %{status_code: "4004", errors: %{message: "Record Not Found."}}
        end
      else
        json conn, %{status_code: "4002", errors: %{message: "You do not have permission to any update, Please contact to administrator."}}
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  def getAllFees(conn, params) do
    unless map_size(params) == 0 do
      username = params["username"]
      password = params["sec_password"]
      _request_id = params["request_id"]
      viola_username = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)
      if username == viola_username and password == viola_password do
        filtered = params
                   |> Map.take(~w( title))
                   |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

        getFeehead =  Feehead
                       |> where(^filtered)
                       |> order_by(desc: :updated_at)
                       |> Repo.paginate(params)
        if !is_nil(getFeehead) do
           render(conn, FeeheadView, "feehead_paginate.json", feehead: getFeehead)
        else
          json conn, %{status_code: "4004", errors: %{message: "Record Not Found."}}
        end
      else
        json conn, %{status_code: "4002", errors: %{message: "You do not have permission to any update, Please contact to administrator."}}
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  def getSingleFees(conn, params) do
    unless map_size(params) == 0 do
      username = params["username"]
      password = params["sec_password"]
      _request_id = params["request_id"]
      viola_username = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)
      if username == viola_username and password == viola_password do
        getFeehead = Repo.one(from f in Feehead, where: f.id == ^params["id"])
        if !is_nil(getFeehead) do
          render(conn, FeeheadView, "show.json", feehead: getFeehead)
        else
          json conn, %{status_code: "4004", errors: %{message: "Record Not Found."}}
        end
      else
        json conn, %{status_code: "4002", errors: %{message: "You do not have permission to any update, Please contact to administrator."}}
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  def insertGroupFees(conn, params) do
    unless map_size(params) == 0 do
      username = params["username"]
      password = params["sec_password"]
      request_id = params["request_id"]
      viola_username = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)
      if username == viola_username and password == viola_password do

        check_entry = Repo.get_by(Groupfee, feehead_id: params["title"], as_default: "Yes", status: "A")
        if is_nil(check_entry) do
          decode_rule = Poison.decode!(params["rules"])
          groupfee = %{
            "feehead_id" => params["title"],
            "amount" => params["amount"],
            "fee_type" => params["fee_type"],
            "trans_type" => params["trans_type"],
            "as_default" => "Yes",
            "rules" => Poison.encode!(decode_rule),
            "status" => "A",
            "inserted_by" => request_id
          }

          changeset = Groupfee.changeset(%Groupfee{}, groupfee)
          case Repo.insert(changeset) do
            {:ok, _groupfee} -> json conn, %{status_code: "200", message: "GroupFee Added."}
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        else
          json conn, %{status_code: "4002", errors: %{message: "Record Already Added."}}
        end
      else
        json conn, %{status_code: "4002", errors: %{message: "You do not have permission to any update, Please contact to administrator."}}
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  def updateGroupFees(conn, params) do
    unless map_size(params) == 0 do

      username = params["username"]
      password = params["sec_password"]
      _request_id = params["request_id"]
      viola_username = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)
      if username == viola_username and password == viola_password do
        getGroupfee = Repo.get_by(Groupfee, id: params["id"])
        if !is_nil(getGroupfee) do
          decode_rule = Poison.decode!(params["rules"])
          groupfee = %{
            "amount" => params["amount"],
            "fee_type" => params["fee_type"],
            "trans_type" => params["trans_type"],
            "rules" => Poison.encode!(decode_rule),
          }
          changeset = Groupfee.changeset(getGroupfee, groupfee)
          case Repo.update(changeset) do
            {:ok, _feehead} ->  json conn, %{status_code: "200", message: "GroupFee Updated."}
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        else
          json conn, %{status_code: "4004", errors: %{message: "Record Not Found."}}
        end
      else
        json conn, %{status_code: "4002", errors: %{message: "You do not have permission to any update, Please contact to administrator."}}
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  def getAllGroupFees(conn, params) do
    unless map_size(params) == 0 do
      username = params["username"]
      password = params["sec_password"]
      _request_id = params["request_id"]
      viola_username = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)
      if username == viola_username and password == viola_password do

        filtered = params
                   |> Map.take(~w( status amount trans_type commanall_id))
                   |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

        getGroupFee = (from g in Groupfee,
                        having: ^filtered,
                        where: is_nil(g.commanall_id),
                        left_join: f in assoc(g, :feehead),
                        order_by: [desc: g.updated_at],
                        select: %{id: g.id, title: f.title, trans_type: g.trans_type, fee_type: g.fee_type, amount: g.amount, as_default: g.as_default, status: g.status, rules: g.rules, inserted_at: g.inserted_at, updated_at: g.updated_at}
                        )
                      |> Repo.paginate(params)

        if !is_nil(getGroupFee) do
          render(conn, GroupfeeView, "groupfee_paginate.json", groupfee: getGroupFee)
        else
          json conn, %{status_code: "4004", errors: %{message: "Record Not Found."}}
        end
      else
        json conn, %{status_code: "4002", errors: %{message: "You do not have permission to any update, Please contact to administrator."}}
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  def getSingleGroupFees(conn, params) do
    unless map_size(params) == 0 do
      username = params["username"]
      password = params["sec_password"]
      _request_id = params["request_id"]
      viola_username = Application.get_env(:violacorp, :username)
      viola_password = Application.get_env(:violacorp, :password)
      if username == viola_username and password == viola_password do
        getGroupFee = (from g in Groupfee,
                            where: g.id == ^params["id"] and is_nil(g.commanall_id),
                            left_join: f in assoc(g, :feehead),
                            select: %{id: g.id, title: f.title, trans_type: g.trans_type, fee_type: g.fee_type, amount: g.amount, as_default: g.as_default, status: g.status, rules: g.rules, inserted_at: g.inserted_at, updated_at: g.updated_at}
                        )
                      |> Repo.one()
        if !is_nil(getGroupFee) do
          render(conn, GroupfeeView, "show.json", groupfee: getGroupFee)
        else
          json conn, %{status_code: "4004", errors: %{message: "Record Not Found."}}
        end
      else
        json conn, %{status_code: "4002", errors: %{message: "You do not have permission to any update, Please contact to administrator."}}
      end
    else
      conn
      |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :errorNoParameter)
    end
  end

  def getCompanyFees(conn, params) do
    text  conn, "getCompanyFees #{params["companyId"]} #{params["id"]}"
  end

  def getEmployeeFees(conn, params) do
    text  conn, "getEmployeeFees #{params["employeeId"]} #{params["id"]}"
  end

  def getMonthlyFee(conn, _params) do

    today = DateTime.utc_now
    get_employees = Repo.all from e in Employee, where: e.status == "A",
                                                 left_join: comman in assoc(e, :commanall),
                                                 left_join: c in assoc(e, :employeecards),
                                                 where: c.status < "5",
                                                 select: %{
                                                   id: e.id,
                                                   company_id: e.company_id,
                                                   title: e.title,
                                                   first_name: e.first_name,
                                                   last_name: e.last_name,
                                                   status: e.status,
                                                   profile_picture: e.profile_picture,
                                                   dateofbirth: e.date_of_birth,
                                                   gender: e.gender,
                                                   employeecards_id: c.id,
                                                   last_digit: c.last_digit,
                                                   available_balance: c.available_balance,
                                                   current_balance: c.current_balance,
                                                   currency: c.currency_code,
                                                   commanall_id: comman.id
                                                 }
    get_monthly = Repo.one from f in Fee, where: f.title == "Monthly Fee",
                                          select: %{
                                            id: f.id,
                                            amount: f.amount,
                                            type: f.type
                                          }

    if is_nil(get_employees) do
      json conn, %{status_code: "200", message: "No active employees/cards found"}
    else
      _ok = Enum.each(
        get_employees,
        fn x ->
          available_balance = String.to_float("#{x.available_balance}")
          debit_balance = if get_monthly.type == "F" do
            available_balance - String.to_float(get_monthly.amount)
          else
            if get_monthly.type == "P" do
              (available_balance * String.to_float(get_monthly.amount)) / 100
            end
          end
          existing = Repo.get(Employeecards, x.employeecards_id)
          changeset = %{available_balance: get_monthly.amount}
          new_changeset = Employeecards.changesetBalance(existing, changeset)

          case Repo.update(new_changeset) do
            {:ok, _commanall} ->
              remark = %{
                "from" => x.last_digit,
                "to" => "violacorporate",
                "from_name" => "#{x.first_name} #{x.last_name}",
                "to_name" => "violacorporate"
              }

              transaction = %{
                "commanall_id" => x.commanall_id,
                "company_id" => x.company_id,
                "employee_id" => x.id,
                "employeecards_id" => x.employeecards_id,
                "amount" => get_monthly.amount,
                "fee_amount" => 5.00,
                "final_amount" => get_monthly.amount,
                "cur_code" => x.currency,
                "balance" => debit_balance,
                "previous_balance" => x.available_balance,
                "transaction_id" => Integer.to_string(Commontools.randnumber(10)),
                "transaction_date" => today,
                "transaction_mode" => "D",
                "transaction_type" => "C2O",
                "category" => "CT",
                "description" => "test",
                "remark" => Poison.encode!(remark),
                "inserted_by" => x.commanall_id
              }
              changeset_card = Transactions.changesetTopupStepThird(%Transactions{}, transaction)

              transaction_fee = %{
                "fee_id" => get_monthly.id,
                "fee_amount" => get_monthly.amount,
                "fee_type" => get_monthly.type,
                "inserted_by" => x.commanall_id
              }
              changeset_fee = Transactionsfee.changeset(%Transactionsfee{}, transaction_fee)

              bothinsert = Ecto.Changeset.put_assoc(changeset_card, :transactionsfee, [changeset_fee])
              Repo.insert(bothinsert)
            {:error, changeset} ->
              conn
              |> render(ViolacorpWeb.ErrorView, "error.json", changeset: changeset)
          end
        end
      )
      json conn, %{status_code: "200", data: "Monthly Fees Deducted"}
    end
  end
end
