local sheet = input.sheetAt(0);
local dataRect = sheet.cellRect(1, sheet.rowCount, 0, 5);

local str(val) = if val == null then "" else std.toString(val);

local latestPerSensor = std.foldl(
  function(acc, row)
    local id = str(row[0]);
    if id != "" then acc + { [id]: row } else acc,
  dataRect,
  {}
);

local nbi(s) = rdf.iri("https://neverblink.eu/oberek/" + s);
local saref(s) = rdf.iri("https://saref.etsi.org/core/" + s);
local s4watr(s) = rdf.iri("https://saref.etsi.org/saref4watr/" + s);
local unit(s) = rdf.iri("http://qudt.org/vocab/unit/" + s);
local wmdr_terr(s) = rdf.iri("http://codes.wmo.int/wmdr/ObservedVariableTerrestrial/" + s);
local xsd(s) = rdf.iri("http://www.w3.org/2001/XMLSchema#" + s);
local a = rdf.iri("http://www.w3.org/1999/02/22-rdf-syntax-ns#type");

local makeObservation(sensor, id, fecha, property, propTag, unit_val, value) =
  if value == "" then [] else
  local base = "https://neverblink.eu/oberek/water/" + id + "/" + propTag + "/" + std.strReplace(fecha, " ", "_");
  local obs = rdf.iri(base + "/obs");
  local res = rdf.iri(base + "/val");
  [
    rdf.triple(sensor, saref("madeExecution"), obs),
    rdf.triple(obs, a, saref("Observation")),
    rdf.triple(obs, saref("hasTimestamp"), rdf.literal(fecha)),
    rdf.triple(obs, saref("observes"), property),
    rdf.triple(obs, saref("hasResult"), res),
    rdf.triple(res, a, saref("PropertyValue")),
    rdf.triple(res, saref("isValueOfProperty"), property),
    rdf.triple(res, saref("isMeasuredIn"), unit_val),
    rdf.triple(res, saref("hasValue"), rdf.literal(value, xsd("float")))
  ];

std.flattenArrays([
  local id = str(row[0]);
  local fecha = str(row[1]);
  local nivel = str(row[2]);
  local caudal = str(row[3]);
  local volumen = str(row[4]);

  local station = nbi("station-" + id);
  local sensor = nbi("sensor-" + id);

  [
    rdf.triple(station, a, saref("Device")),
    rdf.triple(station, saref("hasIdentifier"), rdf.literal(id)),
    rdf.triple(station, saref("consistsOf"), sensor),
    rdf.triple(sensor, a, s4watr("WaterMeter")),
    rdf.triple(sensor, rdf.iri("http://www.w3.org/2000/01/rdf-schema#label"), rdf.literal(id, xsd("string")))
  ]
  + makeObservation(sensor, id, fecha, s4watr("FlowVolume"), "FlowVolume", unit("M3"), volumen)
  + makeObservation(sensor, id, fecha, s4watr("FlowRate"), "FlowRate", unit("M3-PER-SEC"), caudal)
  + makeObservation(sensor, id, fecha, wmdr_terr("12252"), "level", unit("M"), nivel)

  for row in std.objectValues(latestPerSensor)
])
