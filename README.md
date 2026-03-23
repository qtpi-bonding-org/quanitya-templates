# Quanitya Templates

Pre-built tracker templates for [Quanitya](https://quanitya.com), a privacy-first self-tracking app.

Import any template with one tap. Make it yours — customize fields, colors, and analysis however you want.

## Templates

| Name | What it tracks |
|------|---------------|
| **Mood & Energy** | Daily mood and energy levels (1-10 sliders) |
| **Emotion** | How you're feeling right now (pick from 16 emotions) |
| **Sleep** | Hours slept, quality, how refreshed you feel |
| **Period** | Flow intensity, cramps, notes. Predicts your next cycle. |
| **Symptoms** | What hurts, how bad, and what triggered it |
| **Medication** | What you took, how much, whether you took it |
| **Weight** | Body weight over time |
| **Running** | Distance, duration |
| **Swimming** | Laps, duration |
| **Cycling** | Distance, duration |
| **Lifting** | Exercise, sets (weight/reps/RPE). Tracks volume over time. |
| **Food** | Calories, protein, carbs, fat |
| **Water** | Cups per day |
| **Meditated** | One tap — did you meditate today? |
| **Habit** | Name any habit and check it off |
| **Productivity** | Focus time (built-in timer), tasks completed |
| **Journal** | Free-form text entry |

## How to use

**From the app:** Browse templates by category, tap to preview, tap to import. Done.

**From this repo:** Copy the raw URL of any `template.json` file and paste it into the app's import field.

## Share your own

Made a template you love? Share it with the community.

1. **Export from the app** — go to your template, tap Share, and copy the JSON
2. **Fork this repo** and create a folder in `templates/` with a short name (e.g., `blood-pressure`)
3. **Save your export** as `template.json` in that folder
4. **Add an entry** to `catalog.json` with a name, description, emoji, and category
5. **Validate** — run `./validate.sh` to check the format (requires [jq](https://jqlang.github.io/jq/)). CI also runs this automatically on your PR.
6. **Submit a pull request**

Look at any existing template for reference — the Water template is the simplest.

### Tips for good templates

- **One thing per template.** Don't combine mood tracking with medication logging.
- **Clear field names.** "Severity" not "Rating". "Done" not "Completed (Y/N)".
- **Make notes optional.** Nobody wants to type something every single time.
- **Sensible ranges.** Mood 1-10 is standard. Pain 1-5 is enough.
- **Include analysis if you can.** Templates with built-in charts are more useful.

### Categories

Pick one: `health` · `fitness` · `nutrition` · `productivity` · `journaling`

### catalog.json entry

```json
{
  "slug": "your-template-name",
  "name": "Your Template",
  "description": "One sentence about what it tracks.",
  "emoji": "🎯",
  "category": "health",
  "tags": ["tag1", "tag2"],
  "fields_count": 3,
  "author": "your-name",
  "featured": false
}
```

## License

MIT — use these templates however you want.
