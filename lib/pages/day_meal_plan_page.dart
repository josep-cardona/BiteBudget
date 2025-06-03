import 'package:flutter/material.dart';
import 'package:bitebudget/models/meal_plan.dart';
import 'package:bitebudget/services/database_service.dart';
import 'package:bitebudget/services/meal_plan_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bitebudget/models/recipe.dart';
import 'package:bitebudget/pages/recipe_page.dart';

class DayMealPlanPage extends StatefulWidget {
  final DayPlan dayPlan;
  final int dayIndex;
  final String weekPlanId;
  final DateTime weekMonday;
  final List<DayPlan> weekDays;

  const DayMealPlanPage({
    Key? key,
    required this.dayPlan,
    required this.dayIndex,
    required this.weekPlanId,
    required this.weekMonday,
    required this.weekDays,
  }) : super(key: key);

  @override
  State<DayMealPlanPage> createState() => _DayMealPlanPageState();
}

class _DayMealPlanPageState extends State<DayMealPlanPage> {
  late DayPlan _dayPlan;
  bool _updating = false;
  bool _loadingRecipes = true;
  Map<String, Recipe> _recipeMap = {};

  @override
  void initState() {
    super.initState();
    _dayPlan = widget.dayPlan;
    _fetchRecipes();
  }

  Future<void> _fetchRecipes() async {
    final service = DatabaseService_Recipe();
    final names = [
      _dayPlan.breakfast,
      _dayPlan.lunch,
      _dayPlan.snack,
      _dayPlan.dinner
    ].whereType<String>().toList();
    final map = await service.getRecipesByNames(names);
    setState(() {
      _recipeMap = map;
      _loadingRecipes = false;
    });
  }

  Future<void> _editRecipe(String mealType) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => RecipePickerDialog(mealType: mealType),
    );
    if (selected != null) {
      setState(() { _updating = true; });
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final mealPlanService = DatabaseServiceMealPlan();
      final updatedDay = DayPlan(
        breakfast: mealType == 'breakfast' ? selected : _dayPlan.breakfast,
        lunch: mealType == 'lunch' ? selected : _dayPlan.lunch,
        snack: mealType == 'snack' ? selected : _dayPlan.snack,
        dinner: mealType == 'dinner' ? selected : _dayPlan.dinner,
      );
      final updatedWeek = List<DayPlan>.from(widget.weekDays);
      updatedWeek[widget.dayIndex] = updatedDay;
      await mealPlanService.updateMealPlan(
        MealPlan(
          id: widget.weekPlanId,
          startDate: widget.weekMonday,
          endDate: widget.weekMonday.add(const Duration(days: 6)),
          days: updatedWeek,
        ),
        user.uid,
      );
      setState(() {
        _dayPlan = updatedDay;
      });
      await _fetchRecipes(); // Refetch recipes to update images and UI
      setState(() {
        _updating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recipe updated!')));
      // Do NOT pop here. Let user go back manually.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Main content (cards, text, etc)
          Positioned.fill(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(top: 40, left: 0, right: 0, bottom: 0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    DayMealPlanHeader(dayIndex: widget.dayIndex, weekMonday: widget.weekMonday),
                    const SizedBox(height: 18),
                    if (_updating || _loadingRecipes)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      DayMealCard(
                        label: 'Breakfast',
                        recipeName: _dayPlan.breakfast,
                        mealType: 'breakfast',
                        recipe: _dayPlan.breakfast != null ? _recipeMap[_dayPlan.breakfast!] : null,
                        onEdit: () => _editRecipe('breakfast'),
                      ),
                      DayMealCard(
                        label: 'Lunch',
                        recipeName: _dayPlan.lunch,
                        mealType: 'lunch',
                        recipe: _dayPlan.lunch != null ? _recipeMap[_dayPlan.lunch!] : null,
                        onEdit: () => _editRecipe('lunch'),
                      ),
                      DayMealCard(
                        label: 'Snack',
                        recipeName: _dayPlan.snack,
                        mealType: 'snack',
                        recipe: _dayPlan.snack != null ? _recipeMap[_dayPlan.snack!] : null,
                        onEdit: () => _editRecipe('snack'),
                      ),
                      DayMealCard(
                        label: 'Dinner',
                        recipeName: _dayPlan.dinner,
                        mealType: 'dinner',
                        recipe: _dayPlan.dinner != null ? _recipeMap[_dayPlan.dinner!] : null,
                        onEdit: () => _editRecipe('dinner'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // Small gradient overlay at the very top (fadeout effect, always above content)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 80, // Make the gradient much smaller
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color.fromARGB(0, 255, 255, 255),
                      Colors.white,
                    ],
                    stops: [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // Fixed back arrow with padding from top and left
          Positioned(
            top: 18,
            left: 10,
            child: SafeArea(
              bottom: false,
              child: Container(
                width: 41,
                height: 41,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadows: [
                    BoxShadow(
                      color: Color.fromARGB(44, 5, 51, 54),
                      blurRadius: 16,
                      offset: Offset(0, 2),
                      spreadRadius: 0,
                    )
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.black),
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: ButtonStyle(
                    overlayColor: MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.hovered)) {
                          return Colors.grey.withOpacity(0.2);
                        }
                        return null;
                      },
                    ),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.zero),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DayMealPlanHeader extends StatelessWidget {
  final int dayIndex;
  final DateTime weekMonday;
  const DayMealPlanHeader({Key? key, required this.dayIndex, required this.weekMonday}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final date = weekMonday.add(Duration(days: dayIndex));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            dayNames[dayIndex],
            style: const TextStyle(
              color: Colors.black,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontVariations: [FontVariation('wght', 700)],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${date.day}/${date.month}/${date.year}',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class DayMealCard extends StatelessWidget {
  final String label;
  final String? recipeName;
  final String mealType;
  final Recipe? recipe;
  final VoidCallback onEdit;
  const DayMealCard({
    Key? key,
    required this.label,
    required this.recipeName,
    required this.mealType,
    required this.recipe,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 380,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0x19053336),
                blurRadius: 16,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: recipe != null
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RecipePage(recipe: recipe!),
                      ),
                    );
                  }
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    if (recipe?.image_url != null && recipe!.image_url!.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                        child: Image.network(
                          recipe!.image_url!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 160,
                            color: Colors.grey[200],
                            child: const Icon(Icons.fastfood, size: 60, color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF2F2F2),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(28),
                            topRight: Radius.circular(28),
                          ),
                        ),
                        child: const Icon(Icons.fastfood, size: 60, color: Colors.grey),
                      ),
                    // Time needed at top right with fade gradient
                    if (recipe != null)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          height: 48,
                          width: 140, // Even wider to the left
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [
                                Colors.black87, // Darker gradient
                                Colors.transparent,
                              ],
                            ),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(28),
                              bottomLeft: Radius.circular(18),
                            ),
                          ),
                          alignment: Alignment.topLeft, // Move content to the left
                          padding: const EdgeInsets.only(top: 10, left: 40, right: 10, bottom: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start, // Align left
                            children: [
                              const Icon(Icons.access_time, color: Color(0xFFD1D1D1), size: 24),
                              const SizedBox(width: 4),
                              Text(
                                '${recipe!.time.toStringAsFixed(0)} min',
                                style: const TextStyle(
                                  color: Color(0xFFD1D1D1),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  shadows: [Shadow(blurRadius: 2, color: Colors.black12)],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                // Fully rounded white container below image
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  transform: Matrix4.translationValues(0, -18, 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 26, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ElevatedButton(
                            onPressed: onEdit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              elevation: 0,
                            ),
                            child: const Text('Edit'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(recipeName ?? '-', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 18),
                      // Centered property labels at the bottom with margin
                      if (recipe != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 5, bottom: 0),
                          child: Column(
                            children: [
                          SizedBox(height: 30,),
                          Row(
                            children: [
                              Text(
                                '${recipe!.price}€',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    height: 1.40,
                                ),
                              ),
                              SizedBox(width: 4,),
                              Text(
                                '/ ration',
                                style: TextStyle(
                                    color: Colors.black.withValues(alpha: 128) /* ✦-_text-text-secondary */,
                                    fontSize: 12,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    height: 1.83,
                                ),
                            ),
                            SizedBox(width: 55,),

                            Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              _PropertyText(
                                icon: Icons.local_fire_department,
                                label: '${recipe!.calories.toStringAsFixed(0)} kcal',
                                color: Colors.black.withValues(alpha: 128),
                              ),
                              const SizedBox(width: 18),
                              _PropertyText(
                                icon: Icons.fitness_center,
                                label: '${recipe!.protein.toStringAsFixed(0)}g protein',
                                color: Colors.black.withValues(alpha: 128),
                              ),

                            ],
                            
                          ),

                          ],
                          )
                            ],
                          )
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      )
    );
    }
}

class _PropertyText extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _PropertyText({Key? key, required this.icon, required this.label, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class RecipePickerDialog extends StatefulWidget {
  final String mealType;
  const RecipePickerDialog({Key? key, required this.mealType}) : super(key: key);

  @override
  State<RecipePickerDialog> createState() => _RecipePickerDialogState();
}

class _RecipePickerDialogState extends State<RecipePickerDialog> {
  List<Recipe> _recipes = [];
  List<Recipe> _filtered = [];
  bool _loading = true;
  String? _selectedType;
  String? _selectedDiet;

  List<String> get _allTypes {
    final types = <String>{};
    for (final r in _recipes) {
      types.addAll(r.type);
    }
    return types.toList()..sort();
  }

  List<String> get _allDiets {
    final diets = <String>{};
    for (final r in _recipes) {
      diets.add(r.diet);
    }
    return diets.toList()..sort();
  }

  void _applyFilters({String? search}) {
    setState(() {
      _filtered = _recipes.where((r) {
        final matchesType = _selectedType == null || r.type.contains(_selectedType!);
        final matchesDiet = _selectedDiet == null || r.diet == _selectedDiet;
        final matchesSearch = search == null || r.name.toLowerCase().contains(search.toLowerCase());
        return matchesType && matchesDiet && matchesSearch;
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  Future<void> _fetchRecipes() async {
    final service = DatabaseService_Recipe();
    final all = await service.getAllRecipes();
    setState(() {
      _recipes = all;
      _filtered = all;
      _loading = false;
      _selectedType = null;
      _selectedDiet = null;
    });
  }

  void _search(String q) {
    _applyFilters(search: q);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Recipe for ${widget.mealType}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(hintText: 'Search recipes...'),
                onChanged: _search,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _selectedType,
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('All Types')),
                        ..._allTypes.map((type) => DropdownMenuItem<String?>(value: type, child: Text(type)))
                      ],
                      onChanged: (val) {
                        setState(() => _selectedType = val);
                        _applyFilters();
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8F8F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      ),
                      dropdownColor: const Color(0xFFF8F8F8),
                      style: const TextStyle(color: Colors.black, fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: _selectedDiet,
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('All Diets')),
                        ..._allDiets.map((diet) => DropdownMenuItem<String?>(value: diet, child: Text(diet)))
                      ],
                      onChanged: (val) {
                        setState(() => _selectedDiet = val);
                        _applyFilters();
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8F8F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      ),
                      dropdownColor: const Color(0xFFF8F8F8),
                      style: const TextStyle(color: Colors.black, fontSize: 15),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _loading
                  ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
                  : SizedBox(
                      height: 340,
                      width: 360,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16), // Match card radius
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          clipBehavior: Clip.hardEdge, // Ensure both card and shadow are clipped
                          physics: const BouncingScrollPhysics(),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, idx) {
                            final recipe = _filtered[idx];
                            return _HorizontalRecipeCard(recipe: recipe);
                          },
                        ),
                      ),
                    ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      elevation: 0,
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      )
    );
  }
}

class _HorizontalRecipeCard extends StatelessWidget {
  final Recipe recipe;
  const _HorizontalRecipeCard({Key? key, required this.recipe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // Remove clipBehavior here so shadow is not cut off by the card itself
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0x19053336),
            blurRadius: 18, // More spread, softer
            offset: Offset(0, 6), // Move shadow towards center (down)
            spreadRadius: -6, // Negative spread to keep shadow inside, oval look
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (recipe.image_url != null && recipe.image_url!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: Image.network(
                recipe.image_url!,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: const Icon(Icons.fastfood, size: 32, color: Colors.grey),
                ),
              ),
            )
          else
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFF2F2F2),
                borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
              ),
              child: const Icon(Icons.fastfood, size: 32, color: Colors.grey),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _BottomInfoText(text: '${recipe.calories.toStringAsFixed(0)} kcal'),
                      const SizedBox(width: 12),
                      _BottomInfoText(text: '${recipe.protein.toStringAsFixed(0)}g protein'),
                      const SizedBox(width: 12),
                      _BottomInfoText(text: '${recipe.price.toStringAsFixed(2)} €'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomInfoText extends StatelessWidget {
  final String text;
  const _BottomInfoText({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF97A1B0),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
