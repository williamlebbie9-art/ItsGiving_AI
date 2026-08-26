# Decide AI

Decide AI is a life decision assistant app.

This phase implements Products + Fashion first, with the full category framework in place:
- Food
- Travel
- Products
- Relationships
- Fashion

## Implemented Features

- Home screen with global question input
- Auto category routing (or manual category selection)
- Compare mode (up to 3 options)
- Structured decision output:
	- best_choice
	- alternatives
	- reasoning
	- pros
	- cons
	- confidence_score
	- category
- Outfit image picker input for fashion analysis context
- Local personalization storage (budget, location, preferences, style)
- Decision history (persisted locally)
- Share-ready result text (copy to clipboard)
- Light and dark themes with smooth UI transitions

## AI Provider Setup

The mobile app uses the Firebase provider only. Provider API keys stay in
Firebase Secrets / the Functions environment and must never be placed in the
mobile app's `.env` file.

1. Copy `.env.example` to `.env`
2. For local emulation, put provider keys in `functions/.secret.local`
3. Run `npm --prefix functions install`
4. Run `firebase emulators:start --only functions`

Example app `.env`:

```env
AI_PROVIDER=firebase
FIREBASE_FUNCTIONS_URL=
```

Example `functions/.env`:

```env
AI_PROVIDER=gemini
GEMINI_API_KEY=paste_your_key_here
GEMINI_MODEL=gemini-1.5-flash
OPENAI_API_KEY=
OPENAI_MODEL=gpt-4o-mini
AI_FUNCTION_REGION=us-central1
```

If the provider is unavailable, the app shows a retryable error and retains a
local fallback plan instead of blocking the onboarding journey.

## Run Locally

```bash
flutter pub get
flutter run
```

## Project Structure

```text
lib/
	app.dart
	main.dart
	core/
		models/
			decision_models.dart
		services/
			ai_client.dart
			category_router.dart
			decision_engine.dart
			decision_prompts.dart
		storage/
			history_repository.dart
			profile_repository.dart
	features/
		home/
			home_screen.dart
		history/
			history_screen.dart
		results/
			result_screen.dart
```

## Notes

- Products + Fashion are optimized first for rapid iteration.
- Food, Travel, and Relationships are already wired into routing and prompt systems and can be expanded next with deeper domain logic.
