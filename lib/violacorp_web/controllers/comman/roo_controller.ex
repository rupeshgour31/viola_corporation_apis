defmodule ViolacorpWeb.Comman.RooController do
  use ViolacorpWeb, :controller

  @version Mix.Project.config()[:version]

  def yahoo(conn, _params) do
    text conn, "welcome to Viola Corporate API's (#{@version})"
  end

  def yahoopost(conn, _params) do
    text conn, "welcome to Viola Corporate API's (#{@version})"
  end
end
