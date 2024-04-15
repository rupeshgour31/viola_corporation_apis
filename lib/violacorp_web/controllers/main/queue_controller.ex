defmodule ViolacorpWeb.Main.QueueController do
  use ViolacorpWeb, :controller

  def index(conn, _params) do

    messagebody = "{\"recipients\": \"+447722101011\",\"originator\": \"ViolaCorp\",\"body\": \"+hello test\" }"

    #  {:ok, ack} = Exq.enqueue(Exq, "ios", Vioalcorp.Worker.SendIosWorker, [details], max_retries: 1)
    {:ok, _ack} = Exq.enqueue(Exq, "sms", Violacorp.Workers.Sendsms, [messagebody], max_retries: 1)
    text conn, "Showing id QueueController"
  end
end
