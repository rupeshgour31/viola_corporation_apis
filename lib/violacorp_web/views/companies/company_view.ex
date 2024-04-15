defmodule ViolacorpWeb.Companies.CompanyView do
  use ViolacorpWeb, :view
  alias ViolacorpWeb.Companies.CompanyView
  alias ViolacorpWeb.Comman.CommanView
  alias Violacorp.Libraries.Commontools
  alias Violacorp.Libraries.Transactiontype

  def render("index.json", %{company: company}) do
    %{status_code: "200", data: render_many(company, CompanyView, "company.json")}
  end

  def render("show.json", %{company: company}) do
    %{status_code: "200", data: render_many(company, CompanyView, "company.json")}
  end

  def render("company.json", %{company: company}) do
    %{status_code: "200", company_name: company.company_name, company_cin: company.company_cin, company_logo: company.company_logo, registration_number: company.registration_number, company_type: company.company_type, date_of_registration: company.date_of_registration, commanall: render_many(company.commanall, CompanyView, "commanall.json")}

  end

#  ADDRESSES
  def render("employeeaddress.json", %{employeeaddress: employeeaddress}) do
    %{status_code: "200", address: render_many(employeeaddress.address, CommanView, "address.json", as: :address)}
  end

  def render("companyaddress.json", %{companyaddress: companyaddress}) do
    %{status_code: "200", address: render_many(companyaddress.address, CommanView, "address.json", as: :address)}
  end

  def render("addressdirectors.json", %{addressdirectors: addressdirectors}) do
    %{status_code: "200", address: render_many(addressdirectors.addressdirectors, CommanView, "address.json", as: :address)}
  end

#  CONTACTS
  def render("employeecontacts.json", %{employeecontacts: employeecontacts}) do
    %{status_code: "200", contacts: render_many(employeecontacts.contacts, CommanView, "contacts.json", as: :contacts)}
  end

  def render("companycontacts.json", %{companycontacts: companycontacts}) do
    %{status_code: "200", contacts: render_many(companycontacts.contacts, CommanView, "contacts.json", as: :contacts)}
  end

  def render("contactsdirectors.json", %{contactsdirectors: contactsdirectors}) do
    %{status_code: "200", contacts: render_many(contactsdirectors.contactsdirectors, CommanView, "contacts.json", as: :contacts)}
  end

  def render("commanall.json", %{company: company}) do
  %{id: company.id}
end

  #BANK ACCOUNT LISTS
  def render("manybeneficiaries_paginate.json", %{beneficiaries: beneficiaries}) do
    %{status_code: "200", total_count: beneficiaries.total_entries, page_number: beneficiaries.page_number, total_pages: beneficiaries.total_pages, data: render_many(beneficiaries.entries, CompanyView, "beneficiaries.json", as: :beneficiaries)}
  end

  def render("beneficiaryTransactions.json", %{transactions: transactions}) do
    %{status_code: "200", total_count: transactions.total_entries, page_number: transactions.page_number, total_pages: transactions.total_pages, data: render_many(transactions.entries, CompanyView, "beneficiaries_transactions.json", as: :transactions)}
  end


  def render("beneficiaries.json", %{beneficiaries: beneficiaries}) do
    status = Commontools.status(beneficiaries.status)
    type = Commontools.beneficiary_type(beneficiaries.type)

    %{id: beneficiaries.id, company_id: beneficiaries.company_id, first_name: beneficiaries.first_name, last_name: beneficiaries.last_name, nick_name: beneficiaries.nick_name, sort_code: beneficiaries.sort_code, account_number: beneficiaries.account_number, description: beneficiaries.description, invoice_number: beneficiaries.invoice_number, type: type, status: status, inserted_by: beneficiaries.inserted_by}
  end

  def render("beneficiaries_transactions.json", %{transactions: transactions}) do
    status = Commontools.transaction_status(transactions.status)
    transactions_type = Commontools.transaction_type(transactions.transaction_type)
    transactions_mode = Commontools.transaction_mode(transactions.transaction_mode)
    data =  %{remark: transactions.remark, type: transactions.transaction_type, description: transactions.description}
    map = Commontools.remark(data)
    transactions_codes = Transactiontype.get_transaction_type(transactions.api_type)

    %{id: transactions.id, commanall_id: transactions.commanall_id, transactions_code_type: transactions_codes["type"], transactions_code_title: transactions_codes["title"], from: map["from"], to: map["to"], amount: transactions.amount, fee_amount: transactions.fee_amount, final_amount: transactions.final_amount, remark: transactions.remark, balance: transactions.balance, previous_balance: transactions.previous_balance, transaction_mode: transactions.transaction_mode, transaction_date: transactions.transaction_date, transaction_type: transactions.transaction_type, transaction_id: transactions.transaction_id, category: transactions.category, status: transactions.status, description: transactions.description, cur_code: transactions.cur_code, status_new: status, transaction_type_new: transactions_type, transaction_mode_new: transactions_mode}

  end

end
