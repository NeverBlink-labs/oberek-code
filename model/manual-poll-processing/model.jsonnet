local nb(s)    = rdf.iri("https://neverblink.eu/ontologies/oberek/" + s);
local nbi(s)   = rdf.iri("https://neverblink.eu/oberek/" + s);
local saref(s) = rdf.iri("https://saref.etsi.org/core/" + s);
local xsd(s)   = rdf.iri("http://www.w3.org/2001/XMLSchema#" + s);
local a        = rdf.iri("http://www.w3.org/1999/02/22-rdf-syntax-ns#type");

local DEFAULT_CATEGORY = "OtherRespondent";

local str(v) = if v == null then "" else std.toString(v);
local cell(row, i) = if std.length(row) > i then str(row[i]) else "";

local answer(s) = if s == "" then 0 else std.parseInt(s);

local DIGITS = "0123456789";
local isIntStr(s) = s != "" && std.stripChars(s, DIGITS) == "";
local ratingOk(s) = s == "" || isIntStr(s);

local digits(s, i, n) = isIntStr(std.substr(s, i, n));
local at(s, i, c) = std.substr(s, i, 1) == c;
local isoOk(s) =
  std.length(s) == 20 &&
  at(s, 4, "-") && at(s, 7, "-") && at(s, 10, "T") &&
  at(s, 13, ":") && at(s, 16, ":") && at(s, 19, "Z") &&
  digits(s, 0, 4) && digits(s, 5, 2) && digits(s, 8, 2) &&
  digits(s, 11, 2) && digits(s, 14, 2) && digits(s, 17, 2);

local validRow(row) =
  std.length(row) >= 5 &&
  isoOk(cell(row, 0)) &&
  std.foldl(function(acc, n) acc && ratingOk(cell(row, n)), [1, 2, 3, 4], true);

local rowStatements(row, i) =
  local cat = if cell(row, 5) != "" then cell(row, 5) else DEFAULT_CATEGORY;
  local base = "https://neverblink.eu/oberek/poll/manual/" + std.toString(i) + "/" + cell(row, 0);
  local sub = rdf.iri(base + "/obs");
  [
    rdf.triple(sub, a, saref("Observation")),
    rdf.triple(sub, saref("hasTimestamp"), rdf.literal(cell(row, 0), xsd("dateTime"))),
    rdf.triple(sub, nb("forPoll"), nbi("CommunityPoll")),
    rdf.triple(sub, nb("categoryAnswer"), nb(cat)),
  ]
  + std.flattenArrays([
      local an = rdf.iri(base + "/q" + std.toString(n));
      [
        rdf.triple(sub, nb("ratingAnswer"), an),
        rdf.triple(an, nb("forQuestion"), nbi("CommunityPoll-q" + std.toString(n))),
        rdf.triple(an, nb("answerValue"), rdf.literal(answer(cell(row, n)))),
      ]
      for n in [1, 2, 3, 4]
    ]);

std.flattenArrays([
  rowStatements(input.rows[i], i)
  for i in std.range(0, std.length(input.rows) - 1)
  if validRow(input.rows[i])
])