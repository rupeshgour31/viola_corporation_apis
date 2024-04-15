defmodule ViolacorpWeb.Admin.DashboardController do
  use Phoenix.Controller
#  import Ecto.Query

#  alias Violacorp.Repo
#  alias Violacorp.Schemas.Commanall

  alias  Violacorp.Models.Dashboard
  @doc "get all daseboard counts"
  def getall_act_ped_company_daseboard(conn, params)do
    data = Dashboard.dashboardCount(params)
    case data do
      {} -> render(conn, ViolacorpWeb.ErrorView, "recordNotFound.json", data: data)
      data ->
        json conn, %{status_code: "200", data: data}
    end
  end

  def get_all_cards_counts(conn, params)do
    data = Dashboard.cards_count(params)
    case data do
      [] -> render(conn, ViolacorpWeb.ErrorView, "recordNotFound.json", data: data)
      data ->
        json conn, %{status_code: "200", data: data}
    end
  end



def getall_archive_del_company_daseboard(conn, params)do
  data = Dashboard.archive_deleted_com_count(params)
  case data do
    {} -> render(conn, ViolacorpWeb.ErrorView, "recordNotFound.json", data: data)
    data ->
      json conn, %{status_code: "200", data: data ,}
  end
end
def active_Directors_Business_Owners(conn, params)do
         data = Dashboard.total_directors_owner(params)
    case data do
      {} -> render(conn, ViolacorpWeb.ErrorView, "recordNotFound.json", data: data)
      data ->
        json conn, %{status_code: "200", data: data ,}
    end
  end


end