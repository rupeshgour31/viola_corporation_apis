defmodule ViolacorpWeb.AccountErrorView do
  use ViolacorpWeb, :view

  def render("accountNotFound.json", _assigns) do
    %{
      status_code: "4004",
      errors: %{
        message: "Account not found"
      }
    }
  end

end