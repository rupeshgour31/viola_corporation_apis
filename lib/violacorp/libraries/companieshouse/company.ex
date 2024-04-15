defmodule Violacorp.Libraries.Companieshouse.Company do
  use HTTPoison.Base

  def httpcall(companyNumber)do

        companiesHouseToken = "Basic dElLSllSZTNmaFZZWkxlUEhMaHpMSDk4dFZsalNoeWxKZ1k1SHlxbTo="

        urlbase = "https://api.companieshouse.gov.uk/company/"
                  |> URI.merge(companyNumber)
                  |> URI.to_string()

        #    url = "https://api.companieshouse.gov.uk/company/09703795"
        url = urlbase
        headers = ["Authorization": companiesHouseToken, "Accept": "Application/json; Charset=utf-8"]
        {:ok, response} = HTTPoison.get(url, headers)
        Poison.decode!(response.body)
        |> IO.inspect()

  end

  def httpcall2(companyNumber, info)do

    companiesHouseToken = "Basic dElLSllSZTNmaFZZWkxlUEhMaHpMSDk4dFZsalNoeWxKZ1k1SHlxbTo="
    urlbase = "https://api.companieshouse.gov.uk/company/"
              |> URI.merge(companyNumber)
              |> URI.to_string()
    url = "#{urlbase}/#{info}"
    headers = ["Authorization": companiesHouseToken, "Accept": "Application/json; Charset=utf-8"]
    {:ok, response} = HTTPoison.get(url, headers)
    Poison.decode!(response.body)
    |> IO.inspect()

  end

  def getCompanyDetails(companyNumber)do
    _a = httpcall(companyNumber)
        "companyDetails"
  end

  def getCompanyOfficers(companyNumber)do
    _a = httpcall2(companyNumber, "officers")
    "companyOfficers"
  end

  def getCompanyAddress(companyNumber)do
    _a = httpcall2(companyNumber, "registered-office-address")
    "companyAddress"
  end

  def getCompanyInsolvency(companyNumber)do
    _a = httpcall2(companyNumber, "insolvency")
    "companyInsolvency"
  end

  def getCompanyFilingHistory(companyNumber)do
    _a = httpcall2(companyNumber, "filing-history")
    "companyFilingHistory"
  end



end