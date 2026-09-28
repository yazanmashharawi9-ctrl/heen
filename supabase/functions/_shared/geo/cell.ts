// The weather grid: 0.25° cells, about 28 km north–south.
//
// A device computes its own cell and only ever sends the cell id, never its
// coordinates. app/lib/core/geo_cell.dart implements the same function; both
// are checked against shared/test-vectors/cells.json.

export const CELL_DEG = 0.25;
const LAT_CELLS = 180 / CELL_DEG; // 720
const LON_CELLS = 360 / CELL_DEG; // 1440
const ID = /^(\d{1,3})-(\d{1,4})$/;

export function cellId(lat: number, lon: number): string {
  if (!Number.isFinite(lat) || !Number.isFinite(lon) || lat < -90 || lat > 90 || lon < -180 || lon > 180) {
    throw new RangeError(`not a coordinate: ${lat}, ${lon}`);
  }
  const latIndex = Math.min(LAT_CELLS - 1, Math.floor((lat + 90) / CELL_DEG));
  // lon + 180 is in [0, 360]; only 360 (the antimeridian) wraps to 0.
  let x = (lon + 180) % 360;
  if (x < 0) x += 360;
  const lonIndex = Math.min(LON_CELLS - 1, Math.floor(x / CELL_DEG));
  return `${latIndex}-${lonIndex}`;
}

export function parseCellId(id: string): { latIndex: number; lonIndex: number } | null {
  const match = ID.exec(id);
  if (!match) return null;
  const latIndex = Number(match[1]);
  const lonIndex = Number(match[2]);
  if (latIndex >= LAT_CELLS || lonIndex >= LON_CELLS) return null;
  return { latIndex, lonIndex };
}

/** Centre of a cell — where the server asks for the weather. */
export function cellCenter(id: string): { lat: number; lon: number } {
  const parsed = parseCellId(id);
  if (!parsed) throw new RangeError(`not a cell id: ${id}`);
  return {
    lat: parsed.latIndex * CELL_DEG - 90 + CELL_DEG / 2,
    lon: parsed.lonIndex * CELL_DEG - 180 + CELL_DEG / 2,
  };
}
