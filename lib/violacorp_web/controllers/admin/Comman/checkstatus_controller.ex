defmodule ViolacorpWeb.Admin.Comman.CheckstatusController do
  use ViolacorpWeb, :controller
  alias Violacorp.Models.ThirdpartyStatusUpdate

  @moduledoc "Thirdparty Controller"
  #  import Ecto.Query

  defp check_params(available, required) do
    Enum.all?(required, &(Map.has_key?(available, &1)))
  end

  @doc""
  def checkstatus(conn, params)do
    %{"id" => admin_id, "type" => ad_type} = conn.assigns[:current_user]
    if ad_type == "A" do
      with true <- check_params(params, ["type", "commanall_id", "own_password"]) do
        case ThirdpartyStatusUpdate.changeStatus(params, admin_id) do
          {:ok, message} ->
            json conn, %{status_code: "200", message: message}
          {:not_found, message} ->
            json conn,
                 %{
                   status_code: "4004",
                   errors: %{
                     message: message
                   }
                 }
          {:third_party_error, message} ->
            json conn,
                 %{
                   status_code: "5001",
                   errors: %{
                     message: message
                   }
                 }
        end
      else
        false ->
          json conn,
               %{
                 status_code: "4004",
                 errors: %{
                   message: "Please send all required params."
                 }
               }
      end
    else
      json conn,
           %{
             status_code: "4002",
             errors: %{
               message: "You have not permission to any update, Please contact to administrator."
             }
           }
    end
  end

end