defmodule ViolacorpWeb.SuccessView do
  use ViolacorpWeb, :view

  # This is for success view
  def render("success.json", %{response: response}) do
    %{status_code: "200", data: response}
  end

end
