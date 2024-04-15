%% @doc This provider allows the user to delete a package within one
%% hour of its publication.
%% @end
-module(rebar3_hex_retire).

-export([init/1,
         do/1,
         format_error/1]).

-export([retire/6]).

-include("rebar3_hex.hrl").

-define(PROVIDER, retire).
-define(DEPS, []).

%% ===================================================================
%% Public API
%% ===================================================================

-spec init(rebar_state:t()) -> {ok, rebar_state:t()}.
init(State) ->
    Provider = providers:create([{name, ?PROVIDER},
                                 {module, ?MODULE},
                                 {namespace, hex},
                                 {bare, true},
                                 {deps, ?DEPS},
                                 {example, "rebar3 hex retire some_pkg 0.3.0"},
                                 {short_desc, "Mark a package as deprecated."},
                                 {desc, ""},
                                 {opts, [{pkg, undefined, undefined, string, "Name of the package to retire."},
                                         {vsn, undefined, undefined, string, "Version of the package to retire."},
                                         {reason, undefined, undefined, string, "Reason to retire package."},
                                         {message, undefined, undefined, string, "Clarifying message for retirement"},
                                         rebar3_hex_utils:repo_opt()]}]),
    State1 = rebar_state:add_provider(State, Provider),
    {ok, State1}.

-spec do(rebar_state:t()) -> {ok, rebar_state:t()} | {error, string()}.
do(State) ->
    Repo = rebar3_hex_utils:repo(State),

    {Args, _} = rebar_state:command_parsed_args(State),
    Name = get_required(pkg, Args),
    PkgName = rebar_utils:to_binary(Name),
    Version = get_required(vsn, Args),
    Reason = get_required(reason, Args),
    Message = get_required(message, Args),
    retire(PkgName, rebar_utils:to_binary(Version), Repo,
           rebar_utils:to_binary(Reason),
           rebar_utils:to_binary(Message),
           State).

get_required(Key, Args) ->
    case proplists:get_value(Key, Args) of
        undefined ->
            throw(?PRV_ERROR({required, Key}));
        Value ->
            Value
    end.

format_error({api_error, PkgName, Version, Reason}) ->
    io_lib:format("Unable to delete package ~ts ~ts: ~ts", [PkgName, Version, Reason]);
format_error({required, pkg}) ->
    "retire requires a package name argument to identify the package to delete";
format_error({required, vsn}) ->
    "retire requires a version number argument to identify the package to delete";
format_error({required, reason}) ->
    "retire requires a reason with value of either other, invalid, security, deprecated or renamed";
format_error({required, message}) ->
    "retire requires a message to clarify the reason for the retirement of the package".

%%

retire(PkgName, Version, Repo, Reason, Message, State) ->
    case maps:get(write_key, Repo, undefined) of
        undefined ->
            {error, no_write_key};
        WriteKey ->
            Username = maps:get(username, Repo),
            HexConfig = Repo#{api_key => rebar3_hex_user:decrypt_write_key(Username, WriteKey)},

            Body = #{<<"reason">> => Reason,
                     <<"message">> => Message},

            case hex_api_release:retire(HexConfig, PkgName, Version, Body) of
                {ok, {Code, _Headers, _Body}} when Code =:= 204 ->
                    rebar_api:info("Successfully retired package ~ts ~ts", [PkgName, Version]),
                    {ok, State};
                {ok, {Code, _Headers, _Body}} ->
                    ?PRV_ERROR({api_error, PkgName, Version, rebar3_hex_utils:pretty_print_status(Code)});
                {error, Reason} ->
                    ?PRV_ERROR({api_error, PkgName, Version, io_lib:format("~p", [Reason])})
            end
    end.
