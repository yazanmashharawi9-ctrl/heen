// Regenerates shared/test-vectors/cells.json from the TypeScript implementation.
// The Dart tests read the same file, so both platforms must agree cell for cell.
//
//   node tools/geo/cell-vectors.ts

import { writeFileSync } from "node:fs";
import { join } from "node:path";
import { cellCenter, cellId } from "../../supabase/functions/_shared/geo/cell.ts";
import { ROOT } from "../content/lib.ts";

const points: Array<[string, number, number]> = [
  ["Amman", 31.9539, 35.9106],
  ["Jerusalem", 31.7683, 35.2137],
  ["Mecca", 21.4225, 39.8262],
  ["Riyadh", 24.7136, 46.6753],
  ["Cairo", 30.0444, 31.2357],
  ["Istanbul", 41.0082, 28.9784],
  ["London", 51.5072, -0.1276],
  ["New York", 40.7128, -74.006],
  ["Jakarta", -6.2088, 106.8456],
  ["Auckland", -36.8485, 174.7633],
  ["Anchorage", 61.2181, -149.9003],
  ["origin", 0, 0],
  ["cell boundary", 31.75, 35.75],
  ["just below a boundary", 31.7499999, 35.7499999],
  ["south pole", -90, -180],
  ["north pole", 90, 179.99],
  ["antimeridian east", 0, 180],
  ["antimeridian west", 0, -180],
];

const vectors = points.map(([name, lat, lon]) => {
  const id = cellId(lat, lon);
  return { name, lat, lon, cell: id, center: cellCenter(id) };
});

const path = join(ROOT, "shared", "test-vectors", "cells.json");
writeFileSync(path, `${JSON.stringify({ cellDeg: 0.25, vectors }, null, 2)}\n`, "utf8");
console.log(`wrote ${vectors.length} vectors to shared/test-vectors/cells.json`);
