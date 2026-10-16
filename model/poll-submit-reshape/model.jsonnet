local body = std.parseJson(input.body.data);
local responses = if std.objectHas(body, "responses") then body.responses else {};

// Same default as the manual poll upload: no category means "Other"
local DEFAULT_CATEGORY = "nb:OtherRespondent";
local category =
  if std.objectHas(body, "respondent_category") && body.respondent_category != null && body.respondent_category != ""
  then body.respondent_category
  else DEFAULT_CATEGORY;

std.manifestJson({
  poll_id: if std.objectHas(body, "poll_id") then body.poll_id else "",
  timestamp: if std.objectHas(body, "timestamp") then body.timestamp else "",
  respondent_category: category,
  responses: [
    { question_id: q, answer: responses[q] }
    for q in std.objectFields(responses)
  ],
})