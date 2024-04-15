defmodule ViolacorpWeb.ErrorView do
  use ViolacorpWeb, :view

  #  use Iteraptor.Iteraptable

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

  def render("500.html", _assigns) do
    "Internal server error"
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

  def render("invalidFiled.json", %{message: message}) do
    %{
      status_code: "4001",
      errors: %{
        message: message
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

  def render("emailPasswordWrong.json", _assigns) do
    %{
      status_code: "4002",
      errors: %{
        message: "Email or Password is incorrect"
      }
    }
  end

  def render("userDeactive.json", _assigns) do
    %{
      status_code: "4002",
      errors: %{
        message: "Account De-activated"
      }
    }
  end

  def render("userBlocked.json", _assigns) do
    %{
      status_code: "4002",
      errors: %{
        message: "Account has been blocked"
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

  def render("errorNoParameter.json", _assigns) do
    %{
      status_code: "400",
      errors: %{
        message: "No Parameter Found"
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
  def render("permission_message.json", _assigns) do
    %{
      status_code: "4004",
      errors: %{
        message: "You don't have permission for any update"
      }
    }
  end
  def render("invalid.json", %{error: message}) do
    %{
      status_code: "4003",
      errors: message
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

  def render("error.json", %{changeset: changeset}) do
    # When encoded, the changeset returns its errors
    # as a JSON object. So we just pass it forward.
    %{status_code: "4003", errors: translate_errors(changeset)}
  end

  def render("assign_token_failed.json", _assigns) do
    %{
      status_code: "4002",
      errors: %{
        message: "assign token failed"
      }
    }
  end

  def render("feeplan.json", _assigns) do
    %{
      status_code: "400",
      errors: %{
        message: "No Feeplan Found in Parameter 'plan: ''"
      }
    }
  end

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(_template, assigns) do
    render "500.html", assigns
  end

  def translate_errors(changeset) do

    Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
    #    vartwo = varone |> Iteraptor.to_flatmap(delimiter: "_")

    #    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
    #        Enum.reduce(opts, msg, fn {key, value}, acc ->
    #            String.replace(acc, "%{#{key}}", to_string(value))
    #           end)
    #       end)


    ##    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
    ##      Enum.reduce(opts, msg, fn {key, value}, acc ->
    ##      String.replace(acc, "%{#{key}}", to_string(value))

    #        Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
    #        Enum.reduce(opts, msg, fn {key, value}, acc ->
    #
    #    for {key, values} <- changeset.errors, value <- values, do: "#{key} #{value}"
    #          end
    #                                  ) end)


  end

end
