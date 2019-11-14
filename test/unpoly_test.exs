defmodule UnpolyTest do
  use ExUnit.Case
  use Plug.Test

  @opts Unpoly.init([])

  test "mirrors request path and method in response headers" do
    conn =
      conn(:get, "/foo")
      |> Unpoly.call(@opts)

    assert ["/foo"] = get_resp_header(conn, "x-up-location")
    assert ["GET"] = get_resp_header(conn, "x-up-method")
  end

  test "appends method cookie to non GET requests" do
    conn =
      conn(:post, "/foo")
      |> Unpoly.call(@opts)

    assert %{"_up_method" => %{value: "POST"}} = conn.resp_cookies
  end

  test "deletes method cookie from GET requests" do
    conn =
      conn(:get, "/foo")
      |> put_req_cookie("_up_method", "POST")
      |> Unpoly.call(@opts)

    assert %{"_up_method" => %{max_age: 0}} = conn.resp_cookies
  end
end
