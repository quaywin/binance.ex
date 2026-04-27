defmodule Binance.Futures.AlgoOrder do
  defstruct [
    :algo_id,
    :client_algo_id,
    :algo_type,
    :order_type,
    :symbol,
    :side,
    :position_side,
    :time_in_force,
    :quantity,
    :algo_status,
    :actual_order_id,
    :actual_price,
    :trigger_price,
    :price,
    :iceberg_quantity,
    :tp_trigger_price,
    :tp_price,
    :sl_trigger_price,
    :sl_price,
    :tp_order_type,
    :self_trade_prevention_mode,
    :working_type,
    :price_match,
    :close_position,
    :price_protect,
    :reduce_only,
    :create_time,
    :update_time,
    :trigger_time,
    :good_till_date
  ]

  use ExConstructor
end
