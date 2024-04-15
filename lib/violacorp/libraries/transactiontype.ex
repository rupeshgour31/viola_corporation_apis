defmodule Violacorp.Libraries.Transactiontype do

  @moduledoc "Accomplish Transaction Type Library"

def get_transaction_type(value) do
  map = %{
    3 => %{
      "type" => "",
      "title" => "Cash Withdrawal - ATM"
    },
    4 => %{
      "type" => "",
      "title" => "Purchase - POS"
    },
    11 => %{
      "type" => "",
      "title" => "Credit Card Load"
    },
    13 => %{
      "type" => "",
      "title" => "Transaction Reversal"
    },
    14 => %{
      "type" => "",
      "title" => "Bank Account Load"
    },
    16 => %{
      "type" => "",
      "title" => "Bank Account Withdrawl"
    },
    18 => %{
      "type" => "",
      "title" => "WIRE Load"
    },
    20 => %{
      "type" => "",
      "title" => "WIRE Withdrawl"
    },
    22 => %{
      "type" => "",
      "title" => "CHECK Load"
    },
    24 => %{
      "type" => "",
      "title" => "CHECK Withdrawl"
    },
    26 => %{
      "type" => "",
      "title" => "Purchase - Credit Adjustment"
    },
    28 => %{
      "type" => "",
      "title" => "Purchase - Debit Adjustment"
    },
    30 => %{
      "type" => "",
      "title" => "Purchase - Return"
    },
    32 => %{
      "type" => "",
      "title" => "Deposit To Merchant"
    },
    34 => %{
      "type" => "",
      "title" => "Withdrawal From Merchant"
    },
    36 => %{
      "type" => "",
      "title" => "Cash Withdrawal - Advance"
    },
    38 => %{
      "type" => "",
      "title" => "Purchase - Internet"
    },
    40 => %{
      "type" => "",
      "title" => "Purchase - Mail/Tel Order"
    },
    42 => %{
      "type" => "",
      "title" => "Purchase - Recurring Payment"
    },
    44 => %{
      "type" => "",
      "title" => "Purchase - Signature Cash Back"
    },
    46 => %{
      "type" => "",
      "title" => "Cash Withdrawal"
    },
    48 => %{
      "type" => "",
      "title" => "Purchase"
    },
    84 => %{
      "type" => "",
      "title" => "MANUAL Load"
    },
    86 => %{
      "type" => "",
      "title" => "MANUAL_Withdrawl"
    },
    88 => %{
      "type" => "",
      "title" => "Merchants Payout"
    },
    90 => %{
      "type" => "",
      "title" => "E-Wallet Send Internal"
    },
    91 => %{
      "type" => "",
      "title" => "E-Wallet Receive Internal"
    },
    92 => %{
      "type" => "",
      "title" => "E-Wallet Receive External"
    },
    96 => %{
      "type" => "",
      "title" => "Points Send Internal"
    },
    97 => %{
      "type" => "",
      "title" => "Points Receive Internal"
    },
    98 => %{
      "type" => "",
      "title" => "Points Receive External"
    },
    102 => %{
      "type" => "",
      "title" => "Debit Card Send Internal"
    },
    103 => %{
      "type" => "",
      "title" => "Debit Card Receive Internal"
    },
    104 => %{
      "type" => "",
      "title" => "Debit Card Receive External"
    },
    108 => %{
      "type" => "",
      "title" => "E-Wallet Send External"
    },
    110 => %{
      "type" => "",
      "title" => "Points Send Externale"
    },
    112 => %{
      "type" => "",
      "title" => "Debit Card Send External"
    },
    114 => %{
      "type" => "",
      "title" => "Payroll"
    },
    116 => %{
      "type" => "",
      "title" => "SYSTEM Activation Account"
    },
    118 => %{
      "type" => "",
      "title" => "SYSTEM Account Termination"
    },
    120 => %{
      "type" => "",
      "title" => "SYSTEM Debit Card Shipping"
    },
    122 => %{
      "type" => "",
      "title" => "SYSTEM NSF"
    },
    124 => %{
      "type" => "",
      "title" => "SYSTEM Lost Card"
    },
    126 => %{
      "type" => "",
      "title" => "SYSTEM Support"
    },
    128 => %{
      "type" => "",
      "title" => "SYSTEM Administration"
    },
    130 => %{
      "type" => "",
      "title" => "SYSTEM Account Suspension"
    },
    132 => %{
      "type" => "",
      "title" => "SYSTEM Account Re Activation"
    },
    134 => %{
      "type" => "",
      "title" => "SYSTEM Generic"
    },
    136 => %{
      "type" => "",
      "title" => "General Debit"
    },
    138 => %{
      "type" => "",
      "title" => "General Credit"
    },
    140 => %{
      "type" => "",
      "title" => "SYSTEM Balance Request"
    },
    142 => %{
      "type" => "",
      "title" => "Purchase - With Cash Back"
    },
    144 => %{
      "type" => "",
      "title" => "Bill Payment"
    },
    146 => %{
      "type" => "",
      "title" => "Money Transfer"
    },
    148 => %{
      "type" => "",
      "title" => "Quasi-Cash"
    },
    150 => %{
      "type" => "",
      "title" => "Cash Disbursement"
    },
    152 => %{
      "type" => "",
      "title" => "Point Manual Load"
    },
    154 => %{
      "type" => "",
      "title" => "Point General Load"
    },
    156 => %{
      "type" => "",
      "title" => "Point Manual Withdrawal"
    },
    158 => %{
      "type" => "",
      "title" => "Point General Withdrawal"
    },
    160 => %{
      "type" => "",
      "title" => "SYSTEM Decline"
    },
    162 => %{
      "type" => "",
      "title" => "VOUCHER Load"
    },
    164 => %{
      "type" => "",
      "title" => "Companion Account Request"
    },
    166 => %{
      "type" => "",
      "title" => "Cups Withdrawl"
    },
    168 => %{
      "type" => "",
      "title" => "Cups Load"
    },
    170 => %{
      "type" => "",
      "title" => "Account Renewal"
    },
    172 => %{
      "type" => "",
      "title" => "Seller Payment Send"
    },
    174 => %{
      "type" => "",
      "title" => "Seller Payment Receive"
    },
    176 => %{
      "type" => "",
      "title" => "Agent Transfer Send"
    },
    178 => %{
      "type" => "",
      "title" => "Agent Transfer Receive"
    },
    180 => %{
      "type" => "",
      "title" => "Agent Load Send"
    },
    182 => %{
      "type" => "",
      "title" => "Agent Load Receive"
    },
    184 => %{
      "type" => "",
      "title" => "Agent Withdrawal Send"
    },
    186 => %{
      "type" => "",
      "title" => "Agent Withdrawal Receive"
    },
    188 => %{
      "type" => "",
      "title" => "Reseller Purchase"
    },
    9 => %{
      "type" => "FEE",
      "title" => "Purchase - POS Fee"
    },
    10 => %{
      "type" => "FEE",
      "title" => "Cash Withdrawal - ATM Fee"
    },
    12 => %{
      "type" => "FEE",
      "title" => "Credit Card Load Fee"
    },
    15 => %{
      "type" => "FEE",
      "title" => "Bank Account Load Fee"
    },
    17 => %{
      "type" => "FEE",
      "title" => "Bank Account Withdrawl Fee"
    },
    19 => %{
      "type" => "FEE",
      "title" => "WIRE Load Fee"
    },
    21 => %{
      "type" => "FEE",
      "title" => "WIRE Withdrawl Fee"
    },
    23 => %{
      "type" => "FEE",
      "title" => "CHECK Load Fee"
    },
    25 => %{
      "type" => "FEE",
      "title" => "CHECK Withdrawl Fee"
    },
    27 => %{
      "type" => "FEE",
      "title" => "Purchase - Credit Adjustment Fee"
    },
    29 => %{
      "type" => "FEE",
      "title" => "Purchase - Debit Adjustment Fee"
    },
    31 => %{
      "type" => "FEE",
      "title" => "Purchase - Return Fee"
    },
    33 => %{
      "type" => "FEE",
      "title" => "Deposit To Merchant Fee"
    },
    35 => %{
      "type" => "FEE",
      "title" => "Withdrawal From Merchant Fee"
    },
    37 => %{
      "type" => "FEE",
      "title" => "Cash Withdrawal - Advance Fee"
    },
    39 => %{
      "type" => "FEE",
      "title" => "Purchase - Internet Fee"
    },
    41 => %{
      "type" => "FEE",
      "title" => "Purchase - Mail/Tel Order Fee"
    },
    43 => %{
      "type" => "FEE",
      "title" => "Purchase - Recurring Payment Fee"
    },
    45 => %{
      "type" => "FEE",
      "title" => "Purchase - Signature Cash Back Fee"
    },
    47 => %{
      "type" => "FEE",
      "title" => "Cash Withdrawal Fee"
    },
    49 => %{
      "type" => "FEE",
      "title" => "Purchase Fee"
    },
    85 => %{
      "type" => "FEE",
      "title" => "MANUAL Load Fee"
    },
    87 => %{
      "type" => "FEE",
      "title" => "MANUAL_Withdrawl Fee"
    },
    89 => %{
      "type" => "FEE",
      "title" => "Merchants Payout Fee"
    },
    93 => %{
      "type" => "FEE",
      "title" => "E-Wallet Send Internal Fee"
    },
    94 => %{
      "type" => "FEE",
      "title" => "E-Wallet Receive Internal Fee"
    },
    95 => %{
      "type" => "FEE",
      "title" => "E-Wallet Receive External Fee"
    },
    99 => %{
      "type" => "FEE",
      "title" => "Points Send Internal Fee"
    },
    100 => %{
      "type" => "FEE",
      "title" => "Points Receive Internal Fee"
    },
    101 => %{
      "type" => "FEE",
      "title" => "Points Receive External Fee"
    },
    105 => %{
      "type" => "FEE",
      "title" => "Debit Card Send Internal Fee"
    },
    106 => %{
      "type" => "FEE",
      "title" => "Debit Card Receive Internal Fee"
    },
    107 => %{
      "type" => "FEE",
      "title" => "Debit Card Receive External Fee"
    },
    109 => %{
      "type" => "FEE",
      "title" => "E-Wallet Send External Fee"
    },
    111 => %{
      "type" => "FEE",
      "title" => "Points Send External Fee"
    },
    113 => %{
      "type" => "FEE",
      "title" => "Debit Card Send ExternalFee"
    },
    115 => %{
      "type" => "FEE",
      "title" => "Payroll Fee"
    },
    117 => %{
      "type" => "FEE",
      "title" => "SYSTEM Activation Account Fee"
    },
    119 => %{
      "type" => "FEE",
      "title" => "SYSTEM Account Termination Fee"
    },
    121 => %{
      "type" => "FEE",
      "title" => "SYSTEM Debit Card Shipping Fee"
    },
    123 => %{
      "type" => "FEE",
      "title" => "SYSTEM NSF Fee"
    },
    125 => %{
      "type" => "FEE",
      "title" => "SYSTEM Lost Card Fee"
    },
    127 => %{
      "type" => "FEE",
      "title" => "SYSTEM Support Fee"
    },
    129 => %{
      "type" => "FEE",
      "title" => "SYSTEM Administration Fee"
    },
    131 => %{
      "type" => "FEE",
      "title" => "SYSTEM Account Suspension Fee"
    },
    133 => %{
      "type" => "FEE",
      "title" => "SYSTEM Account Re Activation Fee"
    },
    135 => %{
      "type" => "FEE",
      "title" => "SYSTEM Generic Fee"
    },
    137 => %{
      "type" => "FEE",
      "title" => "General Debit Fee"
    },
    139 => %{
      "type" => "FEE",
      "title" => "General Credit Fee"
    },
    141 => %{
      "type" => "FEE",
      "title" => "SYSTEM Balance Request Fee"
    },
    143 => %{
      "type" => "FEE",
      "title" => "Purchase - With Cash Back Fee"
    },
    145 => %{
      "type" => "FEE",
      "title" => "Bill Payment Fee"
    },
    147 => %{
      "type" => "FEE",
      "title" => "Money Transfer Fee"
    },
    149 => %{
      "type" => "FEE",
      "title" => "Quasi-Cash Fee"
    },
    151 => %{
      "type" => "FEE",
      "title" => "Cash Disbursement Fee"
    },
    153 => %{
      "type" => "FEE",
      "title" => "Point Manual Load Fee"
    },
    155 => %{
      "type" => "FEE",
      "title" => "Point General Load Fee"
    },
    157 => %{
      "type" => "FEE",
      "title" => "Point Manual Withdrawal Fee"
    },
    159 => %{
      "type" => "FEE",
      "title" => "Point General Withdrawal Fee"
    },
    165 => %{
      "type" => "FEE",
      "title" => "Companion Account Request Fee"
    },
    161 => %{
      "type" => "FEE",
      "title" => "SYSTEM Decline Fee"
    },
    163 => %{
      "type" => "FEE",
      "title" => "VOUCHER Load Fee"
    },
    167 => %{
      "type" => "FEE",
      "title" => "Cups Withdrawl Fee"
    },
    169 => %{
      "type" => "FEE",
      "title" => "Cups Load Fee"
    },
    171 => %{
      "type" => "FEE",
      "title" => "Account Renewal Fee"
    },
    173 => %{
      "type" => "FEE",
      "title" => "Seller Payment Send Fee"
    },
    175 => %{
      "type" => "FEE",
      "title" => "Seller Payment Receive Fee"
    },
    177 => %{
      "type" => "FEE",
      "title" => "Agent Transfer Send Fee"
    },
    179 => %{
      "type" => "FEE",
      "title" => "Agent Transfer Receive Fee"
    },
    181 => %{
      "type" => "FEE",
      "title" => "Agent Load Send Fee"
    },
    183 => %{
      "type" => "FEE",
      "title" => "Agent Load Receive Fee"
    },
    185 => %{
      "type" => "FEE",
      "title" => "Agent Withdrawal Send Fee"
    },
    187 => %{
      "type" => "FEE",
      "title" => "Agent Withdrawal Receive Fee"
    },
    189 => %{
      "type" => "FEE",
      "title" => "Reseller Purchase Fee"
    },
    191 => %{
      "type" => "FEE",
      "title" => "User Purchase Fee"
    },
    193 => %{
      "type" => "FEE",
      "title" => "Point Claim Send Fee"
    },
    195 => %{
      "type" => "FEE",
      "title" => "Point Claim Receive Fee"
    },
    197 => %{
      "type" => "FEE",
      "title" => "Point Payout Send Fee"
    },
    199 => %{
      "type" => "FEE",
      "title" => "Point Payout Receive Fee"
    },
    201 => %{
      "type" => "FEE",
      "title" => "Merchant Payment Fee"
    },
    203 => %{
      "type" => "FEE",
      "title" => "Chargeback Fee"
    },
    205 => %{
      "type" => "FEE",
      "title" => "FanaPay Load Fee"
    },
    207 => %{
      "type" => "FEE",
      "title" => "Merchant Cost Fee"
    },
    209 => %{
      "type" => "FEE",
      "title" => "Merchant Profit Fee"
    },
    211 => %{
      "type" => "FEE",
      "title" => "CashU Load Fee"
    },
    213 => %{
      "type" => "FEE",
      "title" => "Payment Fee"
    },
    215 => %{
      "type" => "FEE",
      "title" => "UKash Load Fee"
    },
    217 => %{
      "type" => "FEE",
      "title" => "Balance Inquiry Fee"
    },
    219 => %{
      "type" => "FEE",
      "title" => "OneCard Load Fee"
    },
    221 => %{
      "type" => "FEE",
      "title" => "Generic Transfer Send Fee"
    },
    223 => %{
      "type" => "FEE",
      "title" => "Generic Transfer Receive Fee"
    },
    225 => %{
      "type" => "FEE",
      "title" => "Refund Fee"
    },
    227 => %{
      "type" => "FEE",
      "title" => "Sales Tax Fee"
    },
    229 => %{
      "type" => "FEE",
      "title" => "Limited Debit Fee"
    },
    231 => %{
      "type" => "FEE",
      "title" => "Cash Withdrawal NSF Fee"
    },
    233 => %{
      "type" => "FEE",
      "title" => "Negative Balance Load Fee"
    },
    190 => %{
      "type" => "",
      "title" => "User Purchase"
    },
    192 => %{
      "type" => "",
      "title" => "Point Claim Send"
    },
    194 => %{
      "type" => "",
      "title" => "Point Claim Receive"
    },
    196 => %{
      "type" => "",
      "title" => "Point Payout Send"
    },
    198 => %{
      "type" => "",
      "title" => "Point Payout Receive"
    },
    200 => %{
      "type" => "",
      "title" => "Merchant Payment"
    },
    202 => %{
      "type" => "",
      "title" => "Chargeback"
    },
    204 => %{
      "type" => "",
      "title" => "FanaPay Load"
    },
    206 => %{
      "type" => "",
      "title" => "Merchant Cost"
    },
    208 => %{
      "type" => "",
      "title" => "Merchant Profit"
    },
    210 => %{
      "type" => "",
      "title" => "CashU Load"
    },
    212 => %{
      "type" => "",
      "title" => "Payment"
    },
    214 => %{
      "type" => "",
      "title" => "UKash Load"
    },
    216 => %{
      "type" => "",
      "title" => "Balance Inquiry"
    },
    218 => %{
      "type" => "",
      "title" => "OneCard Load"
    },
    220 => %{
      "type" => "",
      "title" => "TopUp"
    },
    222 => %{
      "type" => "",
      "title" => "TopUp"
    },
    224 => %{
      "type" => "",
      "title" => "Refund"
    },
    226 => %{
      "type" => "",
      "title" => "Sales Tax"
    },
    228 => %{
      "type" => "",
      "title" => "Limited Debit"
    },
    230 => %{
      "type" => "",
      "title" => "Cash Withdrawal NSF"
    },
    232 => %{
      "type" => "",
      "title" => "Negative Balance Load"
    },
    3001 => %{
      "type" => "FEE",
      "title" => "Charge monthly fee"
    },
    3002 => %{
      "type" => "QR",
      "title" => "Payment by QR"
    },
    3003 => %{
      "type" => "Money Send",
      "title" => "TopUp"
    },
    3004 => %{
      "type" => "Money Receive",
      "title" => "TopUp"
    },
    3005 => %{
      "type" => "Money Send",
      "title" => "Move Fund"
    },
    3006 => %{
      "type" => "Money Receive",
      "title" => "Move Fund"
    },
    3007 => %{
      "type" => "Transfer",
      "title" => "Money Sent"
    },
    3008 => %{
      "type" => "Transfer",
      "title" => "Money Received"
    }
  }

  if Map.has_key?(map, value) do
    {:ok, ok} = Map.fetch(map, value)
    ok
  else
    %{
      "type" => nil,
      "title" => nil
    }
  end

end
end