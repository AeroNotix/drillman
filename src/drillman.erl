-module(drillman).

-export([send/6]).
-export([send/7]).

-define(MANDRILL_API, "https://mandrillapp.com/api/1.0/messages/send.json").

-define(NULL_FIELDS,
        [{async, false},
         {send_at, <<"">>},
         {ip_pool, <<"whatever">>}
         ]).

send(APIKey, Recipient, Subject, From, Message, Extra) ->
    send(APIKey, Recipient, Subject, From, Message, Extra, <<"You">>).

send(APIKey, Recipient, Subject, From, Message, Extra, Name) ->
    ToEmail = [{email, Recipient},
               {type, <<"to">>},
               {name, Name}],
    Payload =
        ?NULL_FIELDS ++
        [{key, APIKey},
         {message,
          [{html, Message},
           {subject, Subject},
           {from_email, From},
           {to, [ToEmail]}|Extra]}],
    Uri = ?MANDRILL_API,
    Headers = [],
    ContentType = "application/json",
    Body = binary_to_list(jsx:encode(Payload)),
    Request = {Uri, Headers, ContentType, Body},
    {ok, Resp} = httpc:request(post, Request, [], []),
    handle_resp(Resp).

handle_resp({{_, 200, _}, _Headers, Body}) ->
    BinBody = list_to_binary(Body),
    [Resp] = jsx:decode(BinBody),
    Status = proplists:get_value(<<"status">>, Resp),
    case Status of
        <<"sent">> ->
            ok;
        <<"queued">> ->
            {ok, queued};
        <<"invalid">> ->
            {error, {invalid, Resp}};
        O -> {error, O}
    end;
handle_resp(R) -> %% TODO Handle this better
    {error, R}.
