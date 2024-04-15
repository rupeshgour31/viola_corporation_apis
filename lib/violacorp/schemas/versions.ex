defmodule Violacorp.Schemas.Versions do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Versions

  schema "versions" do
    field :android, :string
    field :inserted_by, :integer
    field :iphone, :string
    field :ekyc, :string
    field :dev_email, :string
    field :live_email, :string
    field :api_enable, :string
    field :fee_sole_trade, :decimal
    field :fee_limited, :decimal
    field :signature_server, :string

    timestamps()
  end

  @doc false
  def changeset(%Versions{} = versions, attrs) do
    versions
    |> cast(attrs, [:android, :iphone, :ekyc, :dev_email, :live_email, :fee_sole_trade, :fee_limited, :api_enable, :inserted_by])
    |> validate_required([:android, :iphone, :ekyc, :dev_email, :live_email, :api_enable])
    |> update_change(:android, &String.trim/1)
    |> update_change(:iphone, &String.trim/1)
    |> update_change(:dev_email, &String.trim/1)
    |> update_change(:live_email, &String.trim/1)
    |> validate_format(:android, ~r/^[0-9.]+$/)
    |> validate_format(:iphone, ~r/^[0-9.]+$/)
    |> validate_length(:android, max: 8)
    |> validate_length(:iphone, max: 8)
    |> validate_length(:dev_email, max: 150)
    |> validate_length(:live_email, max: 150)
    |> validate_inclusion(:api_enable, ["Y", "N"])
  end

  @doc false
  def updateSignatureServer(%Versions{} = versions, attrs) do
    versions
    |> cast(attrs, [:signature_server])
    |> validate_required([:signature_server])
  end
end
