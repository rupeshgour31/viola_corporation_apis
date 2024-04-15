defmodule Violacorp.Libraries.Signaturedev do

  @moduledoc "Clearbank Generate Signaturedev"

  # Generate Digital Signature
  def digital_signature(string) do

    # Private Key
    private_key = System.get_env("VC_PRIVATE_KEY")
    {:ok, rawSkey} = File.read(private_key)
    [encSKey] = :public_key.pem_decode(rawSkey)
    sKey = :public_key.pem_entry_decode(encSKey)

    signature = :public_key.sign(string, :sha256, sKey, [{:rsa_padding, :rsa_pkcs1_padding}])
                |> Base.encode64

    api_token = Application.get_env(:violacorp, :api_token)
    api_url = Application.get_env(:violacorp, :api_url)

    _response_token = %{"signature" => signature, "token" => api_token, "request_id" => randnumber(), "url" => api_url}
  end

  # Verify Digital Signature
  def verify_signature(signature, string) do
    public_key = System.get_env("VC_PUBLIC_KEY")
    {:ok, rawSkey} = File.read(public_key)
    [encSKey] = :public_key.pem_decode(rawSkey)
    pKey = :public_key.pem_entry_decode(encSKey)

    {:ok, ssgn} = Base.decode64(signature)

    _signature_response = :public_key.verify(string, :sha256, ssgn, pKey, [{:rsa_padding, :rsa_pkcs1_padding}])
    _signature_response = %{"status" => true}
  end

  # Generate Random Number
  def randnumber() do
    _currentdatetime = NaiveDateTime.utc_now()
                       |> NaiveDateTime.truncate(:microsecond)
                       |> to_string()
                       |> String.replace( ~r/[-.: ]+/, "")
  end

  # Generate Digital Signature
  def token() do
    api_token = Application.get_env(:violacorp, :api_token)
    api_url = Application.get_env(:violacorp, :api_url)

    _response_token = %{"token" => api_token, "url" => api_url}
  end

end