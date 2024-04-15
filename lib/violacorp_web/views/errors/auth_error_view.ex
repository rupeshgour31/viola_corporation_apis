defmodule ViolacorpWeb.AuthErrorView do
  use ViolacorpWeb, :view

  def render("noPermission.json", _assigns) do
    %{
      status_code: "4002",
      errors: %{
        message: "Update Permission Required, Please Contact Administrator."
      }
    }
  end

def render("emailPasswordWrong.json", _assigns) do
  %{
    status_code: "4002",
    errors: %{
      message: "Email or Password is incorrect"
    }
  }
end

  def render("incorrectPa.json", _assigns) do
    %{
      status_code: "4002",
      errors: %{
        message: "Email or Password is incorrect"
      }
    }
  end

  def render("existingEmail.json", _assigns) do
    %{
      status_code: "4003",
      errors: %{
        message: "This e-mail address is already registered"
      }
    }
  end

  def render("otpNotFound.json", _assigns) do
    %{
      status_code: "4004",
      errors: %{
        message: "OTP not found for this section, request a new one"
      }
    }
  end

  def render("landlineNumberExist.json", %{message: message}) do
    %{
      status_code: "4003",
      errors: %{
        landline_number: message
      }
    }
  end

  def render("userNotFound.json", _assigns) do
    %{
      status_code: "4004",
      errors: %{
        message: "User has not been found"
      }
    }
  end

  def render("tokenNotFound.json", _assigns) do
    %{
      status_code: "4001",
      errors: %{
        message: "Token Missing or InValid"
      }
    }
  end

  def render("tokenExpired.json", _assigns) do
    %{
      status_code: "4000",
      errors: %{
        message: "Token Expired"
      }
    }
  end

  def render("tokenExpired_mobile.json", _assigns) do
    %{
      status_code: "4008",
      errors: %{
        message: "Token Expired"
      }
    }
  end

  def render("assign_token_failed.json", _assigns) do
    %{
      status_code: "4002",
      errors: %{
        message: "assign token failed"
      }
    }
  end

end