%% @doc This provider allows the user to delete a package within one
%% hour of its publication.
%% @end
-module(rebar3_hex_revert).

-export([init/1,
         do/1,
         format_error/1]).

-export([revert/4]).

-include("rebar3_hex.hrl").

-define(PROVIDER, revert).
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
                                 {example, "rebar3 hex revert some_pkg 0.3.0"},
                                 {short_desc, "Delete a package from the repository"},
                                 {desc, ""},
                                 {opts, [{pkg, undefined, undefined, string, "Name of the package to delete."},
                                         {vsn, undefined, undefined, string, "Version of the package to delete."},
                                         rebar3_hex_utils:repo_opt()]}]),
    State1 = rebar_state:add_provider(State, Provider),
    {ok, State1}.

-spec do(rebar_state:t()) -> {ok, rebar_state:t()} | {error, string()}.
do(State) ->
    Repo = rebar3_hex_utils:repo(State),

    {Args, _} = rebar_state:command_parsed_args(State),
    case proplists:get_value(pkg, Args, undefined) of
        undefined ->
            ?PRV_ERROR(package_name_required);
        Name ->
            PkgName = rebar_utils:to_binary(Name),
            case proplists:get_value(vsn, Args, undefined) of
                undefined ->
                    ?PRV_ERROR(version_required);
                Version ->
                    case revert(PkgName, rebar_utils:to_binary(Version), Repo, State) of
                        ok ->
                            {ok, State};
                        Error ->
                            Error
                    end
            end
    end.

format_error({api_error, PkgName, Version, Reason}) ->
    io_lib:format("Unable to delete package ~ts ~ts: ~ts", [PkgName, Version, Reason]);
format_error(package_name_required) ->
    "revert requires a package name argument to identify the package to delete";
format_error(version_required) ->
    "revert requires a version number argument to identify the package to delete".

%%

revert(PkgName, Version, Repo, _State) ->
    case maps:get(write_key, Repo, undefined) of
        undefined ->
            {error, no_write_key};
        WriteKey ->
            Username = maps:get(username, Repo),
            HexConfig = Repo#{api_key => rebar3_hex_user:decrypt_write_key(Username, WriteKey)},

            case hex_api_release:delete(HexConfig, PkgName, Version) of
                {ok, {Code, _Headers, _Body}} when Code =:= 200 ;
                                                   Code =:= 204 ->
                    rebar_api:info("Successfully deleted package ~ts ~ts", [PkgName, Version]),
                    case ec_talk:ask_default(io_lib:format("Also delete tag v~s?", [Version]), boolean, "N") of
                        true ->
                            rebar_utils:sh(io_lib:format("git tag -d v~s", [Version]), []);
                        _ ->
                            ok
                    end;
                {ok, {Code, _Headers, _Body}} ->
                    ?PRV_ERROR({api_error, PkgName, Version, rebar3_hex_utils:pretty_print_status(Code)});
                {error, Reason} ->
                    ?PRV_ERROR({api_error, PkgName, Version, io_lib:format("~p", [Reason])})
            end
    end.
