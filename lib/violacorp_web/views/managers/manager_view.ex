defmodule ViolacorpWeb.Managers.ManagerView do
  use ViolacorpWeb, :view
  alias ViolacorpWeb.Managers.ManagerView

  def render("index.json", %{manager: manager}) do
    %{status_code: "200", data: render_many(manager, ManagerView, "manager.json")}
  end

  def render("show.json", %{manager: manager}) do
    %{status_code: "200", data: render_one(manager, ManagerView, "manager.json")}
  end

  def render("manager.json", %{manager: manager}) do
    %{id: manager.id, title: manager.title, first_name: manager.first_name, last_name: manager.last_name, dateofbirth: manager.date_of_birth, gender: manager.gender, profile_picture: manager.profile_picture}

  end
end
