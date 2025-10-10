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
  @doc since: "2.0.0"
  @spec mode(Plug.Conn.t()) :: String.t() | nil
  def mode(conn), do: get_req_header(conn, "x-up-mode")

  @doc """
  Returns the mode of the layer targeted for a failed fragment update.

  A fragment update is considered failed if the server responds with
  a status code other than 2xx, but still renders HTML.

  Server-side code is free to render different HTML for different modes.
  For example, you might prefer to not render a site navigation for overlays.
  """
  @doc since: "2.0.0"
  @spec fail_mode(Plug.Conn.t()) :: String.t() | nil
  def fail_mode(conn), do: get_req_header(conn, "x-up-fail-mode")

  @doc """
  Returns the mode of the layer from which the fragment update originated.

  This is an experimental feature that can be used to determine the context
  from which a request was made.

  Returns `nil` if the header is not present.
  """
  @doc since: "2.0.0"
  @spec origin_mode(Plug.Conn.t()) :: String.t() | nil
  def origin_mode(conn), do: get_req_header(conn, "x-up-origin-mode")

  @doc """
  Returns the context of the layer targeted for a failed fragment update.

  This is an experimental feature for handling context in failed updates.

  Returns an empty map if no context is present.
  """
  @doc since: "2.0.0"
  @spec fail_context(Plug.Conn.t()) :: map()
  def fail_context(conn) do
    case get_req_header(conn, "x-up-fail-context") do
      nil -> %{}
      json -> Phoenix.json_library().decode!(json)
    end
  end

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
  @doc since: "2.0.0"
  @spec context(Plug.Conn.t()) :: map()
  def context(conn) do
    case get_req_header(conn, "x-up-context") do
      nil -> %{}
      json -> Phoenix.json_library().decode!(json)
    end
  end

  @doc """
  Returns whether the current layer has context.

  Returns `true` if the X-Up-Context request header is present and contains
  context data, `false` otherwise.

  ## Examples

      context?(conn)
      # => true (if context is present)
  """
  @doc since: "2.0.0"
  @spec context?(Plug.Conn.t()) :: boolean()
  def context?(conn) do
    get_req_header(conn, "x-up-context") != nil
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
  Returns whether the current layer is the root layer.

  The root layer is the default layer that contains the initial page content.
  It is identified by the mode "root".

  Returns `true` if the current layer is the root layer, or if the request
  is not an Unpoly request (full page load).

  ## Examples

      root?(conn)
      # => true
  """
  @doc since: "2.0.0"
  @spec root?(Plug.Conn.t()) :: boolean()
  def root?(conn) do
    case mode(conn) do
      nil -> true
      "root" -> true
      _ -> false
    end
  end

  @doc """
  Returns whether the current layer is an overlay.

  Overlays are layers that are stacked on top of the root layer,
  such as modal dialogs, popups, drawers, or covers.

  Returns `false` if the current layer is the root layer, or if the request
  is not an Unpoly request (full page load).

  ## Examples

      overlay?(conn)
      # => true (for modes like "modal", "popup", "drawer", "cover")
  """
  @doc since: "2.0.0"
  @spec overlay?(Plug.Conn.t()) :: boolean()
  def overlay?(conn) do
    case mode(conn) do
      nil -> false
      "root" -> false
      _ -> true
    end
  end

  @doc """
  If the current form submission is a [validation](https://unpoly.com/input-up-validate),
  this returns the name attribute of the form field that has triggered
  the validation.
  """
  @spec validate_name(Plug.Conn.t()) :: String.t() | nil
  def validate_name(conn), do: get_req_header(conn, "x-up-validate")

  @doc """
  Returns the timestamp from the `If-Modified-Since` request header.

  This is part of Unpoly's cache revalidation system. When a cached fragment
  has a `Last-Modified` timestamp, Unpoly will send it back in the
  `If-Modified-Since` header when revalidating the cache.

  If the fragment hasn't changed since this timestamp, the server can return
  a 304 Not Modified response using `not_modified/1`.

  Returns `nil` if the header is not present or cannot be parsed.

  ## Examples

      if_modified_since(conn)
      # => ~U[2024-01-15 10:30:00Z]

  """
  @doc since: "3.0.0"
  @spec if_modified_since(Plug.Conn.t()) :: DateTime.t() | nil
  def if_modified_since(conn) do
    case get_req_header(conn, "if-modified-since") do
      nil -> nil
      date_string -> parse_http_date(date_string)
    end
  end

  @doc """
  Returns the ETag from the `If-None-Match` request header.

  This is part of Unpoly's cache revalidation system. When a cached fragment
  has an ETag, Unpoly will send it back in the `If-None-Match` header when
  revalidating the cache.

  If the current ETag matches this value, the server can return a 304 Not
  Modified response using `not_modified/1`.

  Returns `nil` if the header is not present.

  ## Examples

      if_none_match(conn)
      # => "\"abc123\""

  """
  @doc since: "3.0.0"
  @spec if_none_match(Plug.Conn.t()) :: String.t() | nil
  def if_none_match(conn), do: get_req_header(conn, "if-none-match")

  @doc """
  Returns the timestamp of an existing fragment that is being reloaded.

  The timestamp must be explicitely set by the user as an [up-time] attribute on the fragment.
  It should indicate the time when the fragment's underlying data was last changed.

  ## Deprecation Notice

  This header (X-Up-Reload-From-Time) is deprecated in Unpoly 3.0.
  Instead, use standard HTTP conditional request headers:
  - Use `put_last_modified/2` to set the `Last-Modified` response header
  - Use `if_modified_since/1` to check the `If-Modified-Since` request header
  - Use `not_modified/1` to return a 304 Not Modified response

  This function is kept for backward compatibility with Unpoly 2.x clients.
  """
  @doc since: "2.0.0"
  @doc deprecated: "Use standard Last-Modified/If-Modified-Since headers instead"
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
  Returns whether the current request is reloading an existing fragment.

  ## Deprecation Notice

  This function relies on the deprecated X-Up-Reload-From-Time header.
  In Unpoly 3.0, use standard HTTP conditional request helpers instead:
  - Check `if_modified_since/1` for conditional requests
  - Use `cache_fresh?/2` to determine if cached content is still valid

  This function is kept for backward compatibility with Unpoly 2.x clients.
  """
  @doc since: "2.0.0"
  @doc deprecated: "Use if_modified_since/1 or cache_fresh?/2 instead"
  @spec reload?(Plug.Conn.t()) :: boolean()
  def reload?(conn), do: reload_from_time(conn) !== nil

  @doc """
  Forces Unpoly to use the given string as the document title when processing
  this response.

  This is useful when you skip rendering the `<head>` in an Unpoly request.

  Note: In Unpoly 3.0+, the title value is JSON-encoded as required by the protocol.
  """
  @spec put_title(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  def put_title(conn, new_title) do
    encoded_title =
      new_title
      |> Phoenix.json_library().encode_to_iodata!()
      |> to_string()

    Plug.Conn.put_resp_header(conn, "x-up-title", encoded_title)
  end

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
  @doc since: "2.0.0"
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
  @doc since: "2.0.0"
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
  @doc since: "2.0.0"
  @spec keep_cache(Plug.Conn.t()) :: Plug.Conn.t()
  def keep_cache(conn) do
    put_resp_expire_cache_header(conn, "false")
  end

  @doc """
  Updates the layer context in the response.

  The context will be merged with the existing layer context on the client.
  To remove a context key, set its value to nil.

  ## Examples

      Unpoly.put_context(conn, %{lives: 2})
      Unpoly.put_context(conn, %{removed_key: nil})
  """
  @doc since: "2.0.0"
  @spec put_context(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def put_context(conn, context) when is_map(context) do
    put_resp_context_header(conn, context)
  end

  @doc """
  Forces the response to open in a new overlay layer with the given options.

  This is useful for server-side code that wants to force a response to open
  in an overlay, even when the request was not made from an overlay.

  ## Examples

      Unpoly.open_layer(conn, %{mode: "modal"})
      Unpoly.open_layer(conn, %{mode: "drawer", size: "large"})
  """
  @doc since: "2.0.0"
  @spec open_layer(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def open_layer(conn, options) when is_map(options) do
    put_resp_open_layer_header(conn, options)
  end

  @doc """
  Emits one or more JavaScript events on the frontend.

  Events are sent via the X-Up-Events response header and will be
  triggered on the document when the response is received.

  You can pass either a single event type (string) or a map of events
  with their properties.

  ## Examples

      # Emit a simple event without properties
      Unpoly.emit_events(conn, "user:created")

      # Emit an event with properties
      Unpoly.emit_events(conn, %{"user:created" => %{id: 123, name: "Alice"}})

      # Emit multiple events
      Unpoly.emit_events(conn, %{
        "user:created" => %{id: 123},
        "notification:show" => %{message: "User created"}
      })
  """
  @doc since: "2.0.0"
  @spec emit_events(Plug.Conn.t(), String.t() | map()) :: Plug.Conn.t()
  def emit_events(conn, event_type) when is_binary(event_type) do
    emit_events(conn, %{event_type => %{}})
  end

  def emit_events(conn, events) when is_map(events) do
    put_resp_events_header(conn, events)
  end

  @doc """
  Accepts the current overlay layer and closes it, optionally passing a value to the parent layer.

  This is a high-level convenience helper that combines setting the X-Up-Accept-Layer
  header and preventing rendering of HTML by setting X-Up-Target to ":none".

  When called without a value (or with `nil`), it simply accepts the overlay.
  When called with a value (string or map), that value is passed to the parent layer.

  ## Examples

      # Accept overlay without a value
      Unpoly.accept_layer(conn)

      # Accept overlay with a string value
      Unpoly.accept_layer(conn, "User was created")

      # Accept overlay with a structured value
      Unpoly.accept_layer(conn, %{id: 123, name: "Alice"})

  """
  @doc since: "3.0.0"
  @spec accept_layer(Plug.Conn.t(), term()) :: Plug.Conn.t()
  def accept_layer(conn, value \\ nil) do
    conn
    |> put_resp_accept_layer_header(value)
    |> put_resp_target_header(":none")
  end

  @doc """
  Dismisses the current overlay layer and closes it, optionally passing a value to the parent layer.

  This is a high-level convenience helper that combines setting the X-Up-Dismiss-Layer
  header and preventing rendering of HTML by setting X-Up-Target to ":none".

  When called without a value (or with `nil`), it simply dismisses the overlay.
  When called with a value (string or map), that value is passed to the parent layer.

  ## Examples

      # Dismiss overlay without a value
      Unpoly.dismiss_layer(conn)

      # Dismiss overlay with a string value
      Unpoly.dismiss_layer(conn, "Operation cancelled")

      # Dismiss overlay with a structured value
      Unpoly.dismiss_layer(conn, %{reason: "user_cancelled"})

  """
  @doc since: "3.0.0"
  @spec dismiss_layer(Plug.Conn.t(), term()) :: Plug.Conn.t()
  def dismiss_layer(conn, value \\ nil) do
    conn
    |> put_resp_dismiss_layer_header(value)
    |> put_resp_target_header(":none")
  end

  @doc """
  Sets the `ETag` response header for cache validation.

  ETags are identifiers for specific versions of a resource. When a client
  caches a fragment with an ETag, it will send it back in the `If-None-Match`
  header when revalidating the cache.

  If the ETag matches, the server can return a 304 Not Modified response
  using `not_modified/1`.

  ## Examples

      Unpoly.put_etag(conn, "\"abc123\"")
      Unpoly.put_etag(conn, "\"v2-" <> calculate_hash(content) <> "\"")

  """
  @doc since: "3.0.0"
  @spec put_etag(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  def put_etag(conn, etag) do
    Plug.Conn.put_resp_header(conn, "etag", etag)
  end

  @doc """
  Sets the `Last-Modified` response header for cache validation.

  This header indicates when the resource was last changed. When a client
  caches a fragment with a Last-Modified timestamp, it will send it back in
  the `If-Modified-Since` header when revalidating the cache.

  If the resource hasn't changed since that time, the server can return a
  304 Not Modified response using `not_modified/1`.

  ## Examples

      Unpoly.put_last_modified(conn, ~U[2024-01-15 10:30:00Z])
      Unpoly.put_last_modified(conn, user.updated_at)

  """
  @doc since: "3.0.0"
  @spec put_last_modified(Plug.Conn.t(), DateTime.t()) :: Plug.Conn.t()
  def put_last_modified(conn, datetime) do
    http_date = format_http_date(datetime)
    Plug.Conn.put_resp_header(conn, "last-modified", http_date)
  end

  @doc """
  Sets the `Vary` response header for cache partitioning.

  The Vary header tells the cache which request headers influenced the response.
  This is critical for proper cache partitioning in Unpoly 3.0.

  You can pass either a single header name (string) or a list of header names.
  If called multiple times, headers will be accumulated.

  ## Examples

      # Single header
      Unpoly.put_vary(conn, "X-Up-Target")

      # Multiple headers
      Unpoly.put_vary(conn, ["X-Up-Target", "X-Up-Mode"])

      # Common Unpoly headers
      Unpoly.put_vary(conn, ["X-Up-Target", "X-Up-Mode", "X-Up-Context"])

  """
  @doc since: "3.0.0"
  @spec put_vary(Plug.Conn.t(), String.t() | list(String.t())) :: Plug.Conn.t()
  def put_vary(conn, header) when is_binary(header) do
    put_vary(conn, [header])
  end

  def put_vary(conn, headers) when is_list(headers) do
    # Get existing Vary header if present
    existing = Plug.Conn.get_resp_header(conn, "vary")

    # Combine with new headers
    all_headers =
      case existing do
        [] -> headers
        [existing_value] -> String.split(existing_value, ", ") ++ headers
      end

    # Remove duplicates and join
    vary_value =
      all_headers
      |> Enum.uniq()
      |> Enum.join(", ")

    Plug.Conn.put_resp_header(conn, "vary", vary_value)
  end

  @doc """
  Returns a 304 Not Modified response for cache revalidation.

  This helper sets the response status to 304, sets X-Up-Target to ":none"
  (telling Unpoly not to expect any HTML), and halts the connection.

  Use this after checking conditional request headers like `If-None-Match`
  or `If-Modified-Since` when the cached content is still valid.

  ## Examples

      def show(conn, %{"id" => id}) do
        post = Posts.get_post!(id)
        etag = "\"post-\#{post.id}-\#{post.updated_at}\""

        if if_none_match(conn) == etag do
          not_modified(conn)
        else
          conn
          |> put_etag(etag)
          |> render("show.html", post: post)
        end
      end

  """
  @doc since: "3.0.0"
  @spec not_modified(Plug.Conn.t()) :: Plug.Conn.t()
  def not_modified(conn) do
    conn
    |> Plug.Conn.put_status(304)
    |> put_resp_target_header(":none")
    |> Plug.Conn.halt()
  end

  @doc """
  Checks if the cached content is still fresh based on conditional request headers.

  This helper simplifies cache revalidation logic by checking both ETag and
  Last-Modified conditions in one call.

  Returns `true` if either:
  - The `If-None-Match` header matches the provided `:etag`
  - The `If-Modified-Since` header is >= the provided `:last_modified`

  ## Examples

      def show(conn, %{"id" => id}) do
        post = Posts.get_post!(id)

        if cache_fresh?(conn, last_modified: post.updated_at) do
          not_modified(conn)
        else
          conn
          |> put_last_modified(post.updated_at)
          |> render("show.html", post: post)
        end
      end

      # With ETag
      etag = calculate_etag(content)
      if cache_fresh?(conn, etag: etag) do
        not_modified(conn)
      else
        conn
        |> put_etag(etag)
        |> render(content)
      end

  """
  @doc since: "3.0.0"
  @spec cache_fresh?(Plug.Conn.t(), keyword()) :: boolean()
  def cache_fresh?(conn, opts) do
    etag_matches =
      case Keyword.get(opts, :etag) do
        nil -> false
        etag -> if_none_match(conn) == etag
      end

    last_modified_fresh =
      case Keyword.get(opts, :last_modified) do
        nil ->
          false

        last_modified ->
          case if_modified_since(conn) do
            nil -> false
            since -> DateTime.compare(last_modified, since) != :gt
          end
      end

    etag_matches || last_modified_fresh
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
    |> append_method_cookie(cookie_name, cookie_opts)
  end

  @doc """
  Sets the value of the "X-Up-Accept-Layer" response header.
  """
  @doc since: "2.0.0"
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
  @doc since: "2.0.0"
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
  @doc since: "2.0.0"
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
  @doc since: "2.0.0"
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
  @doc since: "2.0.0"
  @spec put_resp_expire_cache_header(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  def put_resp_expire_cache_header(conn, value) do
    Plug.Conn.put_resp_header(conn, "x-up-expire-cache", value)
  end

  @doc """
  Sets the value of the "X-Up-Context" response header.

  The client will update the layer context with the given value.
  Use this to modify the layer's context from the server side.

  ## Examples

      Unpoly.put_resp_context_header(conn, %{lives: 2})
  """
  @doc since: "2.0.0"
  @spec put_resp_context_header(Plug.Conn.t(), term) :: Plug.Conn.t()
  def put_resp_context_header(conn, value) when is_binary(value) do
    Plug.Conn.put_resp_header(conn, "x-up-context", value)
  end

  def put_resp_context_header(conn, value) do
    value = Phoenix.json_library().encode_to_iodata!(value)
    put_resp_context_header(conn, to_string(value))
  end

  @doc """
  Sets the value of the "X-Up-Open-Layer" response header.

  The client will open a new overlay layer with the given options.
  This is useful for forcing a response to open in an overlay.

  ## Examples

      Unpoly.put_resp_open_layer_header(conn, %{mode: "modal", size: "large"})
  """
  @doc since: "2.0.0"
  @spec put_resp_open_layer_header(Plug.Conn.t(), term) :: Plug.Conn.t()
  def put_resp_open_layer_header(conn, value) when is_binary(value) do
    Plug.Conn.put_resp_header(conn, "x-up-open-layer", value)
  end

  def put_resp_open_layer_header(conn, value) do
    value = Phoenix.json_library().encode_to_iodata!(value)
    put_resp_open_layer_header(conn, to_string(value))
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

  # Parse HTTP date format (RFC 7231)
  # Examples: "Mon, 15 Jan 2024 10:30:00 GMT"
  defp parse_http_date(date_string) do
    # HTTP dates are in IMF-fixdate format: "Day, DD Mon YYYY HH:MM:SS GMT"
    # We'll use a simple regex parser since Elixir doesn't have built-in HTTP date parsing
    case Regex.run(
           ~r/^[A-Za-z]{3}, (\d{2}) ([A-Za-z]{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT$/,
           date_string
         ) do
      [_, day, month_name, year, hour, minute, second] ->
        month = month_name_to_number(month_name)

        if month do
          {:ok, datetime} =
            DateTime.new(
              Date.new!(String.to_integer(year), month, String.to_integer(day)),
              Time.new!(
                String.to_integer(hour),
                String.to_integer(minute),
                String.to_integer(second)
              ),
              "Etc/UTC"
            )

          datetime
        else
          nil
        end

      _ ->
        nil
    end
  rescue
    _ -> nil
  end

  defp month_name_to_number("Jan"), do: 1
  defp month_name_to_number("Feb"), do: 2
  defp month_name_to_number("Mar"), do: 3
  defp month_name_to_number("Apr"), do: 4
  defp month_name_to_number("May"), do: 5
  defp month_name_to_number("Jun"), do: 6
  defp month_name_to_number("Jul"), do: 7
  defp month_name_to_number("Aug"), do: 8
  defp month_name_to_number("Sep"), do: 9
  defp month_name_to_number("Oct"), do: 10
  defp month_name_to_number("Nov"), do: 11
  defp month_name_to_number("Dec"), do: 12
  defp month_name_to_number(_), do: nil

  # Format DateTime as HTTP date (RFC 7231)
  # Example: "Mon, 15 Jan 2024 10:30:00 GMT"
  defp format_http_date(datetime) do
    datetime = DateTime.shift_zone!(datetime, "Etc/UTC")
    day_name = day_of_week_name(Date.day_of_week(datetime))
    month_name = number_to_month_name(datetime.month)

    "#{day_name}, #{String.pad_leading(Integer.to_string(datetime.day), 2, "0")} #{month_name} #{datetime.year} #{String.pad_leading(Integer.to_string(datetime.hour), 2, "0")}:#{String.pad_leading(Integer.to_string(datetime.minute), 2, "0")}:#{String.pad_leading(Integer.to_string(datetime.second), 2, "0")} GMT"
  end

  defp day_of_week_name(1), do: "Mon"
  defp day_of_week_name(2), do: "Tue"
  defp day_of_week_name(3), do: "Wed"
  defp day_of_week_name(4), do: "Thu"
  defp day_of_week_name(5), do: "Fri"
  defp day_of_week_name(6), do: "Sat"
  defp day_of_week_name(7), do: "Sun"

  defp number_to_month_name(1), do: "Jan"
  defp number_to_month_name(2), do: "Feb"
  defp number_to_month_name(3), do: "Mar"
  defp number_to_month_name(4), do: "Apr"
  defp number_to_month_name(5), do: "May"
  defp number_to_month_name(6), do: "Jun"
  defp number_to_month_name(7), do: "Jul"
  defp number_to_month_name(8), do: "Aug"
  defp number_to_month_name(9), do: "Sep"
  defp number_to_month_name(10), do: "Oct"
  defp number_to_month_name(11), do: "Nov"
  defp number_to_month_name(12), do: "Dec"
end
