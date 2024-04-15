defmodule ViolacorpWeb.Admin.Notifications.NotificationController do
 use Phoenix.Controller

#  alias Violacorp.Repo
#  import Ecto.Query
# alias ViolacorpWeb.ErrorView

 alias Violacorp.Models.Notifications

# alias Violacorp.Schemas.Alertswitch
# alias  ViolacorpWeb.MoneyrequestView

   @doc "get all money request "
   def getAllMoneyRequest(conn, params) do
          data = Notifications.money_request(params)
                json conn, %{status_code: "200",total_pages: data.total_pages,total_entries:
                     data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
           end

   @doc "cards Request"
   def getAllCardsRequest(conn, params) do
     data = Notifications.card_request(params)
     json conn, %{status_code: "200",total_pages: data.total_pages,total_entries:
       data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
   end

   @doc "get all approved card list "
    def getAllApprovedCard(conn, params)do
        data =  Notifications.card_approved( params)
        json conn, %{status_code: "200",total_pages: data.total_pages,total_entries:
          data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
    end

 def getBrowserInfoView(conn, params)do
      data =  Notifications.getBrowserInfoView( params)
      json conn, %{status_code: "200", data: data}
   end
end