defmodule BlockScoutWeb.AddressTokenController do
  use BlockScoutWeb, :controller

  import BlockScoutWeb.Chain,
    only: [next_page_params: 4, paging_options: 1, split_list_by_page: 1, paging_params_with_fiat_value: 1]

  import BlockScoutWeb.Account.AuthController, only: [current_user: 1]
  import BlockScoutWeb.Models.GetAddressTags, only: [get_address_tags: 2]

  alias BlockScoutWeb.{AccessHelper, AddressTokenView, Controller}
  alias Explorer.{Chain, Market}
  alias Explorer.Chain.Address
  alias Indexer.Fetcher.OnDemand.CoinBalance, as: CoinBalanceOnDemand
  alias Phoenix.View

  def index(conn, %{"address_id" => address_hash_string, "type" => "JSON"} = params) do
    with {:ok, address_hash} <- Chain.string_to_address_hash(address_hash_string),
         {:ok, address} <- Chain.hash_to_address(address_hash, []),
         {:ok, false} <- AccessHelper.restricted_access?(address_hash_string, params) do
      token_balances_plus_one =
        address_hash
        |> Chain.fetch_paginated_last_token_balances(paging_options(params))

      {tokens, next_page} = split_list_by_page(token_balances_plus_one)

      next_page_path =
        case next_page_params(next_page, tokens, params, &paging_params_with_fiat_value/1) do
          nil ->
            nil

          next_page_params ->
            address_token_path(conn, :index, address, Map.delete(next_page_params, "type"))
        end

      items =
        tokens
        |> Enum.map(fn token_balance ->
          View.render_to_string(
            AddressTokenView,
            "_tokens.html",
            token_balance: token_balance,
            token: token_balance.token,
            address: address,
            conn: conn
          )
        end)

      json(
        conn,
        %{
          items: items,
          next_page_path: next_page_path
        }
      )
    else
      {:restricted_access, _} ->
        not_found(conn)

      :error ->
        unprocessable_entity(conn)

      {:error, :not_found} ->
        not_found(conn)
    end
  end

  def index(conn, %{"address_id" => address_hash_string} = params) do
    ip = AccessHelper.conn_to_ip_string(conn)

    with {:ok, address_hash} <- Chain.string_to_address_hash(address_hash_string),
         {:ok, address} <- Chain.hash_to_address(address_hash),
         {:ok, false} <- AccessHelper.restricted_access?(address_hash_string, params) do
      render(
        conn,
        "index.html",
        address: address,
        current_path: Controller.current_full_path(conn),
        coin_balance_status: CoinBalanceOnDemand.trigger_fetch(ip, address),
        exchange_rate: Market.get_coin_exchange_rate(),
        counters_path: address_path(conn, :address_counters, %{"id" => Address.checksum(address_hash)}),
        tags: get_address_tags(address_hash, current_user(conn))
      )
    else
      {:restricted_access, _} ->
        not_found(conn)

      :error ->
        unprocessable_entity(conn)

      {:error, :not_found} ->
        not_found(conn)
    end
  end
end
