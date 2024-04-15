defmodule Violacorp.Schemas.Alertswitch do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Alertswitch

  @moduledoc "Alertswitch Table Model"

  schema "alertswitch" do
    field :section, :string
    field :email, :string
    field :notification, :string
    field :sms, :string
    field :subject, :string
    field :templatefile, :string
    field :layoutfile, :string
    field :sms_body, :string
    field :notification_body, :string
    field :inserted_by, :integer
    timestamps()
  end

  @doc false

  def changeset(%Alertswitch{} = alertswitch, attrs) do
    alertswitch
    |> cast(attrs, [:section, :email, :subject, :templatefile, :layoutfile, :notification, :sms, :notification_body, :sms_body, :inserted_by])
    |> validate_required([:section ,:email, :sms, :subject, :templatefile, :layoutfile, :sms_body, :notification_body])
    |> validate_length(:section, min: 2, max: 45)
    |> validate_format(:templatefile, ~r/^[A-z{}0-9-_.#]+$/)
    |> validate_length(:templatefile, min: 6, max: 45)
    |> validate_format(:layoutfile, ~r/^[A-z{}0-9-_.#]+$/)
    |> validate_length(:layoutfile, min: 6, max: 45)
    |> validate_length(:subject, min: 2, max: 255)
    |> validate_length(:sms_body, min: 2, max: 255)
    |> validate_length(:notification_body, min: 2, max: 255)
    |> validate_inclusion(:email, ["Y", "N"])
    |> validate_inclusion(:notification, ["Y", "N"])
    |> validate_inclusion(:sms, ["Y", "N"])
  end
end
