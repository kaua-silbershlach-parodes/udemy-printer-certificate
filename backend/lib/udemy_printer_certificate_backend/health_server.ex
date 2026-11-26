defmodule UdemyPrinterCertificateBackend.HealthServer do
  @moduledoc """
  A tiny supervised HTTP health endpoint on 127.0.0.1, pure :gen_tcp.

  Deliberately minimal: one request at a time, every path answers
  the same JSON health body. It exists so the shell (and the smoke
  tests) can prove the sidecar is alive and read its version.
  """
  use GenServer

  def start_link(port) do
    GenServer.start_link(__MODULE__, port, name: __MODULE__)
  end

  @impl true
  def init(port) do
    {:ok, listen} =
      :gen_tcp.listen(port, [
        :binary,
        packet: :raw,
        active: false,
        reuseaddr: true,
        ip: {127, 0, 0, 1}
      ])

    {:ok, %{listen: listen, port: port}, {:continue, :accept}}
  end

  @impl true
  def handle_continue(:accept, state) do
    case :gen_tcp.accept(state.listen) do
      {:ok, socket} ->
        serve(socket)
        {:noreply, state, {:continue, :accept}}

      {:error, _reason} ->
        {:noreply, state, {:continue, :accept}}
    end
  end

  defp serve(socket) do
    case :gen_tcp.recv(socket, 0, 5_000) do
      {:ok, _request} ->
        version = Application.spec(:udemy_printer_certificate_backend, :vsn) |> to_string()
        body = ~s({"status":"ok","service":"udemy_printer_certificate_backend","version":"#{version}"})

        response =
          "HTTP/1.1 200 OK\r\n" <>
            "content-type: application/json\r\n" <>
            "content-length: #{byte_size(body)}\r\n" <>
            "connection: close\r\n\r\n" <> body

        :gen_tcp.send(socket, response)

      _other ->
        :ok
    end

    :gen_tcp.close(socket)
  end
end
