-record(templates, {ns = undef, templateNs = undef, dictionary = undef, template}).
-record(template, {name, templateNs = undef, id= undef, ns = undef, dictionary = undef, typeRef = undef, instructions}).
-record(typeRef, {name, ns = undef}).
-record(templateRef, {name, templateNs = undef, ns = undef}).
-record(int32, {name, ns = undef, id = undef, presence = mandatory, operator = undef}).
-record(uInt32, {name, ns = undef, id = undef, presence = mandatory, operator = undef}).
-record(int64, {name, ns = undef, id = undef, presence = mandatory, operator = undef}).
-record(uInt64, {name, ns = undef, id = undef, presence = mandatory, operator = undef}).
-record(decimal, {name, ns = undef, id = undef, presence = mandatory, operator = undef}).
-record(string, {name, ns = undef, id = undef, presence = mandatory, charset, length, operator = undef}).
-record(byteVector, {name, ns = undef, id = undef, presence = mandatory, length, operator = undef}).
-record(sequence, {name, ns = undef, id = undef, presence = mandatory, dictionary = undef, typeRef = undef, instructions}).
-record(length, {name = undef, ns = undef, id = undef, operator = undef}).
-record(group, {name, ns = undef, id = undef, presence = mandatory, dictionary = undef, typeRef = undef, instructions}).
-record(constant, {value = undef}).
-record(default,  {value = undef}).
-record(copy, {dictionary = undef, key = undef, ns = undef, value = undef}).
-record(increment, {dictionary = undef, key = undef, ns = undef, value = undef}).
-record(delta, {dictionary = undef, key = undef, ns = undef, value = undef}).
-record(tail, {dictionary = undef, key = undef, ns = undef, value = undef}).
-record(decFieldOp, {exponent, mantissa}).
