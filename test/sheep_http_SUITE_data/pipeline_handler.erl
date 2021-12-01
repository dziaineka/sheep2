-module(pipeline_handler).
-behaviour(sheep_http).

-export([
    init/2, sheep_init/2, authorization/2, paging/2,
    validation/2, stage4/2, read/2, create/2
]).

-include("sheep.hrl").

-record(state, {steps = [], user_id}).
-type state() :: state{}.


-spec init(cowboy_req:req(), term()) -> tuple().
init(Req, Opts) ->
    {sheep_http, Req, Opts}.


-spec sheep_init(sheep_request(), term()) -> {sheep_options(), term()}.
sheep_init(_Request, _Opts) ->
    Options =
        #sheep_options{
            method_spec =
            #{
                <<"GET">> => [authorization, paging, read],
                <<"POST">> =>
                [
                    authorization,
                    validation,
                    fun(_R, #state{steps = Steps} = State) ->
                        {continue, State#state{steps = [<<"stage3">> | Steps]}}
                    end,
                    fun stage4/2,
                    create
                ]
            }
        },
    State = state(),
    {Options, State}.


-spec authorization(sheep_request(), state()) -> {continue, state()} | sheep_response().
authorization(Request, #state{steps = Steps} = State) ->
    Token = sheep_http:get_header(<<"x-auth-token">>, Request),
    case Token of
        <<"cft6GLEhLANgstU8sZdL">> ->
            {continue, State#state{steps = [<<"auth">> | Steps]}};
        _ ->
            #sheep_response{status_code = 401, body = <<"Auth error">>}
    end.


-spec paging(sheep_request(), state()) -> {continue, state()} | sheep_response().
paging(_Request, #state{steps = Steps} = State) ->
    {continue, State#state{steps = [<<"paging">> | Steps]}}.


-spec validation(sheep_request(), state()) -> {continue, state()} | sheep_response().
validation(#sheep_request{body = Body}, #state{steps = Steps} = State) ->
    case Body of
        #{<<"user_id">> := UserID} ->
            {continue, State#state{steps = [<<"validation">> | Steps], user_id = UserID}};
        _ -> #sheep_response{status_code = 400, body = #{<<"error">> => <<"User ID not provided">>}}
    end.


-spec stage4(sheep_request(), state()) -> {continue, state()} | sheep_response().
stage4(_Request, #state{steps = Steps} = State) ->
    {continue, State#state{steps = [<<"stage4">> | Steps]}}.


-spec read(sheep_request(), state()) -> sheep_response().
read(_Request, #state{steps = Steps}) ->
    Body = #{
        <<"reply_from">> => <<"read">>,
        <<"steps">> => Steps
    },
    #sheep_response{status_code = 200, body = Body}.


-spec create(sheep_request(), state()) -> sheep_response().
create(_Request, #state{steps = Steps, user_id = UserID}) ->
    Body = #{
        <<"reply_from">> => <<"create">>,
        <<"steps">> => Steps,
        <<"user_id">> => UserID
    },
    #sheep_response{status_code = 200, body = Body}.
