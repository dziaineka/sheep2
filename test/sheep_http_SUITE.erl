-module(sheep_http_SUITE).

-include_lib("common_test/include/ct.hrl").

-export([
    all/0,
    init_per_suite/1,
    end_per_suite/1
]).

-export([
    read_users_collection_test/1,
    read_users_item_test/1
]).

all() ->
    [
        read_users_collection_test,
        read_users_item_test
    ].

init_dispatch() ->
    cowboy_router:compile([
        {"localhost", [
            {"/users[/:user_id]", users_handler, []},
            {"/customers[/:customer_id]/orders[/:order_id]", orders_handler, []}
        ]}
    ]).

init_per_suite(Config) ->
    io:format("~p~n", [Config]),
    application:ensure_all_started(cowboy),
    {ok, _} = cowboy:start_http(
        server, 100, [{port, 0}], [
            {env, [
                {dispatch, init_dispatch()}
            ]},
            {max_keepalive, 50},
            {timeout, 500}
    ]),
    Port = ranch:get_port(server),
    {ok, Client} = cowboy_client:init([]),
    [
        {port, Port},
        {client, Client}
        |Config
    ].

end_per_suite(_Config) ->
    cowboy:stop_listener(server),
    ok.

build_url(Path, Config) ->
    Port = ?config(port, Config),
    PortBin = list_to_binary(integer_to_list(Port)),
    <<"http://localhost:", PortBin/binary, Path/binary >>.


read_users_collection_test(Config) ->

    Client = ?config(client, Config),
    {ok, Client2} = cowboy_client:request(
        <<"GET">>,
        build_url(<<"/users">>, Config),
        [{<<"accept">>, <<"application/json">>}],
        Client),
    {ok, 200, _, _} = cowboy_client:response(Client2).


read_users_item_test(Config) ->
    Client = ?config(client, Config),
    {ok, Request1} = cowboy_client:request(
        <<"GET">>,
        build_url(<<"/users/1">>, Config),
        [{<<"accept">>, <<"application/json">>}],
        Client),
    {ok, 200, _, _} = cowboy_client:response(Request1),

    {ok, Request2} = cowboy_client:request(
        <<"DELETE">>,
        build_url(<<"/users/1">>, Config), [],
        Client),
    {ok, 405, _, _} = cowboy_client:response(Request2),

    {ok, Request3} = cowboy_client:request(
        <<"GET">>,
        build_url(<<"/users/throw_id">>, Config), [],
        Client),
    {ok, 400, _, _} = cowboy_client:response(Request3),

    {ok, Request4} = cowboy_client:request(
        <<"GET">>,
        build_url(<<"/users/error_id">>, Config), [],
        Client),
    {ok, 400, _, _} = cowboy_client:response(Request4),

    {ok, Request5} = cowboy_client:request(
        <<"GET">>,
        build_url(<<"/users/custom_error_id">>, Config), [],
        Client),
    {ok, 400, _, Response5} = cowboy_client:response(Request5),
    {ok, <<"{\"error\":\"Message\"}">>, _} = cowboy_client:response_body(Response5).