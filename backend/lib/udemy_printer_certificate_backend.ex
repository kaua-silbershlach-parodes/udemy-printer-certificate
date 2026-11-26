defmodule UdemyPrinterCertificateBackend do
  @moduledoc """
  Minimal Elixir sidecar for the Oxide OTP shell.

  Pure OTP, zero dependencies: a supervised TCP health server on
  127.0.0.1 that answers any HTTP request with a small JSON body
  (status, service, version). Real backends grow from here: add
  modules under the same supervisor, keep the shell contract
  (localhost only, own lifecycle, own version).
  """
end
