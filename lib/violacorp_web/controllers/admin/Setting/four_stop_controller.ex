defmodule ViolacorpWeb.Admin.Settings.FourStopController do
  use Phoenix.Controller

  import Ecto.Query
  alias Violacorp.Repo
  alias Violacorp.Schemas.Fourstop
  alias Violacorp.Schemas.Directors
  alias Violacorp.Schemas.Commanall
  alias Violacorp.Schemas.Fourstopcallback


  @doc"""
    Director four stop list.
  """
  def director_fourstop(conn, params) do
    %{"id" => _admin_id,"type" => type} = conn.assigns[:current_user]
    if type == "A"  do

      filter = params
               |> Map.take(~w(email_id))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

      result = (from co in Commanall, left_join: f in assoc(co, :fourstop),
                                      where: not is_nil(f.director_id),
                                      left_join: c in assoc(co, :company),
                                      join: d in Directors,
                                      where: d.id == f.director_id,
                                      order_by: [desc: f.id],
                                      having: ^filter,
                                      select: %{
                                       score: f.score,
                                       rec: f.rec,
                                       confidence_level: f.confidence_level,
                                       response: f.response,
                                        stopid: f.stopid,
                                       inserted_at: f.inserted_at,
                                       first_name: d.first_name,
                                       last_name: d.last_name,
                                       director_email: d.email_id,
                                       company_name: c.company_name,
                                       company_email: co.email_id
                                      })
              |> Repo.paginate(params)

      if result != [] do
        json conn,
             %{
               status_code: "200",
               total_pages: result.total_pages,
               total_entries: result.total_entries,
               page_size: result.page_size,
               page_number: result.page_number,
               data: result.entries
             }
      end
    else
      json conn, %{status_code: "4002", errors: %{message: "Update Permission Required, Please Contact Administrator."}}
    end
  end

  @doc"""
    Employee four stop list.
  """
  def employee_fourstop(conn, params) do
    %{"id" => _admin_id,"type" => type} = conn.assigns[:current_user]
    if type == "A"  do

      filter = params
               |> Map.take(~w(email_id))
               |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

      result = (from c in Commanall, left_join: f in Fourstop,
                                     where: is_nil(f.director_id),
                                     right_join: e in assoc(c, :employee),
                                     left_join: co in assoc(e, :company),
                                     order_by: [desc: f.id],
                                     having: ^filter,
                                     select: %{
                                             score: f.score,
                                             rec: f.rec,
                                             confidence_level: f.confidence_level,
                                             response: f.response,
                                             inserted_at: f.inserted_at,
                                             stopid: f.stopid,
                                             email_id: c.email_id,
                                             first_name: e.first_name,
                                             last_name: e.last_name,
                                             company_name: co.company_name,
                                             comapny_email: c.email_id
                                           })
               |> Repo.paginate(params)
        json conn,
             %{
               status_code: "200",
               total_pages: result.total_pages,
               total_entries: result.total_entries,
               page_size: result.page_size,
               page_number: result.page_number,
               data: result.entries
             }
    else
      json conn, %{status_code: "4002", errors: %{message: "Update Permission Required, Please Contact Administrator."}}
    end
  end

  @doc"""
    Callback data
  """
  def callback_data(conn, params) do
    %{"type" => type, "id" => admin_id} = conn.assigns[:current_user]
    if type == "A"  do
      stopid = params["stopid"]
      case Repo.get_by(Fourstopcallback, stopid: stopid) do
        nil ->
          render(conn, ViolacorpWeb.ErrorView, "recordNotFound.json")
        data ->
          image_bucket = Application.get_env(:violacorp, :aws_bucket)
          mode = Application.get_env(:violacorp, :aws_mode)
          region = Application.get_env(:violacorp, :aws_region)
          reference_id = data.reference_id
          file_path = "https://#{image_bucket}.#{region}/#{mode}/#{reference_id}.txt"

          %HTTPoison.Response{status_code: status_code, body: body} = HTTPoison.get!(file_path)

          if status_code == 200  do
              response = Poison.decode!(body)
              json conn, %{status_code: "200", data: response}
          else
            render(conn, ViolacorpWeb.ErrorView, "recordNotFound.json")
          end
      end
    else
      json conn, %{status_code: "4002", errors: %{
        message: "Update Permission Required, Please Contact Administrator."}
      }
    end
  end

end
