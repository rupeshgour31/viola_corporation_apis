defmodule Violacorp.Libraries.Validatecard do
  @moduledoc """
  Validate card Library to checksum credit cards.
  """

  @doc """
  Check if a credit card number is valid based on luhn.
  """
  def valid?(cc) when is_integer(cc) do
    Integer.digits(cc)
    |> Enum.reverse
    |> Enum.with_index
    |> Enum.map(&double_digit(&1))
    |> Enum.sum
    |> divisible?(10)
  end

  def valid?(cc) when is_binary(cc) do
    case Integer.parse(cc) do
      {int, ""} -> valid?(int)
      _ -> false
    end
  end

  defp divisible?(left, right) do
    rem(left, right) == 0
  end

  require Integer
  # double every second digit
  defp double_digit({digit, index}) when Integer.is_odd(index) do
    digit = digit * 2
    # 10 = 1+0, 18 = 1+8
    if digit > 9, do: digit - 9, else: digit
  end

  defp double_digit({digit, _}), do: digit


end
