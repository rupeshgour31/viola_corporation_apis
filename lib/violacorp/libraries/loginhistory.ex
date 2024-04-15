defmodule Violacorp.Libraries.Loginhistory do

  import Ecto.Query
  alias Violacorp.Repo
  alias Violacorp.Schemas.Loginhistory

  def addLoginHistory(commanall, details, dev_type, abc_token, check_block_date) do
    #    addLogoutTime(params["email_id"])
    timein = "#{Time.truncate(Time.utc_now(), :second)}"

    {commanall_id, email_id, time_in, details, success, existing_user, device_type} = if is_map(commanall) do
      case commanall.internal_status do
        "C" -> {commanall.id, commanall.email_id, nil, "Internal Status Closed", "N", "Y", nil}
        "S" -> {commanall.id, commanall.email_id, nil, "Internal Status Suspended", "N", "Y", nil}
        "UR" -> {commanall.id, commanall.email_id, nil, "Internal Status Under Review", "N", "Y", nil}
        _ ->
          if commanall.status in ["D", "B", "U", "R"] do
            {commanall.id, commanall.email_id, nil, "Status is not Active", "N", "Y", nil}
          else
            if check_block_date == "No" do
              if abc_token == "fail" do
                {commanall.id, commanall.email_id, nil, "Incorrect email or password", "N", "Y", nil}
              else
                if commanall.employee_id != nil and commanall.as_employee != "Y" do
                  {commanall.id, commanall.email_id, timein, Poison.encode!(details), "Y", "Y", dev_type}
                else
                  if commanall.company_id != nil do
                    {commanall.id, commanall.email_id, timein, Poison.encode!(details), "Y", "Y", dev_type}
                  end
                end
              end
            else
              {commanall.id, commanall.email_id, nil, "Account Blocked", "N", "Y", nil}
            end
          end
      end
    else
      {nil, commanall, nil, "Incorrect email or password", "N", "N", nil}
    end

    history = %{
      commanall_id: commanall_id,
      email_id: email_id,
      time_in: time_in,
      time_out: nil,
      details: details,
      success: success,
      existing_user: existing_user,
      device_type: device_type
    }
    changesetLogin = Loginhistory.changeset(%Loginhistory{}, history)
    Repo.insert(changesetLogin) # |> IO.inspect()
    login_list = Repo.all(
      from a in Loginhistory, where: a.email_id == ^email_id,
                              order_by: [
                                asc: a.inserted_at
                              ],
                              select: a.id
    )
    Enum.reduce_while(
      login_list,
      Enum.count(login_list),
      fn x, acc ->
        if acc > 10 do
          %Loginhistory{id: x}
          |> Repo.delete
          acc = acc - 1
          {:cont, acc}
        else
          {:halt, :ok}
        end
      end
    )
  end

  def addAdminLoginHistory(commanall, details, dev_type, _abc_token, _check_block_date) do
    #    addLogoutTime(params["email_id"])
    timein = "#{Time.truncate(Time.utc_now(), :second)}"

    {commanall_id, email_id, time_in, details, success, existing_user, device_type} = if is_map(commanall) do
      case commanall.status do
        "D" -> {commanall.id, commanall.email_id, timein, "Account De-Activated", "N", "Y", nil}
        "B" -> {commanall.id, commanall.email_id, timein, "Account Blocked", "N", "Y", nil}
        _ -> {commanall.id, commanall.email_id, timein, details, "Y", "Y", dev_type}
      end
    else
      {nil, commanall, timein, "Admin: Incorrect email or password", "N", "N", nil}
    end

    history = %{
      administratorusers_id: commanall_id,
      email_id: email_id,
      time_in: time_in,
      time_out: nil,
      details: details,
      success: success,
      existing_user: existing_user,
      device_type: "W"
    }
    changesetLogin = Loginhistory.changeset(%Loginhistory{}, history)
    Repo.insert(changesetLogin) # |> IO.inspect()
    login_list = Repo.all(
      from a in Loginhistory, where: a.email_id == ^email_id,
                              order_by: [
                                asc: a.inserted_at
                              ],
                              select: a.id
    )
    Enum.reduce_while(
      login_list,
      Enum.count(login_list),
      fn x, acc ->
        if acc > 10 do
          %Loginhistory{id: x}
          |> Repo.delete
          acc = acc - 1
          {:cont, acc}
        else
          {:halt, :ok}
        end
      end
    )
  end

  @doc" Insert Logout time"
  def addLogoutTime(email_id)do
    time = %{
    "time_out" => "#{Time.truncate(Time.utc_now(), :second)}"
    }
    user = Repo.one(
      from a in Loginhistory, where: a.email_id == ^email_id,
                              order_by: [
                                desc: a.inserted_at
                              ], limit: 1
    )
    _timeout = Loginhistory.changeset(user, time)
    |>Repo.update()
  end
end
