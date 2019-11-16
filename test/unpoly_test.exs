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

  describe "call/2" do
    def url(), do: "https://www.example.com"

    def build_conn_for_path(path, method \\ :get) do
      conn(method, path)
      |> fetch_query_params()
      |> put_private(:phoenix_endpoint, __MODULE__)
      |> put_private(:phoenix_router, __MODULE__)
    end

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
end
