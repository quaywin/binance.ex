defmodule Binance.Futures.Position do
  defstruct [
    :entry_price,
    :leverage,
    :max_notional_value,
    :liquidation_price,
    :mark_price,
    :position_amt,
    :symbol,
    :unRealized_profit,
    :position_side,
    :notional,
    :break_even_price
  ]

  use ExConstructor
end
