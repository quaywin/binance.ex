defmodule Binance.Futures do
  alias Binance.Futures.Rest.HTTPClient

  @type error ::
          {:binance_error, %{code: integer(), message: String.t()}}
          | {:http_error, any()}
          | {:poison_decode_error, any()}
          | {:config_missing, String.t()}

  # Server

  @doc """
  Pings Binance API. Returns `{:ok, %{}}` if successful, `{:error, reason}` otherwise
  """
  @spec ping() :: {:ok, %{}, any()} | {:error, error()}
  def ping() do
    HTTPClient.get_binance("/fapi/v1/ping")
  end

  @doc """
  Get binance server time in unix epoch.

  ## Example
  ```
  {:ok, 1515390701097}
  ```

  """
  @spec get_server_time() :: {:ok, integer(), any()} | {:error, error()}
  def get_server_time() do
    case HTTPClient.get_binance("/fapi/v1/time") do
      {:ok, %{"serverTime" => time}, headers} -> {:ok, time, headers}
      err -> err
    end
  end

  @spec get_index_price(String.t()) :: {:ok, map(), any()} | {:error, error()}
  def get_index_price(instrument) do
    case HTTPClient.get_binance("/fapi/v1/premiumIndex?symbol=#{instrument}") do
      {:ok, data, headers} -> {:ok, data, headers}
      err -> err
    end
  end

  @spec get_best_ticker(String.t()) :: {:ok, map(), any()} | {:error, error()}
  def get_best_ticker(instrument) do
    case HTTPClient.get_binance("/fapi/v1/ticker/bookTicker?symbol=#{instrument}") do
      {:ok, data, headers} -> {:ok, data, headers}
      err -> err
    end
  end

  @spec get_kline_data(String.t(), String.t(), number) :: {:ok, map(), any()} | {:error, error()}
  def get_kline_data(instrument, interval, limit) do
    case HTTPClient.get_binance(
           "/fapi/v1/klines?symbol=#{instrument}&interval=#{interval}&limit=#{limit}"
         ) do
      {:ok, data, headers} -> {:ok, data, headers}
      err -> err
    end
  end

  @spec get_continious_kline_data(String.t(), String.t(), String.t(), number) ::
          {:ok, map(), any()} | {:error, error()}
  def get_continious_kline_data(instrument, interval, contract_type, limit) do
    case HTTPClient.get_binance(
           "/fapi/v1/continuousKlines?pair=#{instrument}&interval=#{interval}&limit=#{limit}&contractType=#{contract_type}"
         ) do
      {:ok, data, headers} -> {:ok, data, headers}
      err -> err
    end
  end

  @spec get_exchange_info() :: {:ok, %Binance.ExchangeInfo{}, any()} | {:error, error()}
  def get_exchange_info() do
    case HTTPClient.get_binance("/fapi/v1/exchangeInfo") do
      {:ok, data, headers} -> {:ok, Binance.ExchangeInfo.new(data), headers}
      err -> err
    end
  end

  @spec create_listen_key(map()) :: {:ok, map(), any()} | {:error, error()}
  def create_listen_key(params, config \\ nil) do
    arguments =
      %{
        timestamp: :os.system_time(:millisecond)
      }
      |> Map.merge(
        unless(is_nil(params[:timestamp]), do: %{timestamp: params[:timestamp]}, else: %{})
      )
      |> Map.merge(
        unless(is_nil(params[:recv_window]), do: %{recvWindow: params[:recv_window]}, else: %{})
      )

    case HTTPClient.post_binance("/fapi/v1/listenKey", arguments, config) do
      {:ok, %{"code" => code, "msg" => msg}, headers} ->
        {:error, {:binance_error, %{code: code, msg: msg}}, headers}

      data ->
        data
    end
  end

  @spec keep_alive_listen_key(map(), map() | nil) ::
          {:ok, %{}, any()} | {:error, error()}
  def keep_alive_listen_key(params, config \\ nil) do
    arguments =
      %{
        timestamp: :os.system_time(:millisecond)
      }
      |> Map.merge(
        unless(is_nil(params[:timestamp]), do: %{timestamp: params[:timestamp]}, else: %{})
      )
      |> Map.merge(
        unless(is_nil(params[:recv_window]), do: %{recvWindow: params[:recv_window]}, else: %{})
      )

    case HTTPClient.put_binance("/fapi/v1/listenKey", arguments, config) do
      {:ok, %{"code" => code, "msg" => msg}, headers} ->
        {:error, {:binance_error, %{code: code, msg: msg}}, headers}

      data ->
        data
    end
  end

  @doc """
  Retrieves the bids & asks of the order book up to the depth for the given symbol

  ## Example
  ```
  {:ok,
    %Binance.OrderBook{
      asks: [
        ["8400.00000000", "2.04078100", []],
        ["8405.35000000", "0.50354700", []],
        ["8406.00000000", "0.32769800", []],
        ["8406.33000000", "0.00239000", []],
        ["8406.51000000", "0.03241000", []]
      ],
      bids: [
        ["8393.00000000", "0.20453200", []],
        ["8392.57000000", "0.02639000", []],
        ["8392.00000000", "1.40893300", []],
        ["8390.09000000", "0.07047100", []],
        ["8388.72000000", "0.04577400", []]
      ],
      last_update_id: 113634395
    }
  }
  ```
  """
  @spec get_depth(String.t(), integer) :: {:ok, %Binance.OrderBook{}, any()} | {:error, error()}
  def get_depth(symbol, limit) do
    case HTTPClient.get_binance("/fapi/v1/depth?symbol=#{symbol}&limit=#{limit}") do
      {:ok, data, headers} -> {:ok, Binance.OrderBook.new(data), headers}
      err -> err
    end
  end

  # Account

  @doc """
  Fetches user account from binance

  In the case of a error on binance, for example with invalid parameters, `{:error, {:binance_error, %{code: code, msg: msg}}}` will be returned.

  Please read https://binanceapitest.github.io/Binance-Futures-API-doc/trade_and_account/
  """
  @spec get_account(map() | nil) :: {:ok, %Binance.Account{}, any()} | {:error, error()}
  def get_account(config \\ nil) do
    case HTTPClient.get_binance("/fapi/v1/account", %{}, config) do
      {:ok, data, headers} ->
        {:ok, Binance.Futures.Account.new(data), headers}

      error ->
        error
    end
  end

  @spec get_position(map() | nil) ::
          {:ok, list(%Binance.Futures.Position{}), any()} | {:error, error()}
  def get_positions(params \\ %{}, config \\ nil) do
    case HTTPClient.get_binance("/fapi/v2/positionRisk", %{}, config) do
      {:ok, data, headers} ->
        {:ok, Enum.map(data, &Binance.Futures.Position.new(&1)), headers}

      error ->
        error
    end
  end

  # Order

  @doc """
  Creates a new order on Binance Futures

  In the case of a error on Binance, for example with invalid parameters, `{:error, {:binance_error, %{code: code, msg: msg}}}` will be returned.

  Please read https://binanceapitest.github.io/Binance-Futures-API-doc/trade_and_account/#new-order-trade
  """
  @spec create_order(map(), map() | nil) :: {:ok, map(), any()} | {:error, error()}
  def create_order(
        %{symbol: symbol, side: side, type: type} = params,
        config \\ nil
      ) do
    arguments = %{
      symbol: symbol,
      side: side,
      type: type,
      timestamp: params[:timestamp] || :os.system_time(:millisecond)
    }

    arguments =
      arguments
      |> Map.merge(
        unless(is_nil(params[:quantity]), do: %{quantity: params[:quantity]}, else: %{})
      )
      |> Map.merge(
        unless(
          is_nil(params[:new_client_order_id]),
          do: %{newClientOrderId: params[:new_client_order_id]},
          else: %{}
        )
      )
      |> Map.merge(
        unless(is_nil(params[:stop_price]), do: %{stopPrice: params[:stop_price]}, else: %{})
      )
      |> Map.merge(
        unless(
          is_nil(params[:time_in_force]),
          do: %{timeInForce: params[:time_in_force]},
          else: %{}
        )
      )
      |> Map.merge(unless(is_nil(params[:price]), do: %{price: params[:price]}, else: %{}))
      |> Map.merge(
        unless(is_nil(params[:recv_window]), do: %{recvWindow: params[:recv_window]}, else: %{})
      )
      |> Map.merge(
        unless(is_nil(params[:working_type]), do: %{workingType: params[:working_type]}, else: %{})
      )
      |> Map.merge(
        unless(is_nil(params[:close_position]), do: %{closePosition: params[:close_position]}, else: %{})
      )

    case HTTPClient.post_binance("/fapi/v1/order", arguments, config) do
      {:ok, data, headers} ->
        {:ok, Binance.Futures.Order.new(data), headers}

      error ->
        error
    end
  end

  def prepare_create_order(
        %{symbol: symbol, side: side, type: type, quantity: quantity} = params,
        config \\ nil
      ) do
    arguments = %{
      symbol: symbol,
      side: side,
      type: type,
      quantity: quantity,
      timestamp: params[:timestamp] || :os.system_time(:millisecond)
    }

    arguments =
      arguments
      |> Map.merge(
        unless(
          is_nil(params[:new_client_order_id]),
          do: %{newClientOrderId: params[:new_client_order_id]},
          else: %{}
        )
      )
      |> Map.merge(
        unless(is_nil(params[:stop_price]), do: %{stopPrice: params[:stop_price]}, else: %{})
      )
      |> Map.merge(
        unless(
          is_nil(params[:time_in_force]),
          do: %{timeInForce: params[:time_in_force]},
          else: %{}
        )
      )
      |> Map.merge(unless(is_nil(params[:price]), do: %{price: params[:price]}, else: %{}))
      |> Map.merge(
        unless(is_nil(params[:recv_window]), do: %{recvWindow: params[:recv_window]}, else: %{})
      )

    {:ok, url, headers, argument_string} =
      HTTPClient.prepare_request(
        :post,
        "https://fapi.binance.com/fapi/v1/order",
        arguments,
        config,
        true
      )

    %{
      method: "POST",
      url: url,
      headers: headers,
      body: argument_string
    }
  end

  @doc """
  Get all open orders, alternatively open orders by symbol (params[:symbol])

  Weight: 1 for a single symbol; 40 when the symbol parameter is omitted

  ## Example
  ```
  {:ok,
    [%Binance.Futures.Order{price: "0.1", orig_qty: "1.0", executed_qty: "0.0", ...},
     %Binance.Futures.Order{...},
     %Binance.Futures.Order{...},
     %Binance.Futures.Order{...},
     %Binance.Futures.Order{...},
     %Binance.Futures.Order{...},
     ...]}
  ```

  Read more: https://binanceapitest.github.io/Binance-Futures-API-doc/trade_and_account/#current-open-orders-user_data
  """
  @spec get_open_orders(map(), map() | nil) ::
          {:ok, list(%Binance.Futures.Order{}), any()} | {:error, error()}
  def get_open_orders(params \\ %{}, config \\ nil) do
    case HTTPClient.get_binance("/fapi/v1/openOrders", params, config) do
      {:ok, data, headers} -> {:ok, Enum.map(data, &Binance.Futures.Order.new(&1)), headers}
      err -> err
    end
  end

  @doc """
  Get order by symbol and either orderId or origClientOrderId are mandatory

  Weight: 1

  ## Example
  ```
  {:ok, %Binance.Futures.Order{price: "0.1", origQty: "1.0", executedQty: "0.0", ...}}
  ```

  Info: https://binanceapitest.github.io/Binance-Futures-API-doc/trade_and_account/#query-order-user_data
  """
  @spec get_order(map(), map() | nil) ::
          {:ok, list(%Binance.Futures.Order{}), any()} | {:error, error()}
  def get_order(params, config \\ nil) do
    arguments =
      %{
        symbol: params[:symbol]
      }
      |> Map.merge(
        unless(is_nil(params[:order_id]), do: %{orderId: params[:order_id]}, else: %{})
      )
      |> Map.merge(
        unless(
          is_nil(params[:orig_client_order_id]),
          do: %{origClientOrderId: params[:orig_client_order_id]},
          else: %{}
        )
      )

    case HTTPClient.get_binance("/fapi/v1/order", arguments, config) do
      {:ok, data, headers} -> {:ok, Binance.Futures.Order.new(data), headers}
      err -> err
    end
  end

  @doc """
  Cancel an active order.

  Symbol and either orderId or origClientOrderId must be sent.

  Returns `{:ok, %Binance.Futures.Order{}}` or `{:error, reason}`.

  Weight: 1

  Info: https://binanceapitest.github.io/Binance-Futures-API-doc/trade_and_account/#cancel-order-trade
  """
  @spec cancel_order(map(), map() | nil) ::
          {:ok, %Binance.Futures.Order{}, any()} | {:error, error()}
  def cancel_order(params, config \\ nil) do
    arguments =
      %{
        symbol: params[:symbol]
      }
      |> Map.merge(
        unless(is_nil(params[:order_id]), do: %{orderId: params[:order_id]}, else: %{})
      )
      |> Map.merge(
        unless(
          is_nil(params[:orig_client_order_id]),
          do: %{origClientOrderId: params[:orig_client_order_id]},
          else: %{}
        )
      )

    case HTTPClient.delete_binance("/fapi/v1/order", arguments, config) do
      {:ok, %{"rejectReason" => _} = err, headers} -> {:error, err, headers}
      {:ok, data, headers} -> {:ok, Binance.Futures.Order.new(data), headers}
      err -> err
    end
  end

  def prepare_cancel_order(params, config \\ nil) do
    arguments =
      %{
        symbol: params[:symbol]
      }
      |> Map.merge(
        unless(is_nil(params[:order_id]), do: %{orderId: params[:order_id]}, else: %{})
      )
      |> Map.merge(
        unless(
          is_nil(params[:orig_client_order_id]),
          do: %{origClientOrderId: params[:orig_client_order_id]},
          else: %{}
        )
      )

    {:ok, url, headers} =
      HTTPClient.prepare_request(
        :delete,
        "https://fapi.binance.com/fapi/v1/order",
        arguments,
        config,
        true
      )

    %{
      method: "DELETE",
      url: url,
      headers: headers
    }
  end

  @spec cancel_batch_order(map(), map() | nil) :: {:ok, list, any()} | {:error, error()}
  def cancel_batch_order(params, config \\ nil) do
    arguments =
      %{
        symbol: params[:symbol]
      }
      |> Map.merge(
        if(!!params[:order_id_list], do: %{orderIdList: params[:order_id_list]}, else: %{})
      )
      |> Map.merge(
        if(
          !!params[:orig_client_order_id_list],
          do: %{origClientOrderIdList: params[:orig_client_order_id_list]},
          else: %{}
        )
      )

    case HTTPClient.delete_binance("/fapi/v1/batchOrders", arguments, config) do
      {:ok, %{"rejectReason" => _} = err, headers} -> {:error, err, headers}
      {:ok, data, headers} -> {:ok, data, headers}
      err -> err
    end
  end

  @doc """
  Cancel all orders for a symbol (params[:symbol])

  Weight: 1

  ## Example
  ```
  Binance.Futures.cancel_all_orders(%{symbol: "BTCUSDT"}, config)

  Read more: https://binance-docs.github.io/apidocs/futures/en/#cancel-all-open-orders-trade
  """
  @spec cancel_all_orders(map(), map() | nil) :: {:ok, any(), any()} | {:error, any()}
  def cancel_all_orders(params, config \\ nil) do
    case HTTPClient.delete_binance("/fapi/v1/allOpenOrders", params, config) do
      {:ok, %{"rejectReason" => _} = err, headers} -> {:error, err, headers}
      {:ok, data, headers} -> {:ok, data, headers}
      err -> err
    end
  end

  @spec get_trading_status(map(), map() | nil) :: {:ok, any(), any()} | {:error, any()}
  def get_trading_status(params, config \\ nil) do
    case HTTPClient.get_binance("/fapi/v1/apiTradingStatus", params, config) do
      {:ok, data, headers} -> {:ok, data, headers}
      err -> err
    end
  end

  def change_leverage(
        %{symbol: symbol, leverage: leverage} = params,
        config \\ nil
      ) do
    arguments = %{
      symbol: symbol,
      leverage: leverage,
      timestamp: params[:timestamp] || :os.system_time(:millisecond)
    }

    case HTTPClient.post_binance("/fapi/v1/leverage", arguments, config) do
      {:ok, data, headers} ->
        {:ok, data, headers}

      error ->
        error
    end
  end

end
