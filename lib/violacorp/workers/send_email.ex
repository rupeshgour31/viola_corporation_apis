defmodule Violacorp.Workers.SendEmail do
  use Bamboo.Phoenix, view: ViolacorpWeb.EmailView

#  alias ViolacorpWeb.LayoutView.V2

  @moduledoc "SendEmail function - send email"

  def sendemail(data) do
    new_email()
    |> from(data.from)
    |> to(data.to)
    |> put_html_layout({ViolacorpWeb.LayoutView, data.templatefile})
    |> subject(data.subject)
    |> assign(:data, data)
    |> render(data.templatefile)
  end

  def sendemailV2(data) do
    new_email()
    |> from(data.from)
    |> to(data.to)
    |> put_html_layout({ViolacorpWeb.LayoutView, data.templatefile})
    |> subject(data.subject)
    |> assign(:data, data.render_data)
    |> render(data.templatefile)
  end
end
