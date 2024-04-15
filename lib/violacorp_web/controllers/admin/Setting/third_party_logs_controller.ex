defmodule ViolacorpWeb.Admin.Settings.ThirdPartyLogsController do
  use Phoenix.Controller

  alias ViolacorpWeb.ErrorView
#  alias ViolacorpWeb.ThirdpartyLogsView
  alias Violacorp.Model.Settings.ThirdPartyLogsSetting
  @moduledoc false

  def thirdPartyLogsList(conn, params) do
    data = ThirdPartyLogsSetting.third_party_logs_list(params)
    json conn,%{status_code: "200",total_pages: data.total_pages,total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end

  def thirdPartyLogView(conn, params)do

    data = ThirdPartyLogsSetting.third_party_log_view(params)
            case data do
              [] ->
                conn|> render(ErrorView, "recordNotFound.json")
              response ->
                json conn, %{status_code: "200", data: updateResponse(response)}
    end
  end

  defp updateResponse(response) do

    Enum.map(response, fn x ->
      string = String.split(x.section, " ~ ")
      section_name = if Enum.count(string) > 1 do
        List.last(string)
      else
        List.first(string)
      end
      if section_name !== "GBG" do
        decode = Poison.decode!(x.response)
        response_code = decode["result"]["code"]
        result = decode["result"]
        response_info = if response_code == "0000", do: Poison.encode!(result), else: x.response

        new_map = %{response: response_info}
        Map.merge(x, new_map)
       else
        x.response
      end

    end)
  end
end
