defmodule Violacorp.Libraries.Sectors do

  @moduledoc "Define sector of business"

  def get_sector() do
    _map = %{
      1 => %{
        "id" => "1",
        "title" => "Accountancy, banking and finance"
      },
      2 => %{
        "id" => "2",
        "title" => "Business, consulting and management"
      },
      3 => %{
        "id" => "3",
        "title" => "Charity and voluntary work"
      },
      4 => %{
        "id" => "4",
        "title" => "Creative arts and design"
      },
      5 => %{
        "id" => "5",
        "title" => "Energy and utilities"
      },
      6 => %{
        "id" => "6",
        "title" => "Engineering and manufacturing"
      },
      7 => %{
        "id" => "7",
        "title" => "Environment and agriculture"
      },
      8 => %{
        "id" => "8",
        "title" => "Healthcare"
      },
      9 => %{
        "id" => "9",
        "title" => "Hospitality and events management"
      },
      10 => %{
        "id" => "10",
        "title" => "Information technology"
      },
      11 => %{
        "id" => "11",
        "title" => "Law"
      },
      12 => %{
        "id" => "12",
        "title" => "Law enforcement and security"
      },
      13 => %{
        "id" => "13",
        "title" => "Leisure, sport and tourism"
      },
      14 => %{
        "id" => "14",
        "title" => "Marketing, advertising and PR"
      },
      15 => %{
        "id" => "15",
        "title" => "Media and internet"
      },
      16 => %{
        "id" => "16",
        "title" => "Property and construction"
      },
      17 => %{
        "id" => "17",
        "title" => "Public services and administration"
      },
      18 => %{
        "id" => "18",
        "title" => "Recruitment and HR"
      },
      19 => %{
        "id" => "19",
        "title" => "Retail"
      },
      20 => %{
        "id" => "20",
        "title" => "Sales"
      },
      21 => %{
        "id" => "21",
        "title" => "Science and pharmaceuticals"
      },
      22 => %{
        "id" => "22",
        "title" => "Social care"
      },
      23 => %{
        "id" => "23",
        "title" => "Teacher training and education"
      },
      24 => %{
        "id" => "24",
        "title" => "Transport and logistics"
      }
    }

#    if Map.has_key?(map, value) do
#      {:ok, ok} = Map.fetch(map, value)
#      ok
#    else
#      %{
#        "id" => nil,
#        "title" => nil
#      }
#    end

  end


  def get_value_monthly_transfer() do
    _map = %{
      1 => %{
        "id" => "1",
        "title" => "< £ 1000.00"
      },
      2 => %{
        "id" => "2",
        "title" => "£ 1000.01 - £ 10,000.00"
      },
      3 => %{
        "id" => "3",
        "title" => "£ 10,000.01 - £ 50,000.00"
      },
      4 => %{
        "id" => "4",
        "title" => "£ 50,000.01 - £ 100,000.00"
      },
      5 => %{
        "id" => "5",
        "title" => "£ 100,000.01 >"
      }
    }

#    if Map.has_key?(map, value) do
#      {:ok, ok} = Map.fetch(map, value)
#      ok
#    else
#      %{
#        "id" => nil,
#        "title" => nil
#      }
#    end

  end

end