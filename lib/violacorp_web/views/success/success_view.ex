defmodule ViolacorpWeb.View.SuccessView do
  use ViolacorpWeb, :view
  alias Violacorp.Libraries.SuccessMessages

  # This is for success view
  def render("success.json", %{response: response}) do

    message = SuccessMessages.message(response)

    %{status_code: "200", Success: %{message: message}}
  end

  def render("success.json", %{data: data}) do

    %{status_code: "200", data: data}

  end

  def render("success.json", %{message: message}) do

    %{status_code: "200", message: message}

  end



  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(_template, assigns) do
    render "500.html", assigns
  end

  def render("500.html", _assigns) do
    "View Message Not Found"
  end

end