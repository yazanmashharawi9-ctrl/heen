# مراجعة المحتوى الشرعي · Content review

لا يُنشر أي نص شرعي قبل أن يراجعه شخص مؤهل. هذا شرط، لا خطوة اختيارية.

No religious text ships before a qualified person has reviewed it.

## ما الذي يراجعه المراجِع

لكل لحظة (ملف في `content/moments/`):

1. **النص العربي** مطابق للرواية، ومشكول تشكيلًا صحيحًا.
2. **المصدر**: اسم الكتاب ورقم الحديث صحيحان، والرابط يوصل إليه.
3. **الدرجة**: الحكم على الحديث ومن حكم به. الأثر الموقوف على صحابي يُذكر أنه أثر لا حديث.
4. **ملاءمة اللحظة**: أن تكون السنّة فعلًا لهذه اللحظة (مثلًا دعاء المطر عند نزول المطر).
5. **الشرح** و**شرح المسلم الجديد**: صحيحان ولا يزيدان على ما في المصادر.
6. **المسائل الفقهية**: القول العام صحيح، والخلاف منسوب إلى أهله بدقة.
7. **الترجمة الإنجليزية** والنطق اللاتيني.
8. **نص الإشعار**: لا يَعِد بشيء ولا يجزم بما لا نعلم (نقول «يبدو أن المطر ينزل»).

## Sending the texts to the reviewer

```bash
npm run content:review-sheet     # every moment not yet approved
```

This writes `build/review/heen-review.pdf` (and `.html`): numbered items with the
exact Arabic, sources with links, gradings, explanations and fiqh notes, and a
tick box under each. The reviewer replies with the item number, e.g. «3.1 موافق»
or «5.2 ملاحظة: …». Narrator and grader names come from `content/glossary.json`.

## How approval works

```bash
npm run content:review -- list
npm run content:review -- status weather.rain_start in_review
npm run content:review -- status weather.rain_start changes_requested --notes "…"
npm run content:review -- approve weather.rain_start --reviewer "<name>"
```

`approve` records the reviewer, the date and a sha256 hash of the whole moment
(everything except the review block). The validator recomputes it on every run:

- edited after approval → error, back to review;
- release builds (`--release`) refuse any moment that is not approved.

Approvals are committed like any other change, so the history shows who approved
what and when.

## Grading rules enforced by the validator

- Every non-Qur'an source needs at least one grading (`grade` + `by`).
- A du'a or dhikr whose best grading is da'if is rejected unless it is explicitly
  marked `showAsWeak`, and then the app labels it as weak.
- Du'a, dhikr and Qur'an text must be vocalised.
