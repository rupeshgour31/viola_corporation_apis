defmodule ViolacorpWeb.Comman.CommanView do
  use ViolacorpWeb, :view

#  ADDRESSES
  def render("address.json", %{address: address}) do
    %{id: address.id, address_line_one: address.address_line_one, address_line_two: address.address_line_two, address_line_three: address.address_line_three, city: address.city, countries_id: address.countries_id, post_code: address.post_code}
  end

#  CONTACTS
  def render("contacts.json", %{contacts: contacts}) do
    %{id: contacts.id, contact_number: contacts.contact_number, is_primary: contacts.is_primary, status: contacts.status}
  end

end
