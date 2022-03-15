#include "pgo_api.h"
#include "utils/jsonb.h"

Datum pgo_api_Datum_of_json(char *s) {
  return DirectFunctionCall1(jsonb_in, CStringGetDatum(s));
}

Datum pgo_api_Datum_of_string(char *s) {
  return CStringGetDatum(cstring_to_text(s));
}
