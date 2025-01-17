-type http_code() :: integer().

-record(sheep_request, {
    method :: binary(),
    path :: binary(),
    headers = #{} :: maps:map(),
    query = #{} :: maps:map(),
    bindings = #{} :: maps:map(),
    body = <<>> :: maps:map() | [maps:map()] | binary(),
    peer :: {inet:ip_address(), inet:port_number()} | undefined
}).
-type sheep_request() :: #sheep_request{}.

-record(sheep_response, {
    status_code = 500 :: http_code(),
    headers = #{} :: maps:map(),
    body = <<>> :: maps:map() | [maps:map()] | binary() | undefined
}).
-type sheep_response() :: #sheep_response{}.

-record(sheep_options, {
    encode_spec :: undefined | maps:map(),
    decode_spec :: undefined | maps:map(),
    method_spec :: undefined | maps:map()
}).
-type sheep_options() :: #sheep_options{}.
