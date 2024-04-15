defmodule Violacorp.Schemas.Listener do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc "Listener Table Model"

  schema "listener" do
    field :accounts_id, :string
    field :nonce, :string
    field :type, :string
    field :header_request, :string
    field :request, :string
    field :header_response, :string
    field :response, :string
    field :status, :string
    field :inserted_by, :integer

    timestamps()

  end

  @doc false
  def changeset(listener, attrs) do
    listener
    |> cast(attrs, [:accounts_id, :nonce, :type, :header_request, :request, :header_response, :response, :status, :inserted_by])
    |> validate_required([:nonce, :type])
    |> update_change(:nonce, &String.trim/1)
    |> update_change(:type, &String.trim/1)
#    |> validate_number(:accounts_id, greater_than: 0, less_than: 100000000000)
    |> validate_length(:nonce, max: 45)
    |> validate_length(:type, max: 45)
    |> validate_inclusion(:status, ["A", "R"])
    |> validate_number(:inserted_by, less_than: 100000000000)
  end

  @doc false
  def changesetUpdate(listener, attrs) do
    listener
    |> cast(attrs, [:accounts_id, :header_response, :response, :status])
    |> validate_required([:header_response, :response])
    |> validate_inclusion(:status, ["A", "R"])
  end

end
