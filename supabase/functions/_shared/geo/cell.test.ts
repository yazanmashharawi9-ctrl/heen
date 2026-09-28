import { test } from "node:test";
import assert from "node:assert/strict";
import shared from "../../../../shared/test-vectors/cells.json" with { type: "json" };
import { cellCenter, cellId, parseCellId } from "./cell.ts";

test("matches every shared vector (the Dart implementation checks the same file)", () => {
  for (const v of shared.vectors) {
    assert.equal(cellId(v.lat, v.lon), v.cell, v.name);
    assert.deepEqual(cellCenter(v.cell), v.center, v.name);
  }
});

test("the centre of a cell lies in that cell", () => {
  for (const v of shared.vectors) {
    const c = cellCenter(v.cell);
    assert.equal(cellId(c.lat, c.lon), v.cell, v.name);
  }
});

test("rejects bad coordinates and ids", () => {
  assert.throws(() => cellId(91, 0), RangeError);
  assert.throws(() => cellId(0, Number.NaN), RangeError);
  assert.equal(parseCellId("720-0"), null);
  assert.equal(parseCellId("1-1440"), null);
  assert.equal(parseCellId("12;drop table"), null);
  assert.deepEqual(parseCellId("487-863"), { latIndex: 487, lonIndex: 863 });
});
