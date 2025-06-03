import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:BiteBudget/services/database_service.dart';
import '../models/meal_plan.dart';
import '../services/meal_plan_service.dart';
import '../services/meal_plan_generator.dart';
import 'day_meal_plan_page.dart';
import '../models/user.dart';
import 'home.dart'; // Import HomePage for userUpdateNotifier

class MealPlanPage extends StatefulWidget {
  final MealPlan? previousWeekPlan;
  const MealPlanPage({Key? key, this.previousWeekPlan}) : super(key: key);

  @override
  State<MealPlanPage> createState() => _MealPlanPageState();
}

class _MealPlanPageState extends State<MealPlanPage> {
  MealPlan? _mealPlan;
  bool _loading = true;
  DateTime _currentMonday = _getMondayOf(DateTime.now());
  Map<int, Map<String, double>> _dayTotals = {};
  AppUser? _user;
  
  // Add a listener reference
  late final VoidCallback _userUpdateListener;

  static DateTime _getMondayOf(DateTime date) {
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: date.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    _userUpdateListener = () async {
      await _fetchUserAndPlan(_currentMonday);
    };
    HomePage.userUpdateNotifier.addListener(_userUpdateListener);
    _fetchUserAndPlan(_currentMonday);
  }

  @override
  void dispose() {
    HomePage.userUpdateNotifier.removeListener(_userUpdateListener);
    super.dispose();
  }

  Future<void> _fetchUserAndPlan(DateTime monday) async {
    setState(() { _loading = true; });
    _user = await AppUser.fetchCurrentUser();
    await _fetchMealPlanForWeek(monday);
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
    // Fetch all recipes filtered by user diet
    final allRecipes = await recipeService.getFilteredRecipes(diet: _user?.dietType, excludeIngredients: _user?.allergies);
    for (int i = 0; i < _mealPlan!.days.length; i++) {
      final day = _mealPlan!.days[i];
      final names = [day.breakfast, day.lunch, day.snack, day.dinner].whereType<String>().toList();
      final recipes = { for (var r in allRecipes) r.name : r };
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
    // Use filtered recipes by user diet
    final allRecipes = await recipeService.getFilteredRecipes(diet: _user?.dietType);
    final mealPlanService = DatabaseServiceMealPlan();
    if (allRecipes.isEmpty) {
      setState(() { _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No recipes available.')));
      return;
    }
    if (_user == null) {
      setState(() { _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not loaded.')));
      return;
    }
    // Fetch previous week's plan
    final previousMonday = monday.subtract(const Duration(days: 7));
    final previousWeekPlan = await mealPlanService.getMealPlanForWeek(user.uid, previousMonday);
    final mealPlan = await generateMealPlan(
      monday: monday,
      allRecipes: allRecipes,
      user: _user!,
      pastWeek: previousWeekPlan,
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
    // Use filtered recipes by user diet
    final allRecipes = await recipeService.getFilteredRecipes(diet: _user?.dietType, excludeIngredients: _user?.allergies);
    final mealPlanService = DatabaseServiceMealPlan();
    if (allRecipes.isEmpty) {
      setState(() { _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No recipes available.')));
      return;
    }
    if (_user == null) {
      setState(() { _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not loaded.')));
      return;
    }
    // Fetch previous week's plan
    final previousMonday = monday.subtract(const Duration(days: 7));
    final previousWeekPlan = await mealPlanService.getMealPlanForWeek(user.uid, previousMonday);
    // Use the same generator as for initial generation
    final newMealPlan = await generateMealPlan(
      monday: monday,
      allRecipes: allRecipes,
      user: _user!,
      pastWeek: previousWeekPlan,
    );
    // Find the plan for this week
    final plan = await mealPlanService.getMealPlanForWeek(user.uid, monday);
    if (plan != null) {
      final updatedPlan = MealPlan(
        id: plan.id,
        startDate: monday,
        endDate: monday.add(const Duration(days: 6)),
        days: newMealPlan.days,
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
          Column(children: [
            Text(
            'Weekly Plan',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: const Color(0xFF1E232C),
                fontSize: 24,
                fontVariations: [FontVariation('wght', 600)]
            ),
        ),
            Text(
              '${weekStart.day}/${weekStart.month}/${weekStart.year} - ${weekEnd.day}/${weekEnd.month}/${weekEnd.year}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF8390A1)),
            ),
          ],
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
      child: Center(
        child: TextButton(
          onPressed: () {
            setState(() {
              _currentMonday = currentMonday;
            });
            _fetchMealPlanForWeek(currentMonday);
          },
          style: TextButton.styleFrom(
            foregroundColor: const Color.fromARGB(255, 35, 35, 36), // light gray
            padding: EdgeInsets.zero,
            minimumSize: Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          child: const Text(
            'Go to Current Week',
            style: TextStyle(
              decoration: TextDecoration.underline,
              color: Color.fromARGB(255, 64, 66, 68),
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayCard(DayPlan todayPlan, int todayIdx) {
    double calories = _getTotal('calories', todayIdx);
    double protein = _getTotal('protein', todayIdx);
    double price = _getTotal('price', todayIdx);
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
            elevation: 0,
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x19053336),
                    blurRadius: 16,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.today, size: 22, color: Color(0xFF8390A1)),
                          const SizedBox(width: 8),
                          const Text('Today',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: Color(0xFF1E232C),
                              )),
                        ],
                      ),
                      Text(
                        '${DateTime.now().day}/${DateTime.now().month}',
                        style: const TextStyle(
                          color: Color(0xFF2C2C2C),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Remove background from meal box
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _mealRow('Breakfast', todayPlan.breakfast),
                        _mealRow('Lunch', todayPlan.lunch),
                        _mealRow('Snack', todayPlan.snack),
                        _mealRow('Dinner', todayPlan.dinner),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _infoPill(Icons.local_fire_department, '${calories.toStringAsFixed(0)} kcal', const Color(0xFFFFB300)),
                      _infoPill(Icons.fitness_center, '${protein.toStringAsFixed(0)}g', const Color(0xFF4CAF50)),
                      _infoPill(Icons.euro, '${price.toStringAsFixed(2)}€', const Color(0xFF2196F3)),
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
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: const [
          Expanded(child: Divider(thickness: 1.5, color: Color(0xFFE9EEF6))),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Text('•  Full Week Plan  •',
              style: TextStyle(
                color: Color(0xFF8390A1),
                fontWeight: FontWeight.w600,
                fontSize: 15,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(child: Divider(thickness: 1.5, color: Color(0xFFE9EEF6))),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: SizedBox(
      width: 315,
      height: 40,
      child: ElevatedButton(
        onPressed: () => _generateMealPlanForWeek(_currentMonday),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2C2C2C), // Brand color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
          shadowColor: Colors.black45,
        ),
        child: const Text(
          'Generate Meal Plan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
      ),
    ),
  );
}


Widget _buildRegenerateDeleteRow() {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center, // 👈 This centers the buttons
      children: [
        SizedBox(
          width: 280,
          height: 40,
          child: ElevatedButton(
            onPressed: () => _regenerateMealPlanForWeek(_currentMonday),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C2C2C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
              shadowColor: Colors.black45,
            ),
            child: const Text(
              'Regenerate Meal Plan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 40,
          child: ElevatedButton(
            onPressed: () => _deleteMealPlanForWeek(_currentMonday),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
              shadowColor: Colors.black45,
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
        )
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
        child: GestureDetector(
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
          child: Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x19053336),
                    blurRadius: 16,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 20, color: Color(0xFF8390A1)),
                          const SizedBox(width: 8),
                          Text(dayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: Color(0xFF1E232C),
                              )),
                        ],
                      ),
                      Text(
                        '${date.day}/${date.month}',
                        style: const TextStyle(
                          color: Color(0xFF2C2C2C),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _mealRow('Breakfast', day.breakfast),
                        _mealRow('Lunch', day.lunch),
                        _mealRow('Snack', day.snack),
                        _mealRow('Dinner', day.dinner),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _infoPill(Icons.local_fire_department, '${calories.toStringAsFixed(0)} kcal', const Color(0xFFFFB300)),
                      _infoPill(Icons.fitness_center, '${protein.toStringAsFixed(0)}g', const Color(0xFF4CAF50)),
                      _infoPill(Icons.euro, '${price.toStringAsFixed(2)}€', const Color(0xFF2196F3)),
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

  Widget _mealRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF8390A1))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value ?? '-',
              style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1E232C)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoPill(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(color:Colors.white,child: Center(child: CircularProgressIndicator(color: Colors.black)));
    }
    final weekStart = _currentMonday;
    final weekEnd = _currentMonday.add(const Duration(days: 6));
    final today = DateTime.now();
    final currentMonday = _getMondayOf(today);
    final isCurrentWeek = weekStart.year == currentMonday.year && weekStart.month == currentMonday.month && weekStart.day == currentMonday.day;
    int todayIdx = isCurrentWeek ? today.weekday - 1 : -1;
    final todayPlan = (todayIdx >= 0 && _mealPlan?.days.length == 7) ? _mealPlan!.days[todayIdx] : null;
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: _mealPlan == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 190,
                          height: 190,
                          child: Stack(
                            children: [
                              Positioned(
                                left: 0.70,
                                top: 7,
                                child: Container(
                                  width: 180.59,
                                  height: 183,
                                  decoration: ShapeDecoration(
                                    color: const Color.fromARGB(0, 196, 196, 196),
                                    shape: OvalBorder(),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 0,
                                top: 0,
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/icons/bitebudget.png',
                                    width: 190,
                                    height: 190,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 18,),
                        Text(
                          'Generate a meal plan!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: const Color(0xFF1E232C),
                              fontSize: 26,
                              fontVariations: [FontVariation('wght', 700)]
                          ),
                        ),
                        SizedBox(height: 8,),
                        SizedBox(
                          width: 300,
                          child: Text(
                            'You still don’t have any meal plan for this week, generate it now!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF8390A1),
                              fontSize: 15,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              height: 1.50,
                            ),
                          ),
                        ),
                        SizedBox(height: 12,),
                        _buildGenerateButton(),
                        SizedBox(height: 20,),
                        if (!isCurrentWeek) _buildGoToCurrentWeekButton(currentMonday),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 80),
                      child: Column(
                        children: [
                          const SizedBox(height: 30),
                          if (!isCurrentWeek && _mealPlan != null) _buildGoToCurrentWeekButton(currentMonday),
                          if (isCurrentWeek && todayPlan != null) ...[
                            _buildTodayCard(todayPlan, todayIdx),
                            _buildWeekPlanDivider(),
                          ],
                          if (_mealPlan != null)
                            _buildRegenerateDeleteRow(),
                          if (_mealPlan != null)
                            Column(
                              children: List.generate(7, (index) {
                                final day = _mealPlan!.days[index];
                                String dayName = [
                                  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
                                ][index];
                                final date = weekStart.add(Duration(days: index));
                                return _buildDayCard(day, dayName, date, index);
                              }),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Stack(
              children: [
                IgnorePointer(
                  ignoring: true,
                  child: Container(
                    height: 160,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Color.fromARGB(0, 255, 255, 255),
                          Colors.white,
                        ],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 80,  // limit the height _buildWeekSelector can take
                      ),
                      child: _buildWeekSelector(weekStart, weekEnd, currentMonday, isCurrentWeek),
                    ),
                  ),
                ),
              ],
            ),
          ),


        ],
      ),
    );
  }
}