import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bitebudget/services/database_service.dart';
import 'dart:math';
import '../models/meal_plan.dart';
import '../services/meal_plan_service.dart';
import 'day_meal_plan_page.dart';

class MealPlanPage extends StatefulWidget {
  const MealPlanPage({Key? key}) : super(key: key);

  @override
  State<MealPlanPage> createState() => _MealPlanPageState();
}

class _MealPlanPageState extends State<MealPlanPage> {
  MealPlan? _mealPlan;
  bool _loading = true;
  DateTime _currentMonday = _getMondayOf(DateTime.now());
  Map<int, Map<String, double>> _dayTotals = {};

  static DateTime _getMondayOf(DateTime date) {
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    _fetchMealPlanForWeek(_currentMonday);
  }

  Future<void> _fetchMealPlanForWeek(DateTime monday) async {
    setState(() { _loading = true; });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() { _loading = false; });
      return;
    }
    final service = DatabaseServiceMealPlan();
    final plan = await service.getMealPlanForWeek(user.uid, monday);
    setState(() {
      _mealPlan = plan;
      _dayTotals.clear(); // Clear previous totals before recomputing
    });
    await _computeDayTotals();
    if (mounted) setState(() { _loading = false; }); // Only set loading to false after totals are computed
  }

  Future<void> _computeDayTotals() async {
    if (_mealPlan == null) return;
    final recipeService = DatabaseService_Recipe();
    for (int i = 0; i < _mealPlan!.days.length; i++) {
      final day = _mealPlan!.days[i];
      final names = [day.breakfast, day.lunch, day.snack, day.dinner].whereType<String>().toList();
      final recipes = await recipeService.getRecipesByNames(names);
      double calories = 0, protein = 0, price = 0;
      for (var name in names) {
        final r = recipes[name];
        if (r != null) {
          calories += r.calories;
          protein += r.protein;
          price += r.price;
        }
      }
      _dayTotals[i] = {
        'calories': calories,
        'protein': protein,
        'price': price,
      };
    }
    if (mounted) setState(() {});
  }

  Future<void> _generateMealPlanForWeek(DateTime monday) async {
    setState(() { _loading = true; });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final recipeService = DatabaseService_Recipe();
    final mealPlanService = DatabaseServiceMealPlan();
    final allRecipes = await recipeService.getAllRecipes();
    if (allRecipes.isEmpty) {
      setState(() { _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No recipes available.')));
      return;
    }
    final random = Random();
    List<DayPlan> days = List.generate(7, (dayIdx) {
      String? pickRandom() => allRecipes[random.nextInt(allRecipes.length)].name;
      return DayPlan(
        breakfast: pickRandom(),
        lunch: pickRandom(),
        snack: pickRandom(),
        dinner: pickRandom(),
      );
    });
    final mealPlan = MealPlan(
      id: '',
      startDate: monday,
      endDate: monday.add(const Duration(days: 6)),
      days: days,
    );
    await mealPlanService.addMealPlan(mealPlan, user.uid);
    await _fetchMealPlanForWeek(monday);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meal plan generated!')));
  }

  Future<void> _regenerateMealPlanForWeek(DateTime monday) async {
    setState(() { _loading = true; });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final recipeService = DatabaseService_Recipe();
    final mealPlanService = DatabaseServiceMealPlan();
    final allRecipes = await recipeService.getAllRecipes();
    if (allRecipes.isEmpty) {
      setState(() { _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No recipes available.')));
      return;
    }
    final random = Random();
    List<DayPlan> days = List.generate(7, (dayIdx) {
      String? pickRandom() => allRecipes[random.nextInt(allRecipes.length)].name;
      return DayPlan(
        breakfast: pickRandom(),
        lunch: pickRandom(),
        snack: pickRandom(),
        dinner: pickRandom(),
      );
    });
    // Find the plan for this week
    final plan = await mealPlanService.getMealPlanForWeek(user.uid, monday);
    if (plan != null) {
      final updatedPlan = MealPlan(
        id: plan.id,
        startDate: monday,
        endDate: monday.add(const Duration(days: 6)),
        days: days,
      );
      await mealPlanService.updateMealPlan(updatedPlan, user.uid);
      await _fetchMealPlanForWeek(monday);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meal plan regenerated!')));
    }
  }

  Future<void> _deleteMealPlanForWeek(DateTime monday) async {
    setState(() { _loading = true; });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final mealPlanService = DatabaseServiceMealPlan();
    final plan = await mealPlanService.getMealPlanForWeek(user.uid, monday);
    if (plan != null) {
      await mealPlanService.deleteMealPlan(plan.id, user.uid);
    }
    await _fetchMealPlanForWeek(monday);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meal plan deleted!')));
  }

  double _getTotal(String type, int dayIdx) {
    return _dayTotals[dayIdx]?[type] ?? 0.0;
  }

  void _changeWeek(int offset) {
    if (_loading) return; // Prevent changing week while loading
    setState(() {
      _currentMonday = _currentMonday.add(Duration(days: 7 * offset));
      _dayTotals.clear(); // Clear totals when changing week
    });
    _fetchMealPlanForWeek(_currentMonday);
  }

  // --- UI Helper Widgets ---
  Widget _buildWeekSelector(DateTime weekStart, DateTime weekEnd, DateTime currentMonday, bool isCurrentWeek) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
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
              icon: const Icon(Icons.arrow_left),
              tooltip: 'Previous week',
              onPressed: _loading ? null : () => _changeWeek(-1), // Disable if loading
              style: ButtonStyle(
                overlayColor: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.hovered)) {
                      return Colors.grey.withOpacity(0.2); // Gray hover
                    }
                    return null;
                  },
                ),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), // Match container
                  ),
                ),
              ),
            ),
          ),
          
          Text(
            '${weekStart.day}/${weekStart.month}/${weekStart.year} - ${weekEnd.day}/${weekEnd.month}/${weekEnd.year}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Container(
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
              icon: const Icon(Icons.arrow_right),
              tooltip: 'Next week',
              onPressed: _loading ? null : () => _changeWeek(1), // Disable if loading
              style: ButtonStyle(
                overlayColor: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.hovered)) {
                      return Colors.grey.withOpacity(0.2); // Gray hover
                    }
                    return null;
                  },
                ),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), // Match container
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoToCurrentWeekButton(DateTime currentMonday) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.today),
        label: const Text('Go to Current Week'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: () {
          setState(() {
            _currentMonday = currentMonday;
          });
          _fetchMealPlanForWeek(currentMonday);
        },
      ),
    );
  }

  Widget _buildTodayCard(DayPlan todayPlan, int todayIdx) {
    return Center(
      child: SizedBox(
        width: 380,
        child: GestureDetector(
          onTap: _mealPlan == null ? null : () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DayMealPlanPage(
                  dayPlan: todayPlan,
                  dayIndex: todayIdx,
                  weekPlanId: _mealPlan!.id,
                  weekMonday: _currentMonday,
                  weekDays: _mealPlan!.days,
                ),
              ),
            );
            if (mounted) {
              await _fetchMealPlanForWeek(_currentMonday);
            }
          },
          child: Card(
            color: Colors.amber[50],
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: const Text('Today', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Breakfast:  \t${todayPlan.breakfast ?? "-"}'),
                  Text('Lunch:      \t${todayPlan.lunch ?? "-"}'),
                  Text('Snack:      \t${todayPlan.snack ?? "-"}'),
                  Text('Dinner:     \t${todayPlan.dinner ?? "-"}'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Calories: ${_getTotal('calories', todayIdx).toStringAsFixed(0)}'),
                      const SizedBox(width: 12),
                      Text('Protein: ${_getTotal('protein', todayIdx).toStringAsFixed(0)}g'),
                      const SizedBox(width: 12),
                      Text('Price: ${_getTotal('price', todayIdx).toStringAsFixed(2)}€'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekPlanDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: const [
          Expanded(child: Divider()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text('Full Week Plan'),
          ),
          Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: () => _generateMealPlanForWeek(_currentMonday),
        child: const Text('Generate Meal Plan'),
      ),
    );
  }

  Widget _buildRegenerateDeleteRow() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _regenerateMealPlanForWeek(_currentMonday),
              child: const Text('Regenerate Meal Plan'),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _deleteMealPlanForWeek(_currentMonday),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(DayPlan day, String dayName, DateTime date, int index) {
    double calories = _getTotal('calories', index);
    double protein = _getTotal('protein', index);
    double price = _getTotal('price', index);
    return Center(
      child: SizedBox(
        width: 380,
        child: Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dayName),
                Text('${date.day}/${date.month}', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Breakfast:  \t${day.breakfast ?? "-"}'),
                Text('Lunch:      \t${day.lunch ?? "-"}'),
                Text('Snack:      \t${day.snack ?? "-"}'),
                Text('Dinner:     \t${day.dinner ?? "-"}'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Calories: ${calories.toStringAsFixed(0)}'),
                    const SizedBox(width: 12),
                    Text('Protein: ${protein.toStringAsFixed(0)}g'),
                    const SizedBox(width: 12),
                    Text('Price: ${price.toStringAsFixed(2)}€'),
                  ],
                ),
              ],
            ),
            onTap: _mealPlan == null ? null : () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DayMealPlanPage(
                    dayPlan: day,
                    dayIndex: index,
                    weekPlanId: _mealPlan!.id,
                    weekMonday: _currentMonday,
                    weekDays: _mealPlan!.days,
                  ),
                ),
              );
              if (mounted) {
                await _fetchMealPlanForWeek(_currentMonday);
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(color:Colors.white,child: Center(child: CircularProgressIndicator()));
    }
    final weekStart = _currentMonday;
    final weekEnd = _currentMonday.add(const Duration(days: 6));
    final today = DateTime.now();
    final currentMonday = _getMondayOf(today);
    final isCurrentWeek = weekStart.year == currentMonday.year && weekStart.month == currentMonday.month && weekStart.day == currentMonday.day;
    int todayIdx = isCurrentWeek ? today.weekday - 1 : -1;
    final todayPlan = (todayIdx >= 0 && _mealPlan?.days.length == 7) ? _mealPlan!.days[todayIdx] : null;
    return Container(
      color: Colors.white, // Set background color to white
      child: Column(
        children: [
          const SizedBox(height: 20,),
          _buildWeekSelector(weekStart, weekEnd, currentMonday, isCurrentWeek),
          if (!isCurrentWeek) _buildGoToCurrentWeekButton(currentMonday),
          if (isCurrentWeek && todayPlan != null) ...[
            _buildTodayCard(todayPlan, todayIdx),
            _buildWeekPlanDivider(),
          ],
          if (_mealPlan == null)
            _buildGenerateButton()
          else
            _buildRegenerateDeleteRow(),
          Expanded(
            child: _mealPlan == null
                ? const Center(child: Text('No meal plan found for this week.'))
                : ListView.builder(
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      final day = _mealPlan!.days[index];
                      String dayName = [
                        'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
                      ][index];
                      final date = weekStart.add(Duration(days: index));
                      return _buildDayCard(day, dayName, date, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
