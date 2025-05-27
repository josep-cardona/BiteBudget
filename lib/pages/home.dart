import 'package:bitebudget/models/recipe.dart';
import 'package:bitebudget/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';




// Convert HomePage to a StatefulWidget
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  late final DatabaseService_Recipe _databaseService;
  late Future<List<Recipe>> _recipesFuture; // This list will hold all fetched recipes
  bool _isLoading = true; // Added loading state
  String? _errorMessage; // Added error message state


  final List<String> _recipeIdsToFetch = [
    'x5BCf2fLp4UTd2RkPE9y',
  ];

  Future<String?> _getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      return doc.data()?['name'] as String?;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService_Recipe();
    // Fetch the first recipe when the page loads
    _recipesFuture=_databaseService.getRecipesById(_recipeIdsToFetch);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      //Build your entire screen content within the body
      body: SafeArea( // Use SafeArea to avoid content overlapping status bar/notches
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align children to the start (left)
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
            FutureBuilder<List<Recipe>>(
              future: _recipesFuture, 
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
                  final List<Recipe> recipes = snapshot.data!;

                  if (recipes.isEmpty) {
                    return const Center(child: Text('No recipes found.'));
                  }
                  return Container(
                    height: 172,
                    child: ListView.separated(
                      itemCount: recipes.length,
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16
                      ),
                      separatorBuilder:(context, index) => SizedBox(width: 16,),
                      itemBuilder:(context, index) {
                        //Container for featured card
                        
                        return featuredRecipeCard(recipes[index]);
                      },
                    ),
                  );
                }
                // Fallback case (should ideally not be reached if conditions are exhaustive)
                return const Center(child: Text('Unexpected state.'));
              },
            ),
          ],
        ),
      ),
    );
  }

  Container featuredRecipeCard(Recipe recipe){
    
    return Container(
      width: 264,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(16)
      ),
      //Content of featured card
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 18.0,
              right: 16.0,
              bottom: 4,
            ),
            child: Text(
              recipe.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontVariations: [FontVariation('wght', 700),],
              ),
            ),
          ),
          //Bottom row for name, owner and time
          Padding(
            padding: EdgeInsets.only(bottom: 15, left: 15),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                //Owner of recipie pfp
                Container(
                  padding: EdgeInsets.only(right: 5),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle
                  ),
                ),
                const SizedBox(width: 5.0),
                Text(
                  'BiteBudget Team',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontVariations: [FontVariation('wght', 400),],
                  ),
                ),
                const SizedBox(width: 35.0),
                Container(
                  child: SvgPicture.asset(
                    'assets/icons/time_circle.svg',
                    width: 16, 
                    height: 16,
                  ),
                ),
                const SizedBox(width: 2.0),
                Text(
                  '${recipe.time} min',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontVariations: [FontVariation('wght', 400),],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget welcomeName() {
  return FutureBuilder<String?>(
    future: _getUserName(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            height: 32,
            child: Align(
              alignment: Alignment.centerLeft,
              child: CircularProgressIndicator(strokeWidth: 2),
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