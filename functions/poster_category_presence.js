// Scan every page: a category's only published poster may be older than the feed page.
async function collectPublishedCategoryPosters({query, isVisible, serialize, pageSize = 250}) {
  const posters = [];
  const seen = new Set();
  let cursor;
  while (true) {
    const page = await (cursor ? query.startAfter(cursor) : query).limit(pageSize).get();
    for (const doc of page.docs) {
      const data = doc.data();
      if (!isVisible(data)) continue;
      const poster = serialize(doc);
      const hasMedia = (poster.mediaType === "video" && poster.videoUrl) ||
        poster.imageUrl || poster.imagePath || poster.thumbnailUrl || poster.thumbnailPath;
      if (!hasMedia) continue;
      // Preserve different labels, regions and release days (notably good-night posters).
      const releaseDay = Math.floor(((poster.publishAt || poster.createdAt) + 19800000) / 86400000);
      const key = JSON.stringify([poster.categoryId, poster.categoryLabel, poster.regionId,
        releaseDay, !poster.categoryId && !poster.categoryLabel ? poster.title : ""]);
      if (seen.has(key)) continue;
      seen.add(key);
      delete poster.personalizationConfig;
      posters.push(poster);
    }
    if (page.docs.length < pageSize) return posters;
    cursor = page.docs[page.docs.length - 1];
  }
}

async function collectPublishedPosterDocuments({query, isVisible, isRenderable = () => true, limit, pageSize = 250}) {
  const docs = [];
  let cursor;
  while (docs.length < limit) {
    const page = await (cursor ? query.startAfter(cursor) : query).limit(pageSize).get();
    for (const doc of page.docs) {
      if (isVisible(doc.data()) && isRenderable(doc)) docs.push(doc);
      if (docs.length === limit) return docs;
    }
    if (page.docs.length < pageSize) return docs;
    cursor = page.docs[page.docs.length - 1];
  }
  return docs;
}

function isGoodNightPosterReleased(poster, nowMillis) {
  const signals = [poster.categoryId || "", poster.categoryLabel || "",
    ...String(poster.categoryLabel || "").split(/\s+/)]
      .map((value) => String(value).toLowerCase().replace(/[\s_-]+/g, ""));
  if (!signals.some((value) => ["goodnight", "night", "ratri"].includes(value))) return true;

  // Instant uploads (published immediately without future schedule) should appear instantly
  const isInstantUpload = poster.createdBySurface === "app_posters" ||
    !poster.requestedPublishAt ||
    Number(poster.requestedPublishAt) <= 0 ||
    Math.abs(Number(poster.publishAt || 0) - Number(poster.createdAt || 0)) <= 120000;
  if (isInstantUpload) return true;

  const visibleFrom = poster.publishAt || poster.createdAt;
  if (!visibleFrom || visibleFrom <= 0) return true;
  const release = (Math.floor((visibleFrom + 19800000) / 86400000) + 1) * 86400000 - 19800000;
  return nowMillis >= release;
}

module.exports = {collectPublishedCategoryPosters, collectPublishedPosterDocuments, isGoodNightPosterReleased};
