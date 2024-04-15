defmodule ViolacorpWeb.CardErrorView do
  use ViolacorpWeb, :view

  def render("cardNotFound.json", _assigns) do
    # ViolacorpWeb.Admin.Comman.CommanController method: employeeKycIdDocumentTypeList()
    %{
      status_code: "4004",
      errors: %{
        message: "No cards have been found"
      }
    }
  end

  def render("cardAlreadyBlocked.json", _assigns) do
    # ViolacorpWeb.Admin.Comman.CommanController method: employeeKycIdDocumentTypeList()
    %{
      status_code: "4004",
      errors: %{
        message: "This card is already blocked"
      }
    }
  end

  def render("mustDeactivate.json", _assigns) do
    # ViolacorpWeb.Admin.Comman.CommanController method: employeeKycIdDocumentTypeList()
    %{
      status_code: "4004",
      errors: %{
        message: "The card needs to be deactivated"
      }
    }
  end

end