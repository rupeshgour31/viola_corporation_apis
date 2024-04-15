defmodule ViolacorpWeb.Main.Assetstore do
  @moduledoc """
  Responsible for accepting files and uploading them to an asset store.
  """

  import Mogrify
  alias ExAws.S3

  @doc """
  Accepts a base64 encoded image and uploads it to S3.

  ## Examples

      iex> upload_image(...)
      "https://image_bucket.s3.eu-west-2.amazonaws.com/dbaaee81609747ba82bea2453cc33b83.png"

  """
  @spec upload_image(String.t) :: s3_url :: String.t
  def upload_image(image_base64) do
    image_bucket = Application.get_env(:violacorp, :aws_bucket)
    mode = Application.get_env(:violacorp, :aws_mode)
    region = Application.get_env(:violacorp, :aws_region)

    # Decode the image
    {filename, image_binary} = prepare_image(image_base64)
    # Upload to S3
    _srsp =
      S3.put_object(image_bucket, "#{mode}/#{filename}", image_binary)
      |> ExAws.request!

    # Generate the full URL to the newly uploaded image
    "https://#{image_bucket}.#{region}/#{mode}/#{filename}"
  end

  @spec upload_document(String.t) :: s3_url :: String.t
  def upload_document(image_base64) do
    image_bucket = Application.get_env(:violacorp, :aws_bucket)
    mode = Application.get_env(:violacorp, :aws_mode)
    region = Application.get_env(:violacorp, :aws_region)

    # Get the file's extension
    file_extension = Path.extname("some_image.pdf")

    # Generate the UUID
    file_uuid = UUID.uuid4(:hex)

    # Set the S3 filename
    s3_filename = "#{file_uuid}#{file_extension}"

    # Decode the image
    {:ok, file_binary} = Base.decode64(image_base64)

    # Upload the file to S3
    {:ok, _} =
      ExAws.S3.put_object(image_bucket, "#{mode}/#{s3_filename}", file_binary)
      |> ExAws.request()


    # Generate the full URL to the newly uploaded image
    "https://#{image_bucket}.#{region}/#{mode}/#{s3_filename}"
  end

  @spec upload_file(String.t) :: s3_url :: String.t
  def upload_file(image_base64) do

    image_bucket = Application.get_env(:violacorp, :aws_bucket)
    mode = Application.get_env(:violacorp, :aws_mode)
    region = Application.get_env(:violacorp, :aws_region)

    # Get the file's extension
    file_extension = Path.extname("file.csv")

    # Generate the UUID
    file_uuid = UUID.uuid4(:hex)

    # Set the S3 filename
    s3_filename = "#{file_uuid}#{file_extension}"

    # Decode the image
    {:ok, file_binary} = Base.decode64(image_base64)

    # Upload the file to S3
    {:ok, _} =
      ExAws.S3.put_object(image_bucket, "#{mode}/#{s3_filename}", file_binary)
      |> ExAws.request()


    # Generate the full URL to the newly uploaded image
    "https://#{image_bucket}.#{region}/#{mode}/#{s3_filename}"
  end

  # Generates a unique filename with a given extension
  defp unique_filename(extension) do
    UUID.uuid4(:hex) <> extension
  end

  # Helper functions to read the binary to determine the image extension
  defp image_extension(<<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, _::binary>>), do: ".png"
  defp image_extension(<<0xff, 0xD8, _::binary>>), do: ".jpg"
  defp image_extension(<<0x47, 0x49, 0x46, 0x38, 0x39, 0x61, _::binary>>), do: ".gif"
  defp image_extension(<<0x25, 0x50, 0x44, 0x46, 0x2d, 0x31, 0x2e, _::binary>>), do: ".pdf"

  def prepare_image(base64) do

    #    1 get bindary of base64
    #    2 get original size of image
    #    3 if file size over 2mb do:
    #     3.1 get file name
    #     3.2 save file in server
    #     3.3 open saved file set quality, resize and save
    #     3.4 read saved file
    #     3.5 delete file
    #     3.6 return binary and filename
    #    4 directly return binary and filename

    decoded_value = Base.decode64!(base64)
    decode_size = byte_size(decoded_value)
    quality = cond do
      decode_size < 4000000 -> "80"
      decode_size > 4000000 -> "80"
    end
    filename = decoded_value
               |> image_extension()
               |> unique_filename()
    if decode_size > 2000000 do
      if File.exists?("tmp_uploads/") do
        :ok
      else
        File.mkdir("tmp_uploads/")
      end
      _url = File.write!("tmp_uploads/#{filename}", Base.decode64!(base64))
      _new = open("tmp_uploads/#{filename}")
             |> quality(quality)
             |> resize_to_limit("2000x2000")
             |> save([path: "tmp_uploads/#{filename}"])

      compressed_file = File.read!("tmp_uploads/#{filename}")
      File.rm("tmp_uploads/#{filename}")
      {filename, compressed_file}
    else
      {filename, decoded_value}
    end
  end
end
