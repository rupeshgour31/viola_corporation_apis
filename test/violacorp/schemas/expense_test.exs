defmodule Violacorp.Schemas.ExpenseTest do

  use Violacorp.DataCase
  alias Violacorp.Schemas.Expense
  @moduledoc false

  @valid_attrs %{
    commanall_id: 1232,
    aws_url: "www.sdfsdfsdfsdf.com/scsa",
    generate_date: ~D[2012-02-02],
    employee_id: 1215,
    employeecards_id: 1251
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Expense.changeset(%Expense{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Expense.changeset(%Expense{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "generate_date required check" do
    changeset = Expense.changeset(%Expense{}, Map.delete(@valid_attrs, :generate_date))
    assert !changeset.valid?
  end

  test "check if aws_url maximum 150 numbers" do
    attrs = %{@valid_attrs | aws_url: "www.sdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsdsd.com"}
    changeset = Expense.changeset(%Expense{}, attrs)
    assert %{aws_url: ["should be at most 150 character(s)"]} = errors_on(changeset)
  end



  end