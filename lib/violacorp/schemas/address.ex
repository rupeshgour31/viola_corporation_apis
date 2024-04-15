defmodule Violacorp.Schemas.Address do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc "Address Table Model"

  schema "address" do
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
    field :sequence, :integer
    field :inserted_by, :integer
    field :t_address_line_one, :string, [source: :address_line_one]
    field :t_address_line_two, :string, [source: :address_line_two]
    field :t_address_line_three, :string, [source: :address_line_three]
    field :t_city, :string, [source: :city]
    field :t_town, :string, [source: :town]
    field :t_county, :string, [source: :county]
    field :t_countries_id, :integer, [source: :countries_id]
    field :t_post_code, :string, [source: :post_code]

    belongs_to :commanall, Violacorp.Schemas.Commanall
    timestamps()
  end

  @doc false
  def changeset(address, attrs) do
    address
    |> cast(attrs, [:commanall_id, :countries_id, :address_line_one, :address_line_two, :address_line_three, :town, :sequence, :county, :post_code, :is_primary, :inserted_by])
    |> validate_required([:address_line_one, :town, :post_code])
    |> foreign_key_constraint(:countries_id, name: :fk_address_countries1, message: "countries id con`t be blank")
    |> update_change(:address_line_one, &String.trim/1)
    |> update_change(:address_line_two, &String.trim/1)
    |> update_change(:address_line_three, &String.trim/1)
    |> update_change(:town, &String.trim/1)
    |> update_change(:post_code, &String.trim/1)
    |> update_change(:town, &String.capitalize/1)
    |> update_change(:post_code, &String.upcase/1)
    |> validate_format(:address_line_one, ~r/^[A-z0-9- .\/#&,]+$/)
    |> validate_length(:address_line_one, max: 40)
    |> validate_format(:address_line_two, ~r/^[A-z0-9- .\/#&,]+$/)
    |> validate_length(:address_line_two, max: 40)
    |> validate_format(:address_line_three, ~r/^[A-z0-9- .\/#&,]+$/)
    |> validate_length(:address_line_three, max: 40)
    |> validate_format(:town, ~r/^[A-z- ]+$/)
    |> validate_length(:town, max: 58)
    |> validate_format(:county, ~r/^[A-z- ]+$/)
    |> validate_length(:county, max: 50)
    |> validate_format(:post_code, ~r/^[a-zA-Z]{1,2}([0-9]{1,2}|[0-9][a-zA-Z])( {0,1})[0-9][a-zA-Z]{2}$/)
    |> validate_length(:post_code, max: 9)
  end

  def changeset_trading(address, attrs) do
    address
    |> cast(attrs, [:commanall_id, :t_countries_id, :t_address_line_one, :t_address_line_two, :t_address_line_three, :t_town, :sequence, :t_county, :t_post_code, :is_primary, :inserted_by])
    |> validate_required([:t_address_line_one, :t_town, :t_post_code])
    |> update_change(:t_address_line_one, &String.trim/1)
    |> update_change(:t_address_line_two, &String.trim/1)
    |> update_change(:t_address_line_three, &String.trim/1)
    |> update_change(:t_town, &String.trim/1)
    |> update_change(:t_county, &String.trim/1)
    |> update_change(:t_post_code, &String.trim/1)
    |> update_change(:t_town, &String.capitalize/1)
    |> update_change(:t_post_code, &String.upcase/1)
    |> validate_format(:t_address_line_one, ~r/^[A-z0-9- .\/#&,]+$/)
    |> validate_length(:t_address_line_one, max: 40)
    |> validate_format(:t_address_line_two, ~r/^[A-z0-9- .\/#&,]+$/)
    |> validate_length(:t_address_line_two, max: 40)
    |> validate_format(:t_address_line_three, ~r/^[A-z0-9- .\/#&,]+$/)
    |> validate_length(:t_address_line_three, max: 40)
    |> validate_format(:t_town, ~r/^[A-z- ]+$/)
    |> validate_length(:t_town, max: 58)
    |> validate_format(:t_county, ~r/^[A-z- ]+$/)
    |> validate_length(:t_county, max: 50)
    |> validate_format(:t_post_code, ~r/^[a-zA-Z]{1,2}([0-9]{1,2}|[0-9][a-zA-Z])( {0,1})[0-9][a-zA-Z]{2}$/)
    |> validate_length(:t_post_code, max: 9)
  end

  def changesetUpdateCountry(address, attrs) do
    address
    |> cast(attrs, [:country])
    |> validate_required([:country])
  end

  def updateChangeset(address, attrs) do
    address
    |> cast(attrs, [:countries_id, :address_line_one, :address_line_two, :address_line_three, :town, :sequence, :county, :post_code])
    |> validate_required([:address_line_one, :town, :post_code])
    |> foreign_key_constraint(:countries_id, name: :fk_address_countries1, message: "countries id con`t be blank")
    |> update_change(:address_line_one, &String.trim/1)
    |> update_change(:town, &String.trim/1)
    |> update_change(:post_code, &String.trim/1)
    |> update_change(:town, &String.capitalize/1)
    |> update_change(:post_code, &String.upcase/1)
    |> validate_format(:address_line_one, ~r/^[A-z0-9- .\/#&,]+$/)
    |> validate_length(:address_line_one, max: 40)
    |> validate_format(:address_line_two, ~r/^[A-z0-9- .\/#&,]+$/)
    |> validate_length(:address_line_two, max: 40)
    |> validate_format(:address_line_three, ~r/^[A-z0-9- .\/#&,]+$/)
    |> validate_length(:address_line_three, max: 40)
    |> validate_format(:town, ~r/^[A-z- ]+$/)
    |> validate_length(:town, max: 58)
    |> validate_format(:county, ~r/^[A-z- ]+$/)
    |> validate_length(:county, max: 50)
    |> validate_format(:post_code, ~r/^[a-zA-Z]{1,2}([0-9]{1,2}|[0-9][a-zA-Z])( {0,1})[0-9][a-zA-Z]{2}$/)
    |> validate_length(:post_code, max: 9)
  end
end
