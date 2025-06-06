# BiteBudget

Eat Healthier, 

Eat Cheaper,

Eat BiteBudget

**BiteBudget** is a cross-platform meal planning app that helps users discover, plan, and enjoy healthy, affordable meals tailored to their dietary preferences and budget.

---

## What is BiteBudget?

**BiteBudget makes healthy eating easy and affordable.**  
Users can set their dietary preferences and budget, explore a curated library of recipes (with calories, protein, and price per serving), and generate meal plans that fit their goals. The app is designed for discovery and engagement, making meal planning social, fun, and accessible.

---

## How the App Works

- **Sign Up & Profile:** Users register and set dietary, nutritional, and budget preferences.
- **Personalized Recipes:** The app recommends recipes based on user settings, showing calories, protein, and estimated cost per serving.
- **Meal Planning:** Users can generate their smart meal plan, which adapts to their preferences. If there is some meal that is desired to be replaced, users can do so by editing it and using the smart filtering.
- **Admin Tools:** (For development) Recipes can be batch-uploaded from JSON files.

---

## Compatibility

- **Platforms:**  
  - Android  
  - iOS  
  - Web (Chrome, Firefox, Edge, Safari)
- **Tech Stack:**  
  - Flutter (Dart)  
  - Firebase (Firestore, Auth, Storage)

---

## Main Files & Structure

- `lib/main.dart` – App entry point
- `lib/models/recipe.dart` – Recipe data model
- `lib/models/recipe_uploader.dart` – Batch recipe upload logic (for admin/dev use)
- `lib/services/database_service.dart` – Firestore integration
- `lib/pages/` – All UI pages, including registration, profile, home, and recipe details
- `assets/` – Images, icons, and sample recipe JSON files

---

## Getting Started

1. **Clone the repo:**  
   `git clone https://github.com/yourusername/bitebudget.git`
2. **Install dependencies:**  
   `flutter pub get`
3. **Run the app:**  
   - For web: `flutter run -d chrome`
   - For mobile: `flutter run`

---

## Developed by
Josep Cardona & Elena Andreev with help of Copilot.
