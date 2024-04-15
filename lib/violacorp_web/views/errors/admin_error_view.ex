defmodule ViolacorpWeb.AdminErrorView do
  use ViolacorpWeb, :view

  def render("noTagsFound.json", _assigns) do
    # ViolacorpWeb.Admin.Comman.CommanController method: getTags()
    %{
      status_code: "4004",
      errors: %{
        message: "No tags have been found"
      }
    }
  end

end