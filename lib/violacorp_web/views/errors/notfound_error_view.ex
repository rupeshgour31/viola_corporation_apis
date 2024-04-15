defmodule ViolacorpWeb.NotfoundErrorView do
  use ViolacorpWeb, :view


  def render("noKYC.json", _assigns) do
    %{
      status_code: "4003",
      errors: %{
        message: "No KYC details have been found"
      }
    }
  end

  def render("noAddress.json", _assigns) do
    %{
      status_code: "4003",
      errors: %{
        message: "No Address have been found"
      }
    }
  end

  def render("noContact.json", _assigns) do
    %{
      status_code: "4003",
      errors: %{
        message: "No Contact numbers have been found"
      }
    }
  end

  def render("recordNotFound.json", _assigns) do
    %{
      status_code: "4004",
      errors: %{
        message: "No record found!"
      }
    }
  end

  end
