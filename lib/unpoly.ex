defmodule Unpoly do
  @moduledoc """
  A Plug adapter and helpers for Unpoly, the unobtrusive JavaScript framework.

  ## Options
    * `:cookie_name` - the cookie name where the request method is echoed to. Defaults to
    `"_up_method"`.
    * `:cookie_opts` - additional options to pass to method cookie.
    See `Plug.Conn.put_resp_cookie/4` for all available options.
  """

  @doc """
  Alias for `Unpoly.unpoly?/1`
  """
  @spec up?(Plug.Conn.t()) :: boolean()
  def up?(conn), do: unpoly?(conn)

  @doc """
  Returns whether the current request is a [page fragment update](https://unpoly.com/up.replace)
  triggered by an Unpoly frontend.

  This will eventually just check for the `X-Up-Version header`.
  Just in case a user still has an older version of Unpoly running on the frontend,
  we also check for the X-Up-Target header.
  """
  @spec unpoly?(Plug.Conn.t()) :: boolean()
  def unpoly?(conn), do: version(conn) !== nil || target(conn) !== nil

  @doc """
  Returns the current Unpoly version.

  The version is guaranteed to be set for all Unpoly requests.
  """
  @spec version(Plug.Conn.t()) :: String.t() | nil
  def version(conn), do: get_req_header(conn, "x-up-version")

  @doc """
  Returns the mode of the targeted layer.

  Server-side code is free to render different HTML for different modes. 
  For example, you might prefer to not render a site navigation for overlays.
  """
  @spec mode(Plug.Conn.t()) :: String.t() | nil
  def mode(conn), do: get_req_header(conn, "x-up-mode")

  @doc """
  Returns the mode of the layer targeted for a failed fragment update. 

  A fragment update is considered failed if the server responds with 
  a status code other than 2xx, but still renders HTML.

  Server-side code is free to render different HTML for different modes. 
  For example, you might prefer to not render a site navigation for overlays.
  """
  @spec fail_mode(Plug.Conn.t()) :: String.t() | nil
  def fail_mode(conn), do: get_req_header(conn, "x-up-fail-mode")

  @doc """
  Returns the CSS selector for a fragment that Unpoly will update in
  case of a successful response (200 status code).

  The Unpoly frontend will expect an HTML response containing an element
  that matches this selector.

  Server-side code is free to optimize its successful response by only returning HTML
  that matches this selector.
  """
  @spec target(Plug.Conn.t()) :: String.t() | nil
  def target(conn), do: get_req_header(conn, "x-up-target")

  @doc """
  Returns the CSS selector for a fragment that Unpoly will update in
  case of an failed response. Server errors or validation failures are
  all examples for a failed response (non-200 status code).

  The Unpoly frontend will expect an HTML response containing an element
  that matches this selector.

  Server-side code is free to optimize its response by only returning HTML
  that matches this selector.
  """
  @spec fail_target(Plug.Conn.t()) :: String.t() | nil
  def fail_target(conn), do: get_req_header(conn, "x-up-fail-target")

  @doc """
  Returns the context of the targeted layer as a map.

  The context is sent by Unpoly in the X-Up-Context request header.
  It contains data about the layer's state (e.g., game state, wizard step, etc.).

  Returns an empty map if no context is present.

  ## Examples

      context(conn)
      # => %{"lives" => 3, "level" => 2}
  """
  @spec context(Plug.Conn.t()) :: map()
  def context(conn) do
    case get_req_header(conn, "x-up-context") do
      nil -> %{}
      json -> Phoenix.json_library().decode!(json)
    end
  end

  @doc """
  Returns whether the given CSS selector is targeted by the current fragment
  update in case of a successful response (200 status code).

  Note that the matching logic is very simplistic and does not actually know
  how your page layout is structured. It will return `true` if
  the tested selector and the requested CSS selector matches exactly, or if the
  requested selector is `body` or `html`.

  Always returns `true` if the current request is not an Unpoly fragment update.
  """
  @spec target?(Plug.Conn.t(), String.t()) :: boolean()
  def target?(conn, tested_target), do: query_target(conn, target(conn), tested_target)

  @doc """
  Returns whether the given CSS selector is targeted by the current fragment
  update in case of a failed response (non-200 status code).

  Note that the matching logic is very simplistic and does not actually know
  how your page layout is structured. It will return `true` if
  the tested selector and the requested CSS selector matches exactly, or if the
  requested selector is `body` or `html`.

  Always returns `true` if the current request is not an Unpoly fragment update.
  """
  @spec fail_target?(Plug.Conn.t(), String.t()) :: boolean()
  def fail_target?(conn, tested_target), do: query_target(conn, fail_target(conn), tested_target)

  @doc """
  Returns whether the given CSS selector is targeted by the current fragment
  update for either a success or a failed response.

  Note that the matching logic is very simplistic and does not actually know
  how your page layout is structured. It will return `true` if
  the tested selector and the requested CSS selector matches exactly, or if the
  requested selector is `body` or `html`.

  Always returns `true` if the current request is not an Unpoly fragment update.
  """
  @spec any_target?(Plug.Conn.t(), String.t()) :: boolean()
  def any_target?(conn, tested_target),
    do: target?(conn, tested_target) || fail_target?(conn, tested_target)

  @doc """
  Returns whether the current form submission should be
  [validated](https://unpoly.com/input-up-validate) (and not be saved to the database).
  """
  @spec validate?(Plug.Conn.t()) :: boolean()
  def validate?(conn), do: validate_name(conn) !== nil

  @doc """
  If the current form submission is a [validation](https://unpoly.com/input-up-validate),
  this returns the name attribute of the form field that has triggered
  the validation.
  """
  @spec validate_name(Plug.Conn.t()) :: String.t() | nil
  def validate_name(conn), do: get_req_header(conn, "x-up-validate")

  @doc """
  Returns the timestamp of an existing fragment that is being reloaded.

  The timestamp must be explicitely set by the user as an [up-time] attribute on the fragment. 
  It should indicate the time when the fragment's underlying data was last changed.
  """
  @spec reload_from_time(Plug.Conn.t()) :: String.t() | nil
  def reload_from_time(conn) do
    with timestamp when is_binary(timestamp) <- get_req_header(conn, "x-up-reload-from-time"),
         {timestamp, ""} <- Integer.parse(timestamp),
         {:ok, datetime} <- DateTime.from_unix(timestamp) do
      datetime
    else
      _ -> nil
    end
  end

  @doc """
  Returns the timestamp of an existing fragment that is being reloaded.

  The timestamp must be explicitely set by the user as an [up-time] attribute on the fragment. 
  It should indicate the time when the fragment's underlying data was last changed.
  """
  @spec reload?(Plug.Conn.t()) :: boolean()
  def reload?(conn), do: reload_from_time(conn) !== nil

  @doc """
  Forces Unpoly to use the given string as the document title when processing
  this response.

  This is useful when you skip rendering the `<head>` in an Unpoly request.
  """
  @spec put_title(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  def put_title(conn, new_title), do: Plug.Conn.put_resp_header(conn, "x-up-title", new_title)

  @doc """
  Expires cache entries matching the given URL pattern.

  Expired cache entries will be revalidated when accessed.
  Use "*" to expire all cache entries.
  Use "false" to prevent automatic cache expiration after non-GET requests.

  ## Examples

      Unpoly.expire_cache(conn, "/notes/*")
      Unpoly.expire_cache(conn, "*")
      Unpoly.expire_cache(conn, "false")
  """
  @spec expire_cache(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  def expire_cache(conn, pattern) do
    put_resp_expire_cache_header(conn, pattern)
  end

  @doc """
  Evicts (removes) cache entries matching the given URL pattern.

  Evicted cache entries are completely removed from the cache.
  Use "*" to evict all cache entries.

  ## Examples

      Unpoly.evict_cache(conn, "/notes/*")
      Unpoly.evict_cache(conn, "*")
  """
  @spec evict_cache(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  def evict_cache(conn, pattern) do
    put_resp_evict_cache_header(conn, pattern)
  end

  @doc """
  Prevents automatic cache expiration after this non-GET request.

  By default, Unpoly expires the entire cache after non-GET requests.
  This helper prevents that behavior.

  ## Examples

      Unpoly.keep_cache(conn)
  """
  @spec keep_cache(Plug.Conn.t()) :: Plug.Conn.t()
  def keep_cache(conn) do
    put_resp_expire_cache_header(conn, "false")
  end

  # Plug

  def init(opts \\ []) do
    cookie_name = Keyword.get(opts, :cookie_name, "_up_method")
    cookie_opts = Keyword.get(opts, :cookie_opts, http_only: false)
    {cookie_name, cookie_opts}
  end

  def call(conn, {cookie_name, cookie_opts}) do
    conn
    |> Plug.Conn.fetch_cookies()
    |> echo_request_headers()
    |> append_method_cookie(cookie_name, cookie_opts)
  end

  @doc """
  Sets the value of the "X-Up-Accept-Layer" response header.
  """
  @spec put_resp_accept_layer_header(Plug.Conn.t(), term) :: Plug.Conn.t()
  def put_resp_accept_layer_header(conn, value) when is_binary(value) do
    Plug.Conn.put_resp_header(conn, "x-up-accept-layer", value)
  end

  def put_resp_accept_layer_header(conn, value) do
    value = Phoenix.json_library().encode_to_iodata!(value)
    put_resp_accept_layer_header(conn, to_string(value))
  end

  @doc """
  Sets the value of the "X-Up-Dismiss-Layer" response header.
  """
  @spec put_resp_dismiss_layer_header(Plug.Conn.t(), term) :: Plug.Conn.t()
  def put_resp_dismiss_layer_header(conn, value) when is_binary(value) do
    Plug.Conn.put_resp_header(conn, "x-up-dismiss-layer", value)
  end

  def put_resp_dismiss_layer_header(conn, value) do
    value = Phoenix.json_library().encode_to_iodata!(value)
    put_resp_dismiss_layer_header(conn, to_string(value))
  end

  @doc """
  Sets the value of the "X-Up-Events" response header.
  """
  @spec put_resp_events_header(Plug.Conn.t(), term) :: Plug.Conn.t()
  def put_resp_events_header(conn, value) when is_binary(value) do
    Plug.Conn.put_resp_header(conn, "x-up-events", value)
  end

  def put_resp_events_header(conn, value) do
    value = Phoenix.json_library().encode_to_iodata!(value)
    put_resp_events_header(conn, to_string(value))
  end

  @doc """
  Sets the value of the "X-Up-Location" response header.
  """
  @spec put_resp_location_header(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  def put_resp_location_header(conn, value) do
    Plug.Conn.put_resp_header(conn, "x-up-location", value)
  end

  @doc """
  Sets the value of the "X-Up-Method" response header.
  """
  @spec put_resp_method_header(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  def put_resp_method_header(conn, value) do
    Plug.Conn.put_resp_header(conn, "x-up-method", value)
  end

  @doc """
  Sets the value of the "X-Up-Target" response header.
  """
  @spec put_resp_target_header(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  def put_resp_target_header(conn, value) do
    Plug.Conn.put_resp_header(conn, "x-up-target", value)
  end

  @doc """
  Sets the value of the "X-Up-Evict-Cache" response header.

  The client will evict cached responses that match the given URL pattern.
  Use "*" to evict all cached entries.

  ## Examples

      Unpoly.put_resp_evict_cache_header(conn, "/notes/*")
      Unpoly.put_resp_evict_cache_header(conn, "*")
  """
  @spec put_resp_evict_cache_header(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  def put_resp_evict_cache_header(conn, value) do
    Plug.Conn.put_resp_header(conn, "x-up-evict-cache", value)
  end

  @doc """
  Sets the value of the "X-Up-Expire-Cache" response header.

  The client will expire cached responses that match the given URL pattern,
  forcing revalidation on next access.
  Use "*" to expire all cached entries.
  Use "false" to prevent automatic cache expiration after non-GET requests.

  ## Examples

      Unpoly.put_resp_expire_cache_header(conn, "/notes/*")
      Unpoly.put_resp_expire_cache_header(conn, "*")
      Unpoly.put_resp_expire_cache_header(conn, "false")
  """
  @spec put_resp_expire_cache_header(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  def put_resp_expire_cache_header(conn, value) do
    Plug.Conn.put_resp_header(conn, "x-up-expire-cache", value)
  end

  defp echo_request_headers(conn) do
    conn
    |> put_resp_location_header(Phoenix.Controller.current_url(conn))
    |> put_resp_method_header(conn.method)
  end

  defp append_method_cookie(conn, cookie_name, cookie_opts) do
    cond do
      conn.method != "GET" && !up?(conn) ->
        Plug.Conn.put_resp_cookie(conn, cookie_name, conn.method, cookie_opts)

      Map.has_key?(conn.req_cookies, "_up_method") ->
        Plug.Conn.delete_resp_cookie(conn, cookie_name, cookie_opts)

      true ->
        conn
    end
  end

  ## Helpers

  defp get_req_header(conn, key),
    do: Plug.Conn.get_req_header(conn, key) |> List.first()

  defp query_target(conn, actual_target, tested_target) do
    if up?(conn) do
      cond do
        actual_target == tested_target -> true
        actual_target == "html" -> true
        actual_target == "body" && tested_target not in ["head", "title", "meta"] -> true
        true -> false
      end
    else
      true
    end
  end
end
