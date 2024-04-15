defmodule ViolacorpWeb.TransactionsRecieptView do
  use ViolacorpWeb, :view
 # alias  ViolacorpWeb.TransactionsRecieptView




  @doc""

  def render("receipts.json", %{data: data}) do
    %{
      reciept: data.receipt_url
    }
  end
  end