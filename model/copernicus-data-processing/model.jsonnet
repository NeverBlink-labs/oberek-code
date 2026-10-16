local ctx = input.context;
local g = input.item;
local req = "<http://example.org/copernicusRequest>";
local token = g.path(req, "<http://example.org/accessToken>").one.auto;

// WKT rectangle -> west/south/east/north
local wkt = g.path(req, "<http://example.org/sceneWkt>").one.auto;
local ring = std.splitLimit(std.splitLimit(wkt, "((", 1)[1], "))", 1)[0];
local points = [
  [std.parseJson(c) for c in std.split(std.stripChars(p, " "), " ")]
  for p in std.split(ring, ",")
];
local lons = [p[0] for p in points];
local lats = [p[1] for p in points];
local minOf(xs) = std.foldl(std.min, xs, xs[0]);
local maxOf(xs) = std.foldl(std.max, xs, xs[0]);
local startDate = std.format("%04d-%02d-01T00:00:00Z", [if ctx.month == 1 then ctx.year - 1 else ctx.year, if ctx.month == 1 then 12 else ctx.month - 1]);
local endDate = ctx.iso;

local maxCloudCover = 10;

local openEoGraph = {
  "process": {
    "process_graph": {
      "loadcollection": {
        "process_id": "load_collection",
        "arguments": {
          "id": "sentinel-2-l2a",
          "spatial_extent": {
            "west": minOf(lons),
            "south": minOf(lats),
            "east": maxOf(lons),
            "north": maxOf(lats),
            "width": 512,
            "height": 512
          },
          "temporal_extent": [
            startDate,
            endDate
          ],
          "bands": ["B02", "B03", "B04", "B05", "B06", "B07", "B08", "B8A", "B11", "B12", "viewZenithMean", "viewAzimuthMean", "sunZenithAngles", "sunAzimuthAngles", "SCL"],
          "cloudCoverage": maxCloudCover
        }
      },
      "last_time": {
        "process_id": "reduce_dimension",
        "arguments": {
          "data": { "from_node": "loadcollection" },
          "dimension": "t",
          "reducer": {
            "process_graph": {
              "last": {
                "process_id": "last",
                "arguments": { "data": { "from_parameter": "data" } },
                "result": true
              }
            }
          }
        }
      },
      "save": {
        "process_id": "save_result",
        "arguments": {
          "data": { "from_node": "last_time" },
          "format": "GTiff"
        },
        "result": true
      }
    }
  }
};

{
  uri: "<OPENEO_RESULT_URL>",
  method: "POST",
  headers: {
    "Authorization": "Bearer " + token
  },
  body: {
    type: "bytes",
    contentType: "application/json",
    data: std.manifestJsonEx(openEoGraph, "")
  }
}