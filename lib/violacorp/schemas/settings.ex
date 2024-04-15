defmodule Violacorp.Schemas.Settings do
  use Ecto.Schema
  import Ecto.Changeset

  alias Violacorp.Schemas.Settings

  @moduledoc "Settings Table Model"

  schema "settings" do
    field :category, :string
    field :access_token, :string
    field :token_type, :string
    field :generate_date, :date

    timestamps()
  end

  @doc false
  def changeset(%Settings{} = settings, attrs) do
    settings
    |> cast(attrs, [:category, :access_token, :token_type, :generate_date])
    |> validate_required([:access_token, :token_type, :generate_date])
  end

end
