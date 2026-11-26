defmodule UdemyPrinterCertificateBackend.Application do
  use Application

  @impl true
  def start(_type, _args) do
    port =
      case System.get_env("UDEMY_PRINTER_CERTIFICATE_BACKEND_PORT") do
        nil -> 45_900
        value -> String.to_integer(value)
      end

    children = [
      {UdemyPrinterCertificateBackend.HealthServer, port}
    ]

    opts = [strategy: :one_for_one, name: UdemyPrinterCertificateBackend.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
