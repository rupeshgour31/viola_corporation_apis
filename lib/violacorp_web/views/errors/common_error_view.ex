defmodule ViolacorpWeb.CommonErrorView do
  use ViolacorpWeb, :view

  def render("4004errorMessage.json", %{error: message}) do
    %{
      status_code: "4004",
      errors: %{message: message}
    }
  end

  def render("invalid.json", %{error: message}) do
    %{
      status_code: "4003",
      errors: message
    }
  end

  def render("inValidPassword.json", %{message: message}) do
    %{
      status_code: "4003",
      errors: %{
        password: message
      }
    }
  end

  def render("passwordMatchError.json", _assigns) do
    %{
      status_code: "4004",
      errors: %{
        password: "Passwords do not match, Please re-enter password"
      }
    }
  end

  def render("4002.json", %{message: message}) do
    %{
      status_code: "4002",
      errors: %{
        message: message
      }
    }
  end

end