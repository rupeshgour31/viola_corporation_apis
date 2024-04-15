defmodule ViolacorpWeb.Admin.Settings.BlockUnblockController do
  use Phoenix.Controller

  alias Violacorp.Settings.BlockUnblockSetting
  @moduledoc false

  @doc"  List of Block Unblock users"

    def blockUser(conn, params) do
      data = BlockUnblockSetting.block_user(params)
      json conn, %{status_code: "200", total_pages: data.total_pages, total_entries: data.total_entries, page_size: data.page_size, page_number: data.page_number, data: data.entries}
  end
end
