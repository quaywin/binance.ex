defmodule Binance.Util do
  @moduledoc false

  @doc """
  Prepare request body, sign it if required
  """
  def prepare_request_body(params, sign?) do
    argument_string =
      params
      |> Map.to_list()
      |> Enum.map(fn x -> Tuple.to_list(x) |> Enum.join("=") end)
      |> Enum.join("&")

    case sign? do
      true ->
        signature = sign_content(argument_string)
        "#{argument_string}&signature=#{signature}"

      false ->
        argument_string
    end
  end

  @doc """
  Sign a value using Binance Secret key
  """
  def sign_content(content) do
    :crypto.hmac(
      :sha256,
      Application.get_env(:binance, :secret_key),
      content
    )
    |> Base.encode16()
  end
end
