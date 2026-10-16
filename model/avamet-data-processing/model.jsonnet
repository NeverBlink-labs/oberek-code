local lines = std.split(input, "\n");

local allChunks = std.flattenArrays([std.split(line, "|") for line in lines]);
local triple(x, y, z) = {
     subject:x ,
     predicate: y,
     object: z,
    };

local xsd = "http://www.w3.org/2001/XMLSchema#";

local makeLiteral(rawValue) =
    local value = std.stripChars(rawValue, " \r\n");
    "\"" + value + "\"^^<" + xsd + "string" + ">";

[
  triple(
    "<https://neverblink.eu/ontologies/oberek/" + std.split(chunk, "=")[0] + ">",
    "<https://saref.etsi.org/core/hasValue>",
    makeLiteral(std.split(chunk, "=")[1])
  )

  for chunk in allChunks
  if std.length(std.split(chunk, "=")) >= 2
]