defmodule Binance.Util do
  @moduledoc false

  @doc """
  Sign a given string using given key
  """
  def sign_content(key, content) do
    # TODO: remove when we require OTP 24
    if Code.ensure_loaded?(:crypto) and function_exported?(:crypto, :mac, 4) do
      :hmac
      |> :crypto.mac(:sha256, key, content)
      |> Base.encode16()
    else
      :sha256
      |> :crypto.hmac(key, content)
      |> Base.encode16()
    end
  end

  @doc """
  Sign a given string using given key using secret key
  """
  def sign_content(key, content, key_type) when key_type == "rsa" do
    # Clean the key format
    case ExPublicKey.loads(key) do
      {:ok, rsa_priv_key} ->
        case ExPublicKey.sign(content, rsa_priv_key) do
          {:ok, signature} ->
            "#{Base.encode64(signature)}" |> URI.encode_www_form()

          {:error, reason} ->
            raise "Failed to sign: #{reason}"
        end

      {:error, reason} ->
        raise "Invalid RSA key: #{reason}"
    end
  end

  def sign_content(key, content, _key_type) do
    sign_content(key, content)
  end
end
