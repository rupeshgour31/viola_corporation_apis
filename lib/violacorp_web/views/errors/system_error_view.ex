defmodule ViolacorpWeb.SystemErrorView do
  use ViolacorpWeb, :view

  def render("noDocumentListFound.json", _assigns) do
    # ViolacorpWeb.Admin.Comman.CommanController method: employeeKycIdDocumentTypeList()
    %{
      status_code: "4004",
      errors: %{
        message: "Document List not Found"
      }
    }
  end

  def render("somethingWrong.json", _assigns) do
    %{
      status_code: "4002",
      errors: %{
        message: "Something Went Wrong"
      }
    }
  end

  def render("404.html", _assigns) do
    "Page not found"
  end

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(_template, assigns) do
    render "500.html", assigns
  end

  def render("500.html", _assigns) do
    "Internal server error"
  end

  def render("invalidFiled.json", %{message: message}) do
    %{
      status_code: "4001",
      errors: %{
        message: message
      }
    }
  end

end