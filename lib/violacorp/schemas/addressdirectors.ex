defmodule Violacorp.Schemas.Addressdirectors do
  use Ecto.Schema
  import Ecto.Changeset
  alias Violacorp.Schemas.Addressdirectors

  @moduledoc "Addressdirectors Table Model"

  schema "addressdirectors" do
    field :address_line_one, :string
    field :address_line_two, :string
    field :address_line_three, :string
    field :city, :string
    field :town, :string
    field :county, :string
    field :country, :string
    field :countries_id, :integer
    field :post_code, :string
    field :is_primary, :string
    field :inserted_by, :integer

    belongs_to :directors, Violacorp.Schemas.Directors
#    belongs_to :countries, Violacorp.Schemas.Countries

    timestamps()
  end

  @doc false
  def changeset(%Addressdirectors{} = addressdirectors, attrs) do
    addressdirectors
    |> cast(attrs, [:directors_id, :countries_id, :address_line_one, :address_line_two, :address_line_three, :city, :town, :county, :post_code, :is_primary, :inserted_by])
    |> validate_required([:address_line_one, :post_code, :town, :countries_id])
    |> foreign_key_constraint(:countries_id, name: :fk_addressdirectors_countries1, message: "countries id con`t be blank")
    |> foreign_key_constraint(:directors_id, name: :fk_address_directors_directors1)
    |> update_change(:address_line_one, &String.trim/1)
    #|> update_change(:address_line_two, &String.trim/1)
    #|> update_change(:address_line_three, &String.trim/1)
    |> update_change(:town, &String.trim/1)
   # |> update_change(:county, &String.trim/1)
    |> update_change(:post_code, &String.trim/1)
    #|> update_change(:town, &String.capitalize/1)
    |> update_change(:post_code, &String.upcase/1)
    |> validate_format(:address_line_one, ~r/^[A-z0-9- .\/#&,]+$/)
    |> validate_length(:address_line_one, min: 6, max: 40)
    |> validate_format(:address_line_two, ~r/^[A-z0-9- .\/#&,]+$/)
    |> validate_length(:address_line_two, max: 40)
    |> validate_format(:address_line_three, ~r/^[A-z0-9- .\/#&,]+$/)
    |> validate_length(:address_line_three, max: 40)
    |> validate_format(:town, ~r/^[A-z- ]+$/)
    |> validate_length(:town, min: 1, max: 58)
    |> validate_format(:county, ~r/^[A-z- ]+$/)
    |> validate_length(:county, max: 50)
    |> validate_format(:post_code, ~r/^[a-zA-Z]{1,2}([0-9]{1,2}|[0-9][a-zA-Z])( {0,1})[0-9][a-zA-Z]{2}$/)
    |> validate_length(:post_code, max: 9)

  end

  def changesetUpdateCountry(%Addressdirectors{} = addressdirectors, attrs) do
    addressdirectors
      |> cast(attrs, [:country])
      |> validate_required([:country])
  end

  def updateChangeset(%Addressdirectors{} = addressdirectors, attrs) do
    addressdirectors
    |> cast(attrs, [:countries_id, :address_line_one, :address_line_two, :address_line_three, :city, :town, :county, :post_code])
    |> validate_required([:address_line_one, :post_code, :town, :countries_id])
    |> foreign_key_constraint(:countries_id, name: :fk_addressdirectors_countries1, message: "countries id con`t be blank")
    |> update_change(:address_line_one, &String.trim/1)
      #|> update_change(:address_line_two, &String.trim/1)
      #|> update_change(:address_line_three, &String.trim/1)
    |> update_change(:town, &String.trim/1)
      # |> update_change(:county, &String.trim/1)
    |> update_change(:post_code, &String.trim/1)
      #|> update_change(:town, &String.capitalize/1)
    |> update_change(:post_code, &String.upcase/1)
    |> validate_format(:address_line_one, ~r/^[A-z0-9- .\/#&,]+$/)
    |> validate_length(:address_line_one, min: 6, max: 40)
    |> validate_format(:address_line_two, ~r/^[A-z0-9- .\/#&,]+$/)
    |> validate_length(:address_line_two, max: 40)
    |> validate_format(:address_line_three, ~r/^[A-z0-9- .\/#&,]+$/)
    |> validate_length(:address_line_three, max: 40)
    |> validate_format(:town, ~r/^[A-z- ]+$/)
    |> validate_length(:town, min: 1, max: 58)
    |> validate_format(:county, ~r/^[A-z- ]+$/)
    |> validate_length(:county, max: 50)
    |> validate_format(:post_code, ~r/^[a-zA-Z]{1,2}([0-9]{1,2}|[0-9][a-zA-Z])( {0,1})[0-9][a-zA-Z]{2}$/)
    |> validate_length(:post_code, max: 9)

  end
end
