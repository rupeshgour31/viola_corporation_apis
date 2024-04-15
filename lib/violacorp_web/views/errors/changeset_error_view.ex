defmodule ViolacorpWeb.ChangesetErrorView do
  use ViolacorpWeb, :view

  ## CHANGESET ERROR #################

  def render("error.json", %{changeset: changeset}) do
    # When encoded, the changeset returns its errors
    # as a JSON object. So we just pass it forward.
    %{status_code: "4003", errors: translate_errors(changeset)}
  end

  def translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
  end

  ####################################

end