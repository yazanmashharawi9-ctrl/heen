// Builds the review sheet a scholar reads: every moment not yet approved,
// numbered, with the exact Arabic text, sources, gradings, explanations and
// fiqh notes, plus a box to tick or annotate. Output is HTML, then PDF via
// headless Chrome (which shapes Arabic and tashkeel correctly).
//
//   node tools/content/review-sheet.ts            # all moments not approved
//   node tools/content/review-sheet.ts --all      # every moment
//
// Writes build/review/heen-review.html and .pdf. Reply format for the
// reviewer: "3.1 موافق" or "3.1 ملاحظة: …" — the numbers map back to ids.

import { existsSync, mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { spawnSync } from "node:child_process";
import { pathToFileURL } from "node:url";
import { ROOT, loadMoments, loadPeople, type Json } from "./lib.ts";

type Obj = { [key: string]: Json };
const obj = (v: Json | undefined): Obj => (v && typeof v === "object" && !Array.isArray(v) ? v : {});
const arr = (v: Json | undefined): Json[] => (Array.isArray(v) ? v : []);
const str = (v: Json | undefined): string => (typeof v === "string" ? v : "");
const esc = (s: string) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");

const COLLECTIONS: Record<string, string> = {
  quran: "القرآن الكريم", bukhari: "صحيح البخاري", muslim: "صحيح مسلم", abudawud: "سنن أبي داود",
  tirmidhi: "سنن الترمذي", nasai: "سنن النسائي", ibnmajah: "سنن ابن ماجه", ahmad: "مسند أحمد",
  malik: "موطأ مالك", darimi: "سنن الدارمي", adab_mufrad: "الأدب المفرد", bayhaqi: "البيهقي",
  hakim: "المستدرك", ibnhibban: "صحيح ابن حبان", other: "مصدر آخر",
};
const GRADES: Record<string, string> = {
  sahih: "صحيح", hasan: "حسن", sahih_li_ghayrihi: "صحيح لغيره", hasan_li_ghayrihi: "حسن لغيره", daif: "ضعيف",
};
const TYPES: Record<string, string> = { marfu: "مرفوع", mawquf: "موقوف (أثر صحابي)", maqtu: "مقطوع (أثر تابعي)", quran: "آية" };
const KINDS: Record<string, string> = { dua: "دعاء", dhikr: "ذكر", practice: "سنّة عملية", quran: "آية", info: "بيان" };
const MADHHABS: Record<string, string> = { hanafi: "الحنفية", maliki: "المالكية", shafii: "الشافعية", hanbali: "الحنابلة" };
const CATEGORIES: Record<string, string> = { weather: "الطقس", calendar: "التقويم", sky: "السماء", travel: "السفر", place: "الأماكن" };
const WHEN: Record<string, string> = {
  RAIN_START: "عند بداية نزول المطر في منطقة المستخدم",
  RAIN_FIRST_OF_SEASON: "مع أول مطرٍ بعد موسمٍ جاف",
  RAIN_AFTER: "بعد توقّف المطر",
  RAIN_HEAVY: "عند المطر الغزير",
  THUNDER: "عند الرعد",
  WIND_STRONG: "عند الرياح الشديدة",
  SNOW: "عند تساقط الثلج",
  HEAT: "صباح يومٍ شديد الحرّ",
  COLD: "صباح يومٍ شديد البرد",
  MONTH_START: "مساء آخر يومٍ من الشهر الهجري (ليلة رؤية الهلال)",
  AYYAM_AL_BID: "مساء الثاني عشر من كل شهرٍ هجري",
  ARAFAH: "مساء الثامن من ذي الحجة",
  TASUA_ASHURA: "قبل التاسع من محرّم",
  DHUL_HIJJAH_TEN: "أول ذي الحجة",
  SHAWWAL_SIX: "الثاني من شوّال",
  LAST_TEN_NIGHTS: "ليلة الحادي والعشرين من رمضان",
  RAMADAN_START: "أول رمضان",
  LEAVING: "عند خروج المستخدم من مدينته",
  TRAVELER: "عند تجاوزه مسافة القصر التي اختارها",
  STAY_CHECK: "بعد أربعة أيام من سفره",
  RETURNING: "عند عودته إلى مدينته",
  solar: "عند بدء كسوفٍ ظاهرٍ في موقع المستخدم",
  lunar: "عند بدء خسوفٍ ظاهرٍ في موقع المستخدم",
  mosque: "عند وصوله إلى مسجد (ميزة لاحقة)",
  cemetery: "عند مروره بمقبرة (ميزة لاحقة)",
  fastLength: "مساء قبل أقصر أيام السنة في مدينة المستخدم",
};

function when(trigger: Obj): string {
  const type = str(trigger.type);
  if (type === "weekday") {
    const days = arr(trigger.days).map(Number);
    if (days.includes(5)) return "يوم الجمعة، في آخر ساعةٍ قبل المغرب";
    return "مساء الأحد ومساء الأربعاء (قبل الاثنين والخميس)";
  }
  if (type === "fastLength") return WHEN.fastLength;
  return WHEN[str(trigger.event) || str(trigger.rule) || str(trigger.kind)] ?? type;
}

const PEOPLE = loadPeople();
const name = (n: string) => PEOPLE[n] ?? n;

function sources(list: Json[]): string {
  return `<ul class="sources">${list.map((s) => {
    const o = obj(s);
    const grades = arr(o.grades).map((g) => {
      const x = obj(g);
      return `${GRADES[str(x.grade)] ?? str(x.grade)} — ${esc(name(str(x.by)))}${x.note ? ` (${esc(str(x.note))})` : ""}`;
    });
    const url = str(o.url);
    return `<li><b>${COLLECTIONS[str(o.collection)] ?? esc(str(o.collection))} ${esc(str(o.number))}</b>`
      + (o.narrator ? ` · الراوي: ${esc(name(str(o.narrator)))}` : "")
      + ` · ${TYPES[str(o.type)] ?? ""}`
      + (grades.length ? `<br>الحكم: ${grades.join("، ")}` : "")
      + (o.note ? `<br>${esc(str(o.note))}` : "")
      + (url ? `<br><a href="${esc(url)}" dir="ltr">${esc(url)}</a>` : "")
      + `</li>`;
  }).join("")}</ul>`;
}

const all = process.argv.includes("--all");
const moments = loadMoments()
  .map((m) => m.data)
  .filter((m) => all || str(obj(m.review).status) !== "approved");

// Same order as the app's Library (app/lib/content/ordering.dart).
const CATEGORY_ORDER = ["weather", "calendar", "sky", "travel", "place"];
const TRIGGER_ORDER = [
  "RAIN_START", "RAIN_FIRST_OF_SEASON", "RAIN_AFTER", "RAIN_HEAVY", "THUNDER", "WIND_STRONG", "SNOW", "HEAT", "COLD",
  "MONTH_START", "RAMADAN_START", "LAST_TEN_NIGHTS", "SHAWWAL_SIX", "DHUL_HIJJAH_TEN", "ARAFAH", "TASUA_ASHURA",
  "AYYAM_AL_BID", "weekday:5", "weekday:1", "fastLength", "solar", "lunar",
  "LEAVING", "TRAVELER", "STAY_CHECK", "RETURNING", "mosque", "cemetery",
];
function rank(m: Obj): number {
  const t = obj(m.trigger);
  const type = str(t.type);
  const key = type === "weekday" ? `weekday:${arr(t.days)[0] ?? 0}`
    : type === "fastLength" ? "fastLength"
    : str(t.event) || str(t.rule) || str(t.kind);
  const i = TRIGGER_ORDER.indexOf(key);
  return i < 0 ? TRIGGER_ORDER.length : i;
}
moments.sort((a, b) =>
  CATEGORY_ORDER.indexOf(str(a.category)) - CATEGORY_ORDER.indexOf(str(b.category)) ||
  rank(a) - rank(b) ||
  str(a.id).localeCompare(str(b.id)));

let body = "";
moments.forEach((m, i) => {
  const n = i + 1;
  const title = obj(m.title);
  const push = obj(m.push);
  const review = obj(m.review);
  body += `<section><h2>${n}. ${esc(str(title.ar))} <small>(${CATEGORIES[str(m.category)] ?? ""} · ${esc(str(m.id))})</small></h2>`;
  body += `<p class="meta"><b>متى يظهر:</b> ${esc(when(obj(m.trigger)))}</p>`;
  body += `<p class="meta"><b>نص الإشعار:</b> ${esc(str(obj(push.title).ar))} — ${esc(str(obj(push.body).ar))}</p>`;
  if (review.notes) body += `<p class="note"><b>ملاحظة للمراجع:</b> ${esc(str(review.notes))}</p>`;
  arr(m.items).forEach((it, j) => {
    const item = obj(it);
    body += `<div class="item"><h3>${n}.${j + 1} — ${KINDS[str(item.kind)] ?? ""}</h3>`;
    body += `<p class="arabic">${esc(str(item.ar))}</p>`;
    if (item.quote) body += `<p class="quote">«${esc(str(item.quote)).replace(/^«|»$/g, "")}»</p>`;
    body += sources(arr(item.sources));
    body += `<p><b>الشرح:</b> ${esc(str(obj(item.explain).ar))}</p>`;
    if (item.newMuslim) body += `<p><b>للمسلم الجديد:</b> ${esc(str(obj(item.newMuslim).ar))}</p>`;
    body += `<p class="tick">☐ موافق &nbsp;&nbsp; ☐ يحتاج تعديل: ..............................................................</p></div>`;
  });
  arr(m.fiqh).forEach((f, k) => {
    const note = obj(f);
    body += `<div class="item fiqh"><h3>${n}.ف${k + 1} — مسألة فقهية: ${esc(str(obj(note.topic).ar))}</h3>`;
    body += `<p><b>القول العام:</b> ${esc(str(obj(note.majority).ar))}</p>`;
    for (const d of arr(note.differences)) {
      const x = obj(d);
      body += `<p><b>${MADHHABS[str(x.madhhab)] ?? esc(str(x.madhhab))}:</b> ${esc(str(obj(x.text).ar))}</p>`;
    }
    if (arr(note.sources).length) body += sources(arr(note.sources));
    body += `<p class="tick">☐ موافق &nbsp;&nbsp; ☐ يحتاج تعديل: ..............................................................</p></div>`;
  });
  body += `</section>`;
});

const today = new Date().toISOString().slice(0, 10);
const html = `<!doctype html>
<html lang="ar" dir="rtl"><head><meta charset="utf-8">
<title>حِين — مراجعة الأدعية والأذكار</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Amiri:wght@400;700&family=Noto+Naskh+Arabic:wght@400;700&display=swap" rel="stylesheet">
<style>
  @page { size: A4; margin: 16mm 14mm; }
  body { font-family: "Noto Naskh Arabic", "Sakkal Majalla", "Traditional Arabic", serif; font-size: 12.5pt; line-height: 1.75; color: #1b1b1b; }
  h1 { font-size: 20pt; margin: 0 0 4pt; color: #1f6f5c; }
  h2 { font-size: 15pt; margin: 18pt 0 4pt; color: #1f6f5c; border-bottom: 1.5pt solid #1f6f5c; padding-bottom: 2pt; }
  h2 small { font-size: 9pt; color: #777; font-weight: normal; }
  h3 { font-size: 12pt; margin: 8pt 0 2pt; }
  .arabic { font-family: "Amiri", "Traditional Arabic", serif; font-size: 19pt; line-height: 2.1; text-align: center; margin: 6pt 0; }
  .quote { font-family: "Amiri", "Traditional Arabic", serif; font-size: 13.5pt; background: #f3f6f4; padding: 6pt 10pt; border-radius: 6pt; }
  .sources { font-size: 10.5pt; color: #333; margin: 4pt 0; padding-inline-start: 18pt; }
  .sources a { color: #1f6f5c; font-size: 9pt; }
  .meta { font-size: 11pt; margin: 2pt 0; }
  .note { background: #fff4e0; padding: 6pt 10pt; border-radius: 6pt; }
  .item { break-inside: avoid; border: 0.8pt solid #d8e2dd; border-radius: 8pt; padding: 6pt 12pt; margin: 8pt 0; }
  .fiqh { background: #fafafa; }
  .tick { font-size: 11pt; color: #444; margin-top: 6pt; }
  .intro { background: #eef5f2; border-radius: 8pt; padding: 10pt 14pt; }
  section { break-before: auto; }
</style></head><body>
<h1>حِين — مراجعة الأدعية والأذكار</h1>
<p>نسخة المراجعة بتاريخ ${today} · عدد اللحظات: ${moments.length}</p>
<div class="intro">
<p>جزاكم الله خيرًا على المراجعة. «حِين» تطبيق مجاني صدقةً جارية، يذكّر المسلم بالسنّة في لحظتها. لن يُنشر أي نصٍّ قبل موافقتكم.</p>
<p><b>المطلوب التأكد منه في كل بند:</b> صحة النص العربي وتشكيله · صحة المصدر ورقم الحديث · الحكم على الحديث · مناسبة السنّة لهذه اللحظة · صحة الشرح والمسائل الفقهية.</p>
<p><b>طريقة الرد:</b> يكفي رقم البند مع «موافق» أو الملاحظة، مثل: «3.1 موافق» أو «5.2 ملاحظة: …». ويمكن أيضًا أن تكتبوا «الكل موافق عدا …».</p>
<p>الروابط تفتح الحديث في موقع sunnah.com للتحقق السريع. (الترجمة الإنجليزية تُراجَع لاحقًا بشكلٍ منفصل.)</p>
</div>
${body}
</body></html>`;

const outDir = join(ROOT, "build", "review");
mkdirSync(outDir, { recursive: true });
const htmlPath = join(outDir, "heen-review.html");
writeFileSync(htmlPath, html, "utf8");
console.log(`wrote ${moments.length} moments to build/review/heen-review.html`);

const chromes = [
  process.env.CHROME_PATH,
  "C:/Program Files/Google/Chrome/Application/chrome.exe",
  "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe",
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
  "/usr/bin/google-chrome",
].filter((p): p is string => Boolean(p) && existsSync(p!));
if (chromes.length) {
  const pdfPath = join(outDir, "heen-review.pdf");
  const run = spawnSync(chromes[0], [
    "--headless=new", "--disable-gpu", "--no-pdf-header-footer", "--virtual-time-budget=15000",
    `--print-to-pdf=${pdfPath}`, pathToFileURL(htmlPath).href,
  ], { encoding: "utf8" });
  if (run.status === 0 && existsSync(pdfPath)) console.log("wrote build/review/heen-review.pdf");
  else console.error("PDF step failed:", run.stderr || run.error);
} else {
  console.log("Chrome not found — open the HTML and print it to PDF.");
}
