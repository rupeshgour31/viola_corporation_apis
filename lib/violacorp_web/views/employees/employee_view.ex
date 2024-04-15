defmodule ViolacorpWeb.Employees.EmployeeView do
  use ViolacorpWeb, :view

  alias ViolacorpWeb.Employees.EmployeeView
  alias Violacorp.Libraries.Commontools
  alias Violacorp.Libraries.Transactiontype

  def render("index.json", %{employee: employee}) do
    %{status_code: "200", data: render_many(employee, EmployeeView, "employee.json")}
  end

  def render("show.json", %{employee: employee}) do
    %{status_code: "200", data: render_one(employee, EmployeeView, "employee.json")}
  end

  def render("renderwithaddress.json", %{employee: employee}) do
    %{id: employee.id, title: employee.title, first_name: employee.first_name, dateofbirth: employee.date_of_birth, gender: employee.gender, profile_picture: employee.profile_picture,
     comman: render_many(employee.commanall, EmployeeView, "employeecontacts.json", as: :commanall)}
  end

  def render("employee.json", %{employee: employee}) do
    %{id: employee.id, title: employee.title, first_name: employee.first_name, last_name: employee.last_name, dateofbirth: employee.date_of_birth, gender: employee.gender, profile_picture: employee.profile_picture, status: employee.status}
  end

  def render("employeecontacts.json", %{commanall: commanall}) do
    %{contacts: render_many(commanall.contacts, EmployeeView, "employeecontactsall.json", as: :contacts)}
  end

  def render("employeecontactsall.json", %{contacts: contacts}) do
    %{id: contacts.id, contact_number: contacts.contact_number}
  end

  def render("manytrans_paginate.json", %{transactions: transactions}) do
  %{status_code: "200", total_count: transactions.total_entries, page_number: transactions.page_number, total_pages: transactions.total_pages, data: render_many(transactions.entries, EmployeeView, "transactionsplusreceipt.json", as: :transactions)}
end

  def render("manytrans_paginate_noReceipt.json", %{transactions: transactions}) do
    %{status_code: "200", total_count: transactions.total_entries, page_number: transactions.page_number, total_pages: transactions.total_pages, data: render_many(transactions.entries, EmployeeView, "transactionswithoutreceipt.json", as: :transactions)}
  end

  def render("manytrans_paginate_noReceipt_project.json", %{transactions: transactions}) do
    %{status_code: "200", total_count: transactions.total_entries, page_number: transactions.page_number, total_pages: transactions.total_pages, data: render_many(transactions.entries, EmployeeView, "transactionsplusproject.json", as: :transactions)}
  end

  def render("manytrans_paginate_receipt_project.json", %{transactions: transactions}) do
    %{status_code: "200", total_count: transactions.total_entries, page_number: transactions.page_number, total_pages: transactions.total_pages, data: render_many(transactions.entries, EmployeeView, "transactionsplusreceiptplusproject.json", as: :transactions)}
  end

  def render("manytrans.json", %{transactions: transactions}) do
    %{status_code: "200", data: render_many(transactions, EmployeeView, "transactionsplusreceipt.json", as: :transactions)}
  end

  def render("singletrans_onlyprojectwithaccount.json", %{transactions: transactions}) do
    %{status_code: "200", data: render_one(transactions, EmployeeView, "transactionsplusprojectwithaccount.json", as: :transactions)}
  end

  def render("singletrans_onlyproject.json", %{transactions: transactions}) do
    %{status_code: "200", data: render_one(transactions, EmployeeView, "transactionsplusproject.json", as: :transactions)}
  end

  def render("singletrans_project.json", %{transactions: transactions}) do
    %{status_code: "200", data: render_one(transactions, EmployeeView, "transactionsplusreceiptplusproject.json", as: :transactions)}
  end

  def render("manytrans_total_count.json", %{transactions: transactions}) do
    %{status_code: "200", total_count: Enum.count(transactions), data: render_many(transactions, EmployeeView, "transactionsplusreceipt.json", as: :transactions)}
  end

  def render("singletrans_withreceipt.json", %{transactions: transactions}) do
    %{status_code: "200", data: render_one(transactions, EmployeeView, "transactionsplusreceipt.json", as: :transactions)}
  end

  def render("manytrans_noReceipt.json", %{transactions: transactions}) do
    %{status_code: "200", data: render_many(transactions, EmployeeView, "transactionswithoutreceipt.json", as: :transactions)}
  end

  def render("transactionsplusreceipt.json", %{transactions: transactions}) do
    status = Commontools.transaction_status(transactions.status)
    transactions_type = Commontools.transaction_type(transactions.transaction_type)
    transactions_mode = Commontools.transaction_mode(transactions.transaction_mode)
    data =  %{remark: transactions.remark, type: transactions.transaction_type, description: transactions.description}
    map = Commontools.remark(data)
    transactions_codes = Transactiontype.get_transaction_type(transactions.api_type)

    decoded_remark = Poison.decode!(transactions.remark)
    from_info = if Map.has_key?(decoded_remark, "from_info") do
      decoded_remark["from_info"]
    else
    nil
    end

    to_info = if Map.has_key?(decoded_remark, "to_info") do
      decoded_remark["to_info"]
    else
      nil
    end

    %{id: transactions.id, commanall_id: transactions.commanall_id, from_info: from_info, to_info: to_info, transactions_code_type: transactions_codes["type"], transactions_code_title: transactions_codes["title"], from: map["from"], to: map["to"], amount: transactions.amount, fee_amount: transactions.fee_amount, final_amount: transactions.final_amount, remark: transactions.remark, balance: transactions.balance, previous_balance: transactions.previous_balance, transaction_mode: transactions.transaction_mode, transaction_date: transactions.transaction_date, transaction_type: transactions.transaction_type, transaction_id: transactions.transaction_id, category: transactions.category, lost_receipt: transactions.lost_receipt, category_info: transactions.category_info, status: transactions.status, projects_id: transactions.projects_id, description: transactions.description, cur_code: transactions.cur_code, status_new: status, transaction_type_new: transactions_type, transaction_mode_new: transactions_mode, receipts: render_many(transactions.transactionsreceipt, EmployeeView, "receipts.json", as: :receipts)}
  end

  def render("transactionswithoutreceipt.json", %{transactions: transactions}) do
    status = Commontools.transaction_status(transactions.status)
    transactions_type = Commontools.transaction_type(transactions.transaction_type)
    transactions_mode = Commontools.transaction_mode(transactions.transaction_mode)
    data =  %{remark: transactions.remark, type: transactions.transaction_type, description: transactions.description}
    map = Commontools.remark(data)
    transactions_codes = Transactiontype.get_transaction_type(transactions.api_type)

    decoded_remark = Poison.decode!(transactions.remark)
    from_info = if Map.has_key?(decoded_remark, "from_info") do
      decoded_remark["from_info"]
    else
      nil
    end
    to_info = if Map.has_key?(decoded_remark, "to_info") do
      decoded_remark["to_info"]
    else
      nil
    end
    %{id: transactions.id, commanall_id: transactions.commanall_id, from_info: from_info, to_info: to_info, transactions_code_type: transactions_codes["type"], transactions_code_title: transactions_codes["title"], from: map["from"], to: map["to"], amount: transactions.amount, fee_amount: transactions.fee_amount, final_amount: transactions.final_amount, remark: transactions.remark, balance: transactions.balance, previous_balance: transactions.previous_balance, transaction_mode: transactions.transaction_mode, transaction_date: transactions.transaction_date, transaction_type: transactions.transaction_type, transaction_id: transactions.transaction_id, category: transactions.category, status: transactions.status, projects_id: transactions.projects_id, description: transactions.description, cur_code: transactions.cur_code, status_new: status, transaction_type_new: transactions_type, transaction_mode_new: transactions_mode}
  end

  def render("transactionsplusreceiptplusproject.json", %{transactions: transactions}) do
    status = Commontools.transaction_status(transactions.status)
    transactions_type = Commontools.transaction_type(transactions.transaction_type)
    transactions_mode = Commontools.transaction_mode(transactions.transaction_mode)
    data =  %{remark: transactions.remark, type: transactions.transaction_type, description: transactions.description}
    map = Commontools.remark(data)
    transactions_codes = Transactiontype.get_transaction_type(transactions.api_type)

    project_name = if is_nil(transactions.projects) do
      nil
      else
      transactions.projects.project_name
    end

    decoded_remark = Poison.decode!(transactions.remark)
    from_info = if Map.has_key?(decoded_remark, "from_info") do
      decoded_remark["from_info"]
    else
      nil
    end

    to_info = if Map.has_key?(decoded_remark, "to_info") do
      decoded_remark["to_info"]
    else
      nil
    end
    %{id: transactions.id, commanall_id: transactions.commanall_id, from_info: from_info, to_info: to_info, transactions_code_type: transactions_codes["type"], transactions_code_title: transactions_codes["title"], from: map["from"], to: map["to"], entertain_id: transactions.entertain_id, category_id: transactions.category_id, amount: transactions.amount, fee_amount: transactions.fee_amount, final_amount: transactions.final_amount, remark: transactions.remark, balance: transactions.balance, lost_receipt: transactions.lost_receipt, category_info: transactions.category_info, previous_balance: transactions.previous_balance, transaction_mode: transactions.transaction_mode, transaction_date: transactions.transaction_date, transaction_type: transactions.transaction_type, transaction_id: transactions.transaction_id, category: transactions.category, status: transactions.status, projects_id: transactions.projects_id, description: transactions.description, cur_code: transactions.cur_code, status_new: status, transaction_type_new: transactions_type, transaction_mode_new: transactions_mode, receipts: render_many(transactions.transactionsreceipt, EmployeeView, "receipts.json", as: :receipts), projects_name: project_name}
  end

  def render("transactionsplusproject.json", %{transactions: transactions}) do
    status = Commontools.transaction_status(transactions.status)
    transactions_type = Commontools.transaction_type(transactions.transaction_type)
    transactions_mode = Commontools.transaction_mode(transactions.transaction_mode)
    data =  %{remark: transactions.remark, type: transactions.transaction_type, description: transactions.description}
    map = Commontools.remark(data)
    transactions_codes = Transactiontype.get_transaction_type(transactions.api_type)

    project_name = if is_nil(transactions.projects) do
      nil
    else
      transactions.projects.project_name
    end

    decoded_remark = Poison.decode!(transactions.remark)
    from_info = if Map.has_key?(decoded_remark, "from_info") do
      decoded_remark["from_info"]
    else
      nil
    end

    to_info = if Map.has_key?(decoded_remark, "to_info") do
      decoded_remark["to_info"]
    else
      nil
    end

    %{id: transactions.id, commanall_id: transactions.commanall_id, from_info: from_info, to_info: to_info, transactions_code_type: transactions_codes["type"], transactions_code_title: transactions_codes["title"], from: map["from"], to: map["to"], entertain_id: transactions.entertain_id, category_id: transactions.category_id, amount: transactions.amount, fee_amount: transactions.fee_amount, final_amount: transactions.final_amount, remark: transactions.remark, balance: transactions.balance, previous_balance: transactions.previous_balance, transaction_mode: transactions.transaction_mode, transaction_date: transactions.transaction_date, transaction_type: transactions.transaction_type, transaction_id: transactions.transaction_id, category: transactions.category, status: transactions.status, projects_id: transactions.projects_id, description: transactions.description, cur_code: transactions.cur_code, status_new: status, transaction_type_new: transactions_type, transaction_mode_new: transactions_mode, projects_name: project_name}
  end

  def render("transactionsplusprojectwithaccount.json", %{transactions: transactions}) do
    status = Commontools.transaction_status(transactions.status)
    transactions_type = Commontools.transaction_type(transactions.transaction_type)
    transactions_mode = Commontools.transaction_mode(transactions.transaction_mode)
    data =  %{remark: transactions.remark, type: transactions.transaction_type, description: transactions.description}
    map = Commontools.remark(data)
    transactions_codes = Transactiontype.get_transaction_type(transactions.api_type)

    project_name = if is_nil(transactions.projects) do
      nil
    else
      transactions.projects.project_name
    end

    decoded_remark = Poison.decode!(transactions.remark)
    from_info = if Map.has_key?(decoded_remark, "from_info") do
      decoded_remark["from_info"]
    else
      nil
    end

    to_info = if Map.has_key?(decoded_remark, "to_info") do
      decoded_remark["to_info"]
    else
      nil
    end

    %{id: transactions.id,
      commanall_id: transactions.commanall_id,
      transactions_code_type: transactions_codes["type"],
      transactions_code_title: transactions_codes["title"],
      from: map["from"],
      to: map["to"],
      entertain_id: transactions.entertain_id,
      beneficiaries_id: transactions.beneficiaries_id,
      category_id: transactions.category_id,
      amount: transactions.amount,
      fee_amount: transactions.fee_amount,
      final_amount: transactions.final_amount,
      remark: transactions.remark,
      balance: transactions.balance,
      previous_balance: transactions.previous_balance,
      transaction_mode: transactions.transaction_mode,
      transaction_date: transactions.transaction_date,
      transaction_type: transactions.transaction_type,
      transaction_id: transactions.transaction_id,
      category: transactions.category,
      status: transactions.status,
      projects_id: transactions.projects_id,
      description: transactions.description,
      cur_code: transactions.cur_code,
      from_info: from_info,
      to_info: to_info,
      status_new: status,
      transaction_type_new: transactions_type,
      transaction_mode_new: transactions_mode,
      projects_name: project_name}


    end

  def render("receipts.json", %{receipts: receipts}) do
    %{id: receipts.id, receipt_url: receipts.receipt_url, receipt_upload_date: receipts.inserted_at, transaction_row_id: receipts.transactions_id}
  end

  def render("projects.json", %{projects: projects}) do
    %{id: projects.id, project_name: projects.project_name}
  end
end
