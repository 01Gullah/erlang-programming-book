-module(justify).
-export([justify/1]).

-define(MAX_LINE_LEN, 60).

text_to_raw([], _, _, AccLine) ->
    AccLine;

text_to_raw([$\n|Source], CharCount, AccChar, AccLine) ->
    text_to_raw(Source, CharCount, AccChar, AccLine);

text_to_raw([$ |Source], CharCount, AccChar, AccLine) when CharCount > ?MAX_LINE_LEN ->
    text_to_raw(Source, 1, [], AccLine ++ [AccChar]);

text_to_raw([Char|Source], CharCount, AccChar, AccLine) ->
    text_to_raw(Source, CharCount + 1, AccChar ++ [Char], AccLine).

text_to_raw(Filename) ->
    {ok, Source} = file:read_file(Filename),
    text_to_raw(binary_to_list(Source), 1, [], []).

raw_to_document([]) ->
    [];

raw_to_document([L|Lines]) ->
    raw_to_document(Lines, [line_to_words(L)]).

raw_to_document([], Acc) ->
    lists:reverse(Acc);

raw_to_document([L|Lines], Acc) ->
    raw_to_document(Lines, [line_to_words(L) | Acc]).

line_to_words(Line) ->
    line_to_words(Line, []).

line_to_words([], Acc) ->
    string:tokens(Acc, [$ ]);

line_to_words([C|Line], Acc) ->
    line_to_words(Line, Acc ++ [C]).

count_chars([]) ->
    0;

count_chars(Doc) ->
    lists:foldl(fun(Word, Sum) -> length(Word) + Sum end, 0, Doc).

max_chars_per_line([], Max) ->
    Max;

max_chars_per_line([Doc], Max) ->
    Count = count_chars(Doc),
    if Count > Max -> Count; true -> Max end;

max_chars_per_line([Doc|T], Max) ->
    Count = count_chars(Doc),
    max_chars_per_line(T, if Count > Max -> Count; true -> Max end).

justify(Filename) ->
    Raw = text_to_raw(Filename),
    Doc = raw_to_document(Raw),
    Max = max_chars_per_line(Doc, 0),
    NewDoc = if Max > 0 ->
        justify_doc(Doc, Max, []);
    true ->
        [[]]
    end,
    justify_print(NewDoc).

justify_doc([], _, Acc) ->
    lists:reverse(Acc);

justify_doc([Line|T], Max, Acc) ->
    Fill = Max - count_chars(Line),
    justify_doc(T, Max, [justify_line(Line, Fill, []) | Acc]).

justify_line([], _, Acc) ->
    lists:reverse(Acc);

justify_line([Word|T], 0, Acc) ->
    justify_line(T, 0, [Word ++ [$ ] | Acc]);

justify_line([Word|T], Fill, Acc) ->
    SpacesToFill = length(T) / Fill,
    Trunc = trunc(SpacesToFill),
    Spaces = if Trunc == SpacesToFill -> Trunc; true -> Trunc + 1 end,
    RestFill = if Spaces > Fill -> 0; true -> Fill - Spaces end,
    justify_line(T, RestFill, [Word ++ lists:duplicate(Spaces, $ ) | Acc]).

justify_print([]) ->
    ok;

justify_print([Line|T]) ->
    io:format("~s~n", [Line]),
    justify_print(T).














