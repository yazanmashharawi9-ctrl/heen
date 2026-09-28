# حِين · Heen

**السنّة في لحظتها** — تطبيق صدقة جارية، مجاني بالكامل، بلا إعلانات ولا حسابات، ومفتوح المصدر.

يلتقط الجوال لحظات الحياة الحقيقية ويذكّرك بسنّتها: نزول المطر، الرعد، الريح، رؤية الهلال،
الأيام البيض، الكسوف الظاهر في بلدك، الخروج للسفر والعودة منه. كل نص يظهر مع مصدره ودرجته،
مع نطق لاتيني وشرح مبسّط للمسلم الجديد.

> «من دلّ على خير فله مثل أجر فاعله» — صحيح مسلم 1893

**Heen** — *the Sunnah in its moment.* A free, ad-free, account-free, open-source Islamic app
(sadaqah jariyah) that notices real moments — rain, thunder, the new crescent, the White Days,
an eclipse visible where you are, leaving on a journey and coming home — and shows the Sunnah for
that moment with its source and grading, a transliteration and a simple explanation for new Muslims.

## Repository layout

| Path | What |
|---|---|
| `content/` | The moments: one JSON file each, validated against `content/schema/moment.schema.json`. Licensed CC BY 4.0. |
| `app/` | Flutter app (Android + iOS). Arabic (RTL) and English. |
| `supabase/` | Backend: Postgres migrations and Edge Functions (`api`, `tick`, `send`). |
| `shared/test-vectors/` | Cases both the Dart app and the TypeScript backend are tested against. |
| `tools/content/` | Validate, format, build and review content. |
| `tools/asc/` | App Store Connect tooling — ship iOS from Windows (from the Tubes project). |
| `docs/` | Setup, shipping, content review. |

## Develop

Requirements: Flutter 3.44, Node 24. Docker only for the local Supabase stack.

```bash
npm ci                      # content tooling
npm run content:validate    # sources, gradings, review hashes
npm run content:build       # writes app/assets/content/moments.json (checked in)
npm test                    # TypeScript tests (content tools + backend modules)
npm run typecheck

cd app
flutter test
flutter run
```

## Content and review

No religious text ships without review. Every moment carries a `review` block; approving it
stamps a hash of the content, so any later edit sends it back for review, and release builds
refuse anything not approved. See [docs/content-review.md](docs/content-review.md).

## Privacy

No accounts, no ads, no analytics, no tracking. The phone never sends its location — only a
~25 km weather cell id, a push token and notification preferences.

## License

Code: MIT ([LICENSE](LICENSE)). Content: CC BY 4.0 ([content/LICENSE.md](content/LICENSE.md)).
