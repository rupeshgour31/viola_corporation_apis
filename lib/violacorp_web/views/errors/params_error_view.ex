defmodule ViolacorpWeb.ParamsErrorView do
  use ViolacorpWeb, :view


  def render("feeplan.json", _assigns) do
    %{
      status_code: "400",
      errors: %{
        message: "No Feeplan Found in Parameter 'plan: ''"
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



end