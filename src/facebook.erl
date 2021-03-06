-module(facebook).
-author('Andrii Zadorozhnii').
-include_lib("avz/include/avz.hrl").
-include_lib("nitro/include/nitro.hrl").
-include_lib("n2o/include/wf.hrl").
-include_lib("avz/include/avz_user.hrl").

-compile(export_all).
-export(?API).

-define(HTTP_ADDRESS, application:get_env(web, http_address, [])).
-define(FB_APP_ID,    application:get_env(web, fb_id,        [])).

callback() -> ok.
event({facebook,_Event}) -> wf:wire("fb_login();"), ok.
api_event(fbLogin, Args, _Term) -> {JSArgs} = ?AVZ_JSON:decode(list_to_binary(Args)), avz:login(facebook, JSArgs).

registration_data(Props, facebook, Ori)->
    Id = proplists:get_value(<<"id">>, Props),
    BirthDay = case proplists:get_value(<<"birthday">>, Props) of
        undefined -> {1, 1, 1970};
        BD -> list_to_tuple([list_to_integer(X) || X <- string:tokens(binary_to_list(BD), "/")]) end,
    Email = email_prop(Props, facebook),
    [UserName|_] = string:tokens(binary_to_list(Email),"@"),
    Cover = case proplists:get_value(<<"cover">>,Props) of undefined -> ""; {P} -> case proplists:get_value(<<"source">>,P) of undefined -> ""; C -> binary_to_list(C) end end,
    Ori#avz_user{   id = Email,
                display_name = UserName,
                images = avz:update({fb_cover,Cover},avz:update({fb_avatar,"https://graph.facebook.com/" ++ binary_to_list(Id) ++ "/picture?type=large"},Ori#avz_user.images)),
                email = Email,
                names = proplists:get_value(<<"first_name">>, Props),
                surnames = proplists:get_value(<<"last_name">>, Props),
                tokens = avz:update({facebook,Id},Ori#avz_user.tokens),
                birth = {element(3, BirthDay), element(1, BirthDay), element(2, BirthDay)},
                register_date = os:timestamp(),
                status = ok }.

email_prop(Props, _) ->
    proplists:get_value(<<"email">>, Props).

login_button() -> application:get_env(avz,facebook_button,
    #panel{class=["btn-group"], body=#link{id=loginfb,
                  class=["btn-primary btn-large btn-lg"],
                  body=[#i{class=[fa,"fa-facebook","fa-lg","icon-facebook","icon-large"]},
                        <<"Facebook">>], postback={facebook,loginClick} }}).

sdk() ->
    wf:wire(#api{name=setFbIframe, tag=fb}),
    wf:wire(#api{name=fbAutoLogin, tag=fb}),
    wf:wire(#api{name=fbLogin, tag=fb}),
    [ #dtl{bind_script=false, file="facebook_sdk", ext="dtl", folder="priv/static/js",
        bindings=[{appid, ?FB_APP_ID},{channelUrl, ?HTTP_ADDRESS ++ "/static/channel.html"} ] } ].
