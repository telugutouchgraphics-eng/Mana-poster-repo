const {test} = require("node:test");
const assert = require("node:assert/strict");
const {collectPublishedCategoryPosters, collectPublishedPosterDocuments, isGoodNightPosterReleased} = require("./poster_category_presence");

function queryFor(docs, failAfter = Infinity, offset = 0, count = 250) {
  return {
    startAfter(cursor) {return queryFor(docs, failAfter, docs.indexOf(cursor) + 1, count);},
    limit(size) {return queryFor(docs, failAfter, offset, size);},
    async get() {
      if (offset >= failAfter) throw new Error("Read interrupted");
      return {docs: docs.slice(offset, offset + count)};
    },
  };
}
function poster(id, categoryId, overrides = {}) {
  const data = {id, categoryId, categoryLabel: categoryId, regionId: "telangana",
    createdAt: 1000, imageUrl: "https://example.com/poster.jpg", approved: true, ...overrides};
  return {id, data: () => data};
}
function collect(docs, extra = {}) {
  return collectPublishedCategoryPosters({query: queryFor(docs), pageSize: 2,
    isVisible: (data) => data.approved && !data.expired && !data.future,
    serialize: (doc) => ({...doc.data()}), ...extra});
}
test("empty collection produces no poster categories", async () => {
  assert.deepEqual(await collect([]), []);
});
test("discovers the only poster in a category beyond the first page", async () => {
  const result = await collect([poster("1", "a"), poster("2", "a"), poster("3", "b")]);
  assert.deepEqual(result.map((item) => item.categoryId), ["a", "b"]);
});
test("pending, future, expired and broken posters cannot expose a category", async () => {
  const result = await collect([poster("1", "pending", {approved: false}),
    poster("2", "future", {future: true}), poster("3", "expired", {expired: true}),
    poster("4", "broken", {imageUrl: ""}), poster("5", "valid")]);
  assert.deepEqual(result.map((item) => item.categoryId), ["valid"]);
});
test("deleting the last poster removes its category on the next snapshot", async () => {
  const docs = [poster("1", "a"), poster("2", "b")];
  assert.equal((await collect(docs)).length, 2);
  docs.pop();
  assert.deepEqual((await collect(docs)).map((item) => item.categoryId), ["a"]);
});
test("preserves representatives for different regions, labels and IST release days", async () => {
  const result = await collect([poster("1", "night", {createdAt: 17 * 3600000}),
    poster("2", "night", {createdAt: 20 * 3600000}),
    poster("3", "night", {regionId: "andhra_pradesh"}),
    poster("4", "night", {categoryLabel: "Other label"})]);
  assert.equal(result.length, 4);
});
test("failed later pages never report a partial list as complete", async () => {
  const docs = [poster("1", "a"), poster("2", "a"), poster("3", "b")];
  await assert.rejects(collect(docs, {query: queryFor(docs, 2)}), /Read interrupted/);
});

test("opening a category finds a published poster beyond scheduled first-page entries", async () => {
  const docs = [poster("1", "a", {future: true}), poster("2", "a", {future: true}), poster("3", "a")];
  const result = await collectPublishedPosterDocuments({query: queryFor(docs), pageSize: 2,
    isVisible: (data) => !data.future, limit: 1});
  assert.deepEqual(result.map((doc) => doc.id), ["3"]);
});

test("good-night availability follows the same next-IST-midnight release as the app", () => {
  const item = {categoryId: "good_night", createdAt: Date.parse("2026-10-08T10:00:00Z")};
  assert.equal(isGoodNightPosterReleased(item, Date.parse("2026-10-08T18:29:59Z")), false);
  assert.equal(isGoodNightPosterReleased(item, Date.parse("2026-10-08T18:30:00Z")), true);
  assert.equal(isGoodNightPosterReleased({...item, categoryId: "good_morning"}, item.createdAt), true);
});
