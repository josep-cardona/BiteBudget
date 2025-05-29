import 'package:bitebudget/models/recipe.dart';
import 'package:bitebudget/services/database_service.dart';
import 'package:bitebudget/services/user_service.dart';
import 'package:bitebudget/models/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';



// Convert HomePage to a StatefulWidget
class HomePage extends StatefulWidget {
  const HomePage({super.key});


  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  late final DatabaseService_Recipe _databaseService;
  late Future<List<Recipe>> _featuredRecipes; // This list will hold all fetched recipes
  late Future<List<Recipe>> _popularRecipes; 
  List<String> current_category = ['Breakfast'];
  final UserService _userService = UserService();
  AppUser? _currentUser;



  Future<AppUser?> getUser() async {
    if (_currentUser != null) return _currentUser;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    _currentUser = await _userService.getUser(user.uid);
    return _currentUser;
  }
  Future<String?> _getUserName(AppUser? user) async {
    final appUser = await getUser();
    if (appUser == null) return null;
    return appUser.displayName;
  }




  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService_Recipe();
    getUser();  // only runs once
    // Fetch the first recipe when the page loads
    _featuredRecipes=_databaseService.getRandomRecipes(2);
    _popularRecipes=_databaseService.getFilteredRecipes(types: current_category);

    //Recipe_Uploader.addNewRecipes(_databaseService);
  }

  void _onCategorySelected(String category) {
    setState(() {
      current_category = [category];
      _popularRecipes = _databaseService.getFilteredRecipes(types: current_category);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      //Build your entire screen content within the body
      body: SafeArea( // Use SafeArea to avoid content overlapping status bar/notches
        child: ListView( // Align children to the start (left)
          children: [
            SizedBox(height: 20.0),
            welcomeDaytime(),
            welcomeName(),
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                top: 16,
                bottom: 10
              ),
              child: const Text(
                'Featured',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontVariations: [FontVariation('wght', 700),],
                ),
              ),
            ),
            //Fetch featureds
            featuredMeals(),
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                top: 16,
                bottom: 10
              ),
              child: const Text(
                'Category',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontVariations: [FontVariation('wght', 700),],
                ),
              ),
            ),
            categories(),
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                top: 16,
                bottom: 10
              ),
              child: const Text(
                'Popular Recipes',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontVariations: [FontVariation('wght', 700),],
                ),
              ),
            ),
            popularMeals(),
            Padding(
              padding: EdgeInsets.only(
                bottom: 20
              ),
            )
          ],
        ),
      ),
    );
  }

  FutureBuilder<List<Recipe>> popularMeals() {
    return FutureBuilder<List<Recipe>>(
          future: _popularRecipes, 
          builder: (context, snapshot){
            // --- Connection State Handling ---
            if (snapshot.connectionState == ConnectionState.waiting) {
              // While the Future is still running (fetching data)
              return const Center(child: CircularProgressIndicator());
            }

            // --- Error Handling ---
            if (snapshot.hasError) {
              // If the Future completed with an error
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            // --- Data Available ---
            if (snapshot.hasData) {
              // If the Future completed successfully and has data
              final List<Recipe> featuredRecipes = snapshot.data!;

              if (featuredRecipes.isEmpty) {
                return const Center(child: Text('No recipes found.'));
              }
              return Container(
                width: 331,
                height: 252.95,
                child: ListView.separated(
                  itemCount: featuredRecipes.length,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                  ),
                  separatorBuilder:(context, index) => SizedBox(width: 16,),
                  itemBuilder:(context, index) {
                    //Container for featured card
                    
                    return popularCard(featuredRecipes[index]);
                  },
                  clipBehavior: Clip.none,
                ),
              );
            }
            // Fallback case (should ideally not be reached if conditions are exhaustive)
            return const Center(child: Text('Unexpected state.'));
          },
        );
  }

  Container popularCard(Recipe recipe) {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(15.36),
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
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // IMAGE + BADGE
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 161.28,
                height: 128,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 196, 92, 92),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              Positioned(
                top: -40,
                child: Container(
                  width: 161.28,
                  height: 235,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage("https://placehold.co/161x235"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 26.88,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x19053336),
                        blurRadius: 16,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: SvgPicture.asset('assets/icons/Heart.svg',width: 16,height: 16, color: Colors.black,),

                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // NAME - LIMITED TO WIDTH OF BOTTOM ROW
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 161.28),
            child: Text(
              recipe.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF0A2533),
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),

          Spacer(),

          // BOTTOM ROW - DEFINES CARD WIDTH
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset('assets/icons/calories_icon.svg',width: 16,height: 16, color: const Color(0xff97a2b1),),
              const SizedBox(width: 7),
              Text(
                '${recipe.calories.toInt()} Kcal',
                style: TextStyle(
                  color: const Color(0xFF97A1B0),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
              ),
              const SizedBox(width: 14),
              SvgPicture.asset('assets/icons/Time_circle_thin.svg',width: 16,height: 16, color: const Color(0xff97a2b1)),
              const SizedBox(width: 7),
              Text(
                '${recipe.time.toInt()} Min',
                style: TextStyle(
                  color: const Color(0xFF97A1B0),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ],
      ),
    );


  }

  Widget categories() {
  const List<String> options = ['Breakfast','Lunch','Dinner'];

  return SizedBox(
    height: 41,
    child: ListView.separated(
      itemCount: options.length,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      separatorBuilder:(context, index) => const SizedBox(width: 16),
      itemBuilder:(context, index) {
        final isSelected = current_category.contains(options[index]);

        return GestureDetector(
          onTap: () => _onCategorySelected(options[index]),
          child: Container(
            width: 120,
            decoration: BoxDecoration(
              color: isSelected ? Color(0xFF2C2C2C) : const Color(0xFFF1F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                options[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontVariations: const [FontVariation('wght', 400)],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}


  FutureBuilder<List<Recipe>> featuredMeals() {
    return FutureBuilder<List<Recipe>>(
            future: _featuredRecipes, 
            builder: (context, snapshot){
              // --- Connection State Handling ---
              if (snapshot.connectionState == ConnectionState.waiting) {
                // While the Future is still running (fetching data)
                return const Center(child: CircularProgressIndicator());
              }

              // --- Error Handling ---
              if (snapshot.hasError) {
                // If the Future completed with an error
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              // --- Data Available ---
              if (snapshot.hasData) {
                // If the Future completed successfully and has data
                final List<Recipe> featuredRecipes = snapshot.data!;

                if (featuredRecipes.isEmpty) {
                  return const Center(child: Text('No recipes found.'));
                }
                return Container(
                  height: 172,
                  child: ListView.separated(
                    itemCount: featuredRecipes.length,
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16
                    ),
                    separatorBuilder:(context, index) => SizedBox(width: 16,),
                    itemBuilder:(context, index) {
                      //Container for featured card
                      
                      return featuredRecipeCard(featuredRecipes[index]);
                    },
                  ),
                );
              }
              // Fallback case (should ideally not be reached if conditions are exhaustive)
              return const Center(child: Text('Unexpected state.'));
            },
          );
  }

  Container featuredRecipeCard(Recipe recipe){
    
    return Container(
      width: 264,
      height: 172,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 264,
              height: 172,
              decoration: ShapeDecoration(
                color: const Color(0xFF6FB9BE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 264,
              height: 172,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(0.50, -0.00),
                  end: Alignment(0.50, 1.00),
                  colors: [Colors.black.withValues(alpha: 0), Colors.black],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  recipe.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    height: 1.10,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: ShapeDecoration(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            shape: OvalBorder(),
                          ),
                        ),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: ShapeDecoration(
                            color: const Color(0xFFC4C4C4),
                            shape: OvalBorder(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Opacity(
                      opacity: 0.75,
                      child: Text(
                        'BiteBudget Team',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Opacity(
                      opacity: 0.75,
                      child: SvgPicture.asset(
                        'assets/icons/time_circle.svg',
                        width: 16,
                        height: 16,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Opacity(
                      opacity: 0.75,
                      child: Text(
                        '${recipe.time.toInt()} Min',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget welcomeName() {
  return FutureBuilder<String?>(
    future: _getUserName(_currentUser),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            height: 32,
            child: Align(
              alignment: Alignment.centerLeft,
            ),
          ),
        );
      }
      if (snapshot.hasError) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Error loading name',
            style: const TextStyle(
              color: Colors.red,
              fontSize: 24,
              fontVariations: [FontVariation('wght', 800)],
            ),
          ),
        );
      }
      final name = snapshot.data ?? '';
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          name.isNotEmpty ? name : 'Welcome!',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontVariations: [FontVariation('wght', 800)],
          ),
        ),
      );
    },
  );
}

  Padding welcomeDaytime() {
    return Padding(
            padding: const EdgeInsets.only(
              top: 16.0,
              left: 16.0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Keep the Row tight to its children
              crossAxisAlignment: CrossAxisAlignment.center, // Vertically center icon and text
              children: [
                // Icon container with background and padding
                Container(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: SvgPicture.asset(
                      'assets/icons/sun_icon.svg',
                      width: 17, 
                      height: 17,
                    ),
                  ),
                ),

                // Add a small horizontal space between the icon and text
                const SizedBox(width: 1.0),

                // Your text
                const Text(
                  'Good Morning',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontVariations: [FontVariation('wght', 700),],
                  ),
                ),
              ],
            ),
          );
  }
}