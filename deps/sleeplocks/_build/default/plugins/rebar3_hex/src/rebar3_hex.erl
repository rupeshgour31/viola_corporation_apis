-module(rebar3_hex).

-export([init/1]).

init(State) ->
    lists:foldl(fun provider_init/2, {ok, State}, [rebar3_hex_user,
                                                   rebar3_hex_cut,
                                                   rebar3_hex_key,
                                                   rebar3_hex_owner,
                                                   rebar3_hex_repo,
                                                   rebar3_hex_docs,
                                                   rebar3_hex_search,
                                                   rebar3_hex_revert,
                                                   rebar3_hex_retire,
                                                   rebar3_hex_publish]).

provider_init(Module, {ok, State}) ->
    Module:init(State).
