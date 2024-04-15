defmodule Violacorp.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Violacorp.Repo, []),
      # Start the endpoint when the application starts
      supervisor(ViolacorpWeb.Endpoint, []),
      # Start your own worker by calling: Violacorp.Worker.start_link(arg1, arg2, arg3)
      # worker(Violacorp.Worker, [arg1, arg2, arg3]),
#      {Redix, [[], [name: :redix]]},
      worker(Violacorp.Scheduler, []),
      worker(Cachex, [:vcorp, []])

    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Violacorp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ViolacorpWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
