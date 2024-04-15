defmodule ViolacorpWeb.Plugs.Auth do
  import Plug.Conn
#  alias Violacorp.Repo
#  import Ecto.Query
  @moduledoc "Auth plugs module"

  def init(default), do: default

  def call(conn, _default) do
    token = conn
            |> get_req_header("apitoken")
            |> List.first


    check_token = token
                  |> check_token

    case check_token do
      :expired ->
        conn
        |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :tokenExpired)
        |> halt
      :error ->
        conn
        |> Phoenix.Controller.render(ViolacorpWeb.ErrorView, :tokenNotFound)
        |> halt
      {:ok, user} ->
        conn
        |> assign(:current_user, user)
    end
  end

  def check_token(token) do
    key_for_token = Application.get_env(:violacorp, :tokenKey)
    case Phoenix.Token.verify(ViolacorpWeb.Endpoint, key_for_token, token, max_age: 864000) do
      {:ok, user} -> {:ok, user}
      {:error, :expired} -> :expired
      {:error, _} -> :error
    end
  end
end
