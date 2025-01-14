-module(erlang_fast_utils).

-export(
   [
      is_nullable/1
      ,apply_delta/3
      ,apply_delta/2
      ,get_delta/2
      ,increment_value/3
      ,print_binary/1
      ,select_dict/3
   ]).

-include("include/erlang_fast_common.hrl").
-include("include/erlang_fast_context.hrl").
-include("include/erlang_fast_template.hrl").

-include_lib("eunit/include/eunit.hrl").

is_nullable(optional) -> true;
is_nullable(mandatory) -> false.

select_dict(type, _TemplateName, Application) ->
   ?type_dictionary(Application);
select_dict(template, TemplateName, _Application) ->
   ?template_dictionary(TemplateName);
select_dict(Dict, _, _) ->
   Dict.

apply_delta(undef, {MantissaDelta, ExponentDelta}) ->
   apply_delta({0, 0}, {MantissaDelta, ExponentDelta});

apply_delta({BaseMantissa, BaseExponent}, {MantissaDelta, ExponentDelta}) ->
   {BaseMantissa + MantissaDelta , BaseExponent + ExponentDelta};

apply_delta(undef, Delta) ->
   apply_delta(0, Delta);

apply_delta(BaseValue, Delta) ->
   BaseValue + Delta.

apply_delta(undef, Len, Delta) ->
   apply_delta(<<>>, Len, Delta);

apply_delta(PrevVal, Len, Delta) when byte_size(PrevVal) < abs(Len) ->
   throw({error, ['ERR D7', PrevVal, {Len, Delta}]});

apply_delta(PrevVal, Len, Delta) when Len >= 0 ->
   Head = binary_part(PrevVal, 0, byte_size(PrevVal) - Len),
   <<Head/bytes, Delta/bytes>>;

apply_delta(PrevVal, Len, Delta) when Len < 0 ->
   % Len should be incremented by 1 according to 6.3.7.3
   Tail = binary_part(PrevVal, abs(Len + 1), byte_size(PrevVal) + Len + 1),
   <<Delta/bytes, Tail/bytes>>.

get_delta(NewValue, undef) when is_number(NewValue) ->
   get_delta(NewValue, 0);

get_delta(NewDecimal = {_, _}, undef) ->
   get_delta(NewDecimal, {0, 0});

get_delta(Value, undef) ->
   get_delta(Value, <<"">>);

get_delta(NewValue, OldValue) when is_number(NewValue) andalso is_number(OldValue) ->
   NewValue - OldValue;

get_delta({NewMantissa, NewExponent}, {OldMantissa, OldExponent}) ->
   {NewMantissa - OldMantissa, NewExponent - OldExponent};

get_delta(NewValue, OldValue) ->
   case binary:longest_common_prefix([NewValue, OldValue]) of
      0 ->
         case binary:longest_common_suffix([NewValue, OldValue]) of
            0 ->
               {byte_size(OldValue), NewValue};
            SuffixLen ->
               % if length is negative or 0, it should be decremented by 1 before encoding (see 6.3.7.3 for details)
               {-(byte_size(OldValue) - SuffixLen) - 1, binary:part(NewValue, 0, byte_size(NewValue) - SuffixLen)}
         end;
      PrefixLen ->
         {byte_size(OldValue) - PrefixLen, binary:part(NewValue, PrefixLen, byte_size(NewValue) - PrefixLen)}
   end.

increment_value(int32, Value, Inc) when Value + Inc >= 2147483647 ->
   -2147483648 + Inc;
increment_value(int64, Value, Inc) when Value + Inc >= 9223372036854775807 ->
   -9223372036854775808 + Inc;
increment_value(uInt32, Value, Inc) when Value + Inc >= 4294967295 ->
   Inc;
increment_value(uInt64, Value, Inc) when Value + Inc >= 18446744073709551615 ->
   Inc;
increment_value(Type, Value, Inc) when (Type == int32) or (Type == int64) or (Type == uInt32) or (Type == uInt64)->
   Value + Inc.

print_binary(<<>>) ->
   [];
print_binary(<<0:1, Rest/bits>>) ->
   [$0 | print_binary(Rest)];
print_binary(<<1:1, Rest/bits>>) ->
   [$1 | print_binary(Rest)].

%% ====================================================================================================================
%% unit testing
%% ====================================================================================================================
-ifdef(EUNIT).
-include_lib("eunit/include/eunit.hrl").

apply_delta_test() ->
   ?assertEqual(<<"abcdeab">>, apply_delta(<<"abcdef">>, 1, <<"ab">>)),
   ?assertEqual(<<"abcdab">>, apply_delta(<<"abcdef">>, 2, <<"ab">>)),
   ?assertEqual(<<"xybcdef">>, apply_delta(<<"abcdef">>, -2, <<"xy">>)),
   ?assertEqual(<<"abcdefxy">>, apply_delta(<<"abcdef">>, 0, <<"xy">>)),
   ?assertThrow({error, ['ERR D7', <<"abcdef">>, {7, <<"abc">>}]}, apply_delta(<<"abcdef">>, 7, <<"abc">>)),
   ?assertEqual(<<"abxy">>, apply_delta(<<"abcdef">>, 4, <<"xy">>)),
   ?assertEqual(<<1,2,3,5,6>>, apply_delta(<<1,2,3,4>>, 1, <<5,6>>)),
   ?assertEqual(<<5,6,3,4>>, apply_delta(<<1,2,3,4>>, -3, <<5,6>>)),
   ?assertEqual(<<1,2,3,5,6>>, apply_delta(<<1,2,3,4>>, 1, <<5,6>>)),
   ?assertEqual(<<5,6,3,4>>, apply_delta(<<1,2,3,4>>, -3, <<5,6>>)).

print_binary_test() ->
   ?assertEqual("10101110", print_binary(<<16#ae>>)).

get_delta_test() ->
   ?assertEqual({0, <<"123">>}, get_delta(<<"abc123">>, <<"abc">>)),
   ?assertEqual({1, <<"123">>}, get_delta(<<"abc123">>, <<"abc2">>)),
   ?assertEqual({-1, <<"123">>}, get_delta(<<"123abc">>, <<"abc">>)),
   ?assertEqual({-2, <<"123">>}, get_delta(<<"123abc">>, <<"2abc">>)),
   ?assertEqual({5, <<"abc">>}, get_delta(<<"abc">>, <<"12345">>)),
   ?assertEqual({-2, <<5,6>>}, get_delta(<<5,6,3,4>>, <<1,3,4>>)),
   ?assertEqual({2, <<>>}, get_delta(<<5,6>>, <<5,6,3,4>>)).

-endif.
