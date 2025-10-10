defmodule UnpolyTest do
  use ExUnit.Case, async: true
  use Plug.Test

  describe "target/1" do
    test "returns selector from header" do
      target =
        conn(:get, "/foo")
        |> put_req_header("x-up-target", ".css.selector")
        |> Unpoly.target()

      assert ".css.selector" = target
    end

    test "returns nil when header not present" do
      target =
        conn(:get, "/foo")
        |> Unpoly.target()

      assert is_nil(target)
    end
  end

  describe "fail_target/1" do
    test "returns selector from header" do
      target =
        conn(:get, "/foo")
        |> put_req_header("x-up-fail-target", ".css.selector")
        |> Unpoly.fail_target()

      assert ".css.selector" = target
    end

    test "returns nil when header not present" do
      target =
        conn(:get, "/foo")
        |> Unpoly.fail_target()

      assert is_nil(target)
    end
  end

  describe "context/1" do
    test "returns context from header as map" do
      context =
        conn(:get, "/foo")
        |> put_req_header("x-up-context", "{\"lives\":3,\"level\":2}")
        |> Unpoly.context()

      assert %{"lives" => 3, "level" => 2} = context
    end

    test "returns empty map when header not present" do
      context =
        conn(:get, "/foo")
        |> Unpoly.context()

      assert %{} = context
    end

    test "handles nested context data" do
      context =
        conn(:get, "/foo")
        |> put_req_header("x-up-context", "{\"user\":{\"name\":\"Alice\",\"role\":\"admin\"}}")
        |> Unpoly.context()

      assert %{"user" => %{"name" => "Alice", "role" => "admin"}} = context
    end
  end

  describe "root?/1" do
    test "returns true when mode is root" do
      result =
        conn(:get, "/foo")
        |> put_req_header("x-up-mode", "root")
        |> Unpoly.root?()

      assert result == true
    end

    test "returns true when no mode header (full page load)" do
      result =
        conn(:get, "/foo")
        |> Unpoly.root?()

      assert result == true
    end

    test "returns false when mode is an overlay" do
      result =
        conn(:get, "/foo")
        |> put_req_header("x-up-mode", "modal")
        |> Unpoly.root?()

      assert result == false
    end
  end

  describe "overlay?/1" do
    test "returns true when mode is modal" do
      result =
        conn(:get, "/foo")
        |> put_req_header("x-up-mode", "modal")
        |> Unpoly.overlay?()

      assert result == true
    end

    test "returns true when mode is popup" do
      result =
        conn(:get, "/foo")
        |> put_req_header("x-up-mode", "popup")
        |> Unpoly.overlay?()

      assert result == true
    end

    test "returns true when mode is drawer" do
      result =
        conn(:get, "/foo")
        |> put_req_header("x-up-mode", "drawer")
        |> Unpoly.overlay?()

      assert result == true
    end

    test "returns false when mode is root" do
      result =
        conn(:get, "/foo")
        |> put_req_header("x-up-mode", "root")
        |> Unpoly.overlay?()

      assert result == false
    end

    test "returns false when no mode header (full page load)" do
      result =
        conn(:get, "/foo")
        |> Unpoly.overlay?()

      assert result == false
    end
  end

  describe "origin_mode/1" do
    test "returns mode from header" do
      mode =
        conn(:get, "/foo")
        |> put_req_header("x-up-origin-mode", "modal")
        |> Unpoly.origin_mode()

      assert "modal" = mode
    end

    test "returns nil when header not present" do
      mode =
        conn(:get, "/foo")
        |> Unpoly.origin_mode()

      assert is_nil(mode)
    end
  end

  describe "fail_context/1" do
    test "returns context from header as map" do
      context =
        conn(:get, "/foo")
        |> put_req_header("x-up-fail-context", "{\"error\":\"validation failed\"}")
        |> Unpoly.fail_context()

      assert %{"error" => "validation failed"} = context
    end

    test "returns empty map when header not present" do
      context =
        conn(:get, "/foo")
        |> Unpoly.fail_context()

      assert %{} = context
    end
  end

  describe "reload_from_time/1" do
    test "returns parsed timestamp from header" do
      timestamp =
        conn(:get, "/foo")
        |> put_req_header("x-up-reload-from-time", "1608730818")
        |> Unpoly.reload_from_time()

      assert ~U[2020-12-23 13:40:18Z] = timestamp
    end

    test "returns nil when timestamp is invalid" do
      timestamp =
        conn(:get, "/foo")
        |> put_req_header("x-up-reload-from-time", "foo")
        |> Unpoly.reload_from_time()

      assert is_nil(timestamp)
    end

    test "returns nil when header is missing" do
      timestamp =
        conn(:get, "/foo")
        |> Unpoly.reload_from_time()

      assert is_nil(timestamp)
    end
  end

  describe "call/2" do
    def url(), do: "https://www.example.com"

    test "mirrors request path and method in response headers" do
      conn =
        build_conn_for_path("/foo")
        |> Unpoly.call(Unpoly.init([]))

      assert ["https://www.example.com/foo"] = get_resp_header(conn, "x-up-location")
      assert ["GET"] = get_resp_header(conn, "x-up-method")
    end

    test "respects query params when mirroring request path" do
      conn =
        build_conn_for_path("/foo?bar=baz")
        |> Unpoly.call(Unpoly.init([]))

      assert ["https://www.example.com/foo?bar=baz"] = get_resp_header(conn, "x-up-location")
      assert ["GET"] = get_resp_header(conn, "x-up-method")
    end

    test "appends method cookie to non GET requests" do
      conn =
        build_conn_for_path("/foo", :post)
        |> Unpoly.call(Unpoly.init([]))

      assert %{"_up_method" => %{value: "POST", http_only: false}} = conn.resp_cookies
    end

    test "deletes method cookie from GET requests" do
      conn =
        build_conn_for_path("/foo")
        |> put_req_cookie("_up_method", "POST")
        |> Unpoly.call(Unpoly.init([]))

      assert %{"_up_method" => %{max_age: 0, http_only: false}} = conn.resp_cookies
    end
  end

  describe "put_resp_accept_layer_header/2" do
    test "sets response header" do
      conn =
        build_conn_for_path("/foo")
        |> Unpoly.put_resp_accept_layer_header("foo")

      assert ["foo"] = get_resp_header(conn, "x-up-accept-layer")

      conn = Unpoly.put_resp_accept_layer_header(conn, %{foo: "bar"})
      assert ["{\"foo\":\"bar\"}"] = get_resp_header(conn, "x-up-accept-layer")

      conn = Unpoly.put_resp_accept_layer_header(conn, nil)
      assert ["null"] = get_resp_header(conn, "x-up-accept-layer")
    end
  end

  describe "put_resp_dismiss_layer_header/2" do
    test "sets response header" do
      conn =
        build_conn_for_path("/foo")
        |> Unpoly.put_resp_dismiss_layer_header("foo")

      assert ["foo"] = get_resp_header(conn, "x-up-dismiss-layer")

      conn = Unpoly.put_resp_dismiss_layer_header(conn, %{foo: "bar"})
      assert ["{\"foo\":\"bar\"}"] = get_resp_header(conn, "x-up-dismiss-layer")

      conn = Unpoly.put_resp_dismiss_layer_header(conn, nil)
      assert ["null"] = get_resp_header(conn, "x-up-dismiss-layer")
    end
  end

  describe "put_resp_events_header/2" do
    test "sets response header" do
      conn =
        build_conn_for_path("/foo")
        |> Unpoly.put_resp_events_header("foo")

      assert ["foo"] = get_resp_header(conn, "x-up-events")

      conn = Unpoly.put_resp_events_header(conn, %{foo: "bar"})
      assert ["{\"foo\":\"bar\"}"] = get_resp_header(conn, "x-up-events")
    end
  end

  describe "put_resp_target_header/2" do
    test "sets response header" do
      conn =
        build_conn_for_path("/foo")
        |> Unpoly.put_resp_target_header("foo")

      assert ["foo"] = get_resp_header(conn, "x-up-target")
    end
  end

  describe "put_resp_evict_cache_header/2" do
    test "sets response header with URL pattern" do
      conn =
        build_conn_for_path("/foo")
        |> Unpoly.put_resp_evict_cache_header("/notes/*")

      assert ["/notes/*"] = get_resp_header(conn, "x-up-evict-cache")
    end

    test "sets response header to evict all cache" do
      conn =
        build_conn_for_path("/foo")
        |> Unpoly.put_resp_evict_cache_header("*")

      assert ["*"] = get_resp_header(conn, "x-up-evict-cache")
    end
  end

  describe "put_resp_expire_cache_header/2" do
    test "sets response header with URL pattern" do
      conn =
        build_conn_for_path("/foo")
        |> Unpoly.put_resp_expire_cache_header("/notes/*")

      assert ["/notes/*"] = get_resp_header(conn, "x-up-expire-cache")
    end

    test "sets response header to expire all cache" do
      conn =
        build_conn_for_path("/foo")
        |> Unpoly.put_resp_expire_cache_header("*")

      assert ["*"] = get_resp_header(conn, "x-up-expire-cache")
    end

    test "sets response header to false to prevent cache expiration" do
      conn =
        build_conn_for_path("/foo")
        |> Unpoly.put_resp_expire_cache_header("false")

      assert ["false"] = get_resp_header(conn, "x-up-expire-cache")
    end
  end

  describe "expire_cache/2" do
    test "expires cache for URL pattern" do
      conn =
        build_conn_for_path("/foo")
        |> Unpoly.expire_cache("/notes/*")

      assert ["/notes/*"] = get_resp_header(conn, "x-up-expire-cache")
    end

    test "expires all cache entries with wildcard" do
      conn =
        build_conn_for_path("/foo")
        |> Unpoly.expire_cache("*")

      assert ["*"] = get_resp_header(conn, "x-up-expire-cache")
    end
  end

  describe "evict_cache/2" do
    test "evicts cache for URL pattern" do
      conn =
        build_conn_for_path("/foo")
        |> Unpoly.evict_cache("/notes/*")

      assert ["/notes/*"] = get_resp_header(conn, "x-up-evict-cache")
    end

    test "evicts all cache entries with wildcard" do
      conn =
        build_conn_for_path("/foo")
        |> Unpoly.evict_cache("*")

      assert ["*"] = get_resp_header(conn, "x-up-evict-cache")
    end
  end

  describe "keep_cache/1" do
    test "prevents cache expiration" do
      conn =
        build_conn_for_path("/foo")
        |> Unpoly.keep_cache()

      assert ["false"] = get_resp_header(conn, "x-up-expire-cache")
    end
  end

  describe "put_resp_context_header/2" do
    test "sets response header with map" do
      conn =
        build_conn_for_path("/foo")
        |> Unpoly.put_resp_context_header(%{lives: 2})

      assert ["{\"lives\":2}"] = get_resp_header(conn, "x-up-context")
    end

    test "sets response header with string" do
      conn =
        build_conn_for_path("/foo")
        |> Unpoly.put_resp_context_header("{\"lives\":2}")

      assert ["{\"lives\":2}"] = get_resp_header(conn, "x-up-context")
    end

    test "handles nested maps" do
      conn =
        build_conn_for_path("/foo")
        |> Unpoly.put_resp_context_header(%{user: %{name: "Alice"}})

      assert ["{\"user\":{\"name\":\"Alice\"}}"] = get_resp_header(conn, "x-up-context")
    end

    test "handles nil values for removing keys" do
      conn =
        build_conn_for_path("/foo")
        |> Unpoly.put_resp_context_header(%{removed_key: nil})

      assert ["{\"removed_key\":null}"] = get_resp_header(conn, "x-up-context")
    end
  end

  describe "put_context/2" do
    test "updates context with map" do
      conn =
        build_conn_for_path("/foo")
        |> Unpoly.put_context(%{lives: 2})

      assert ["{\"lives\":2}"] = get_resp_header(conn, "x-up-context")
    end

    test "allows removing context keys with nil" do
      conn =
        build_conn_for_path("/foo")
        |> Unpoly.put_context(%{old_key: nil})

      assert ["{\"old_key\":null}"] = get_resp_header(conn, "x-up-context")
    end
  end

  describe "put_resp_open_layer_header/2" do
    test "sets response header with layer options map" do
      conn =
        build_conn_for_path("/foo")
        |> Unpoly.put_resp_open_layer_header(%{mode: "modal"})

      assert ["{\"mode\":\"modal\"}"] = get_resp_header(conn, "x-up-open-layer")
    end

    test "sets response header with multiple options" do
      conn =
        build_conn_for_path("/foo")
        |> Unpoly.put_resp_open_layer_header(%{mode: "drawer", size: "large"})

      header = get_resp_header(conn, "x-up-open-layer") |> List.first()
      decoded = Poison.decode!(header)
      assert %{"mode" => "drawer", "size" => "large"} = decoded
    end

    test "sets response header with string" do
      conn =
        build_conn_for_path("/foo")
        |> Unpoly.put_resp_open_layer_header("{\"mode\":\"modal\"}")

      assert ["{\"mode\":\"modal\"}"] = get_resp_header(conn, "x-up-open-layer")
    end
  end

  describe "open_layer/2" do
    test "opens layer with mode option" do
      conn =
        build_conn_for_path("/foo")
        |> Unpoly.open_layer(%{mode: "modal"})

      assert ["{\"mode\":\"modal\"}"] = get_resp_header(conn, "x-up-open-layer")
    end

    test "opens layer with multiple options" do
      conn =
        build_conn_for_path("/foo")
        |> Unpoly.open_layer(%{mode: "drawer", size: "large", class: "custom"})

      header = get_resp_header(conn, "x-up-open-layer") |> List.first()
      decoded = Poison.decode!(header)
      assert %{"mode" => "drawer", "size" => "large", "class" => "custom"} = decoded
    end
  end

  describe "emit_events/2" do
    test "emits simple event without properties" do
      conn =
        build_conn_for_path("/foo")
        |> Unpoly.emit_events("user:created")

      header = get_resp_header(conn, "x-up-events") |> List.first()
      decoded = Poison.decode!(header)
      assert %{"user:created" => %{}} = decoded
    end

    test "emits event with properties" do
      conn =
        build_conn_for_path("/foo")
        |> Unpoly.emit_events(%{"user:created" => %{id: 123, name: "Alice"}})

      header = get_resp_header(conn, "x-up-events") |> List.first()
      decoded = Poison.decode!(header)
      assert %{"user:created" => %{"id" => 123, "name" => "Alice"}} = decoded
    end

    test "emits multiple events" do
      conn =
        build_conn_for_path("/foo")
        |> Unpoly.emit_events(%{
          "user:created" => %{id: 123},
          "notification:show" => %{message: "User created"}
        })

      header = get_resp_header(conn, "x-up-events") |> List.first()
      decoded = Poison.decode!(header)
      assert %{"user:created" => %{"id" => 123}} = decoded
      assert %{"notification:show" => %{"message" => "User created"}} = decoded
    end
  end

  def build_conn_for_path(path, method \\ :get) do
    conn(method, path)
    |> fetch_query_params()
    |> put_private(:phoenix_endpoint, __MODULE__)
    |> put_private(:phoenix_router, __MODULE__)
  end
end
