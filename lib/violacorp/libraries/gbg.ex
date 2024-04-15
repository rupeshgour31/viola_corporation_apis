defmodule Violacorp.Libraries.Gbg do

  @moduledoc "GBG Library"

  require Logger

  alias Violacorp.Repo
  alias Violacorp.Schemas.Thirdpartylogs

  # Authenticate KYC
  def kyc_verify(params) do

    username = Application.get_env(:violacorp, :gbg_username)
    password = Application.get_env(:violacorp, :gbg_password)
    profilie_id = Application.get_env(:violacorp, :gbg_profile_id)

    gbg_soap_action = Application.get_env(:violacorp, :gbg_soap_action)
    url = Application.get_env(:violacorp, :gbg_url)
    commanall_id = params.commanall_id
    header = %{
      "content-type" => "text/xml",
      "SOAPAction" => "#{gbg_soap_action}"
    }

    body_part_first = "<soapenv:Envelope xmlns:ns='http://www.id3global.com/ID3gWS/2013/04' xmlns:soap='soap' xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/'>
                        <soapenv:Header xmlns:wsa='http://www.w3.org/2005/08/addressing'>
                           <wsse:Security soapenv:mustUnderstand='1' xmlns:wsse='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd' xmlns:wsu='http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd'>
                              <wsse:UsernameToken >
                                 <wsse:Username>#{username}</wsse:Username>
                                 <wsse:Password>#{password}</wsse:Password>
                               </wsse:UsernameToken>
                           </wsse:Security>
                           </soapenv:Header>
                           <soapenv:Body>
                              <ns:AuthenticateSP>
                                 <ns:ProfileIDVersion>
                                    <ns:ID>#{profilie_id}</ns:ID>
                                        <Version>0</Version>
                                 </ns:ProfileIDVersion>
                                 <ns:CustomerReference></ns:CustomerReference>
                                    <ns:InputData>
                                    <ns:Personal>
                                       <ns:PersonalDetails>
                                          <ns:Title>#{params.title}</ns:Title>
                                          <ns:Forename>#{params.forename}</ns:Forename>
                                           <ns:MiddleName>#{params.middlename}</ns:MiddleName>
                                          <ns:Surname>#{params.surname}</ns:Surname>
                                          <ns:Gender>#{params.gender}</ns:Gender>
                                         <ns:DOBDay>#{params.dobDay}</ns:DOBDay>
                                          <ns:DOBMonth>#{params.dobMonth}</ns:DOBMonth>
                                          <ns:DOBYear>#{params.dobYear}</ns:DOBYear>
                                       </ns:PersonalDetails>
                                    </ns:Personal>
                                    <ns:Addresses>
                                       <ns:CurrentAddress>
                                          <ns:Country>#{params.country}</ns:Country>
                                          <ns:Street>#{params.street}</ns:Street>
                                          <ns:City>#{params.city}</ns:City>
                                          <ns:Region></ns:Region>
                                          <ns:ZipPostcode>#{params.zipPostcode}</ns:ZipPostcode>
                                          <ns:Building>#{params.building}</ns:Building>
                                          <ns:Premise></ns:Premise>
                                       </ns:CurrentAddress>
                                    </ns:Addresses>
                                   <ns:IdentityDocuments>"

    body_part_second = if is_nil(params.drivingLicenceNumber) do
      " <ns:InternationalPassport>
                                <ns:Number>#{params.passportNumber}</ns:Number>
                                <ns:ExpiryDay>#{params.passportExpiryDay}</ns:ExpiryDay>
                                <ns:ExpiryMonth>#{params.passportExpiryMonth}</ns:ExpiryMonth>
                                <ns:ExpiryYear>#{params.passportExpiryYear}</ns:ExpiryYear>
                                <ns:CountryOfOrigin>#{params.countryOfOrigin}</ns:CountryOfOrigin>
                             </ns:InternationalPassport>"
    else
      "<ns:UK>
                                 <ns:DrivingLicence>
                                   <ns:Number>#{params.drivingLicenceNumber}</ns:Number>
                                </ns:DrivingLicence>
                             </ns:UK>"
    end

    body_part_third = "</ns:IdentityDocuments>
                                    </ns:InputData>
                                </ns:AuthenticateSP>
                             </soapenv:Body>
                          </soapenv:Envelope>"

    body = "#{body_part_first}#{body_part_second}#{body_part_third}"
    Logger.warn "GBG Request: #{body}"
    output = post_http(url, header, body)
    Logger.warn "GBG Response: #{output}"

    request = XmlToMap.naive_map(body)
    result = XmlToMap.naive_map(output)



    _response = if !is_nil(
      result["{http://schemas.xmlsoap.org/soap/envelope/}Envelope"]["{http://schemas.xmlsoap.org/soap/envelope/}Body"]["AuthenticateSPResponse"]
    ) do
      response = result["{http://schemas.xmlsoap.org/soap/envelope/}Envelope"]["{http://schemas.xmlsoap.org/soap/envelope/}Body"]["AuthenticateSPResponse"]
      band_text = response["AuthenticateSPResult"]["BandText"]
      authenticationID = response["AuthenticateSPResult"]["AuthenticationID"]

      status = if band_text == "Pass" do
                  "A"
              else
                  if band_text == "Refer" do
                      "RF"
                  else
                      "R"
                  end
              end

      # log for request and response
      api_status = if band_text == "Pass", do: "S", else: "F"
      third_party_log = %{
        commanall_id: "#{commanall_id}",
        section: "GBG",
        method: "POST",
        request: Poison.encode!(request),
        response: Poison.encode!(result),
        status: api_status,
        inserted_by: commanall_id
      }
      changeset = Thirdpartylogs.changeset(%Thirdpartylogs{}, third_party_log)
      Repo.insert(changeset)

      %{"status" => status, "authenticate_id" => authenticationID, "request_response" => Poison.encode!(%{"request" => request, "response" => result})}
    else
        # log for request and response
        third_party_log = %{
          commanall_id: "#{commanall_id}",
          section: "GBG",
          method: "POST",
          request: Poison.encode!(request),
          response: Poison.encode!(result),
          status: "F",
          inserted_by: commanall_id
        }
        changeset = Thirdpartylogs.changeset(%Thirdpartylogs{}, third_party_log)
        Repo.insert(changeset)
      %{"status" => "R", "authenticate_id" => "0", "request_response" => Poison.encode!(%{"request" => request, "response" => result})}
    end
  end

  defp post_http(url, header, body) do
    case HTTPoison.post(url, body, header, [recv_timeout: 50_000]) do
      {:ok, %{status_code: 200, body: body}} -> body
      {:ok, %{status_code: 404}} -> "404 not found!"
      {:ok, %{status_code: 401, body: body}} -> body
      {:ok, %{status_code: 400, body: body}} -> body
      {:ok, %{status_code: 500, body: body}} -> body
      {:error, %{reason: reason}} -> reason
    end
  end

end