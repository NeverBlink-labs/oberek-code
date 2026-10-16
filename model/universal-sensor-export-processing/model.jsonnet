local data = [
  local obs = input.path(res, {inverse: "saref:hasResult"}).all[0];
  local sensor = input.path(obs, {inverse: "saref:madeExecution"}).all[0];
  local device = input.path(sensor, {inverse: "saref:consistsOf"}).oneOr(null);

  local raw_device_id = if device != null then std.toString(device) else "Unknown";
  local sensor_iri = std.toString(sensor);
  local rawVal = input.path(res, "saref:hasValue").oneOr(null);

  {
    timestamp: input.path(obs, "saref:hasTimestamp").all[0].auto,

    device: std.stripChars(raw_device_id, "<>"),
    sensor: std.stripChars(sensor_iri, "<>"),

    feature: std.stripChars(std.toString(input.path(res, "saref:isValueOfProperty").all[0]), "<>"),
    statistic_type: std.stripChars(std.toString(input.path(res, "disco:summaryStatisticType").oneOr("")), "<>"),
    unit: std.stripChars(std.toString(input.path(res, "saref:isMeasuredIn").oneOr("")), "<>"),
    value: if rawVal != null then rawVal.auto else ""
  }
  for res in input.ofType("saref:PropertyValue").all
];

if std.extVar("outputFormat") == "csv" then
  {
    header: ["timestamp", "device", "sensor", "feature", "statistic_type", "unit", "value"],
    rows: [
      [row.timestamp, row.device, row.sensor, row.feature, row.statistic_type, row.unit, row.value]
      for row in data
    ]
  }
else
  data