import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:bitebudget/models/recipe.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bitebudget/pages/shopping_list_page.dart';
import '../bitebudget_button_style.dart';

class RecipePage extends StatefulWidget {
  final Recipe recipe;
  const RecipePage({super.key, required this.recipe});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {

  int _selectedTab = 0; // 0 = Ingredients, 1 = Instructions

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.zero,
              children: [
                // Black top section with image
                Container(
                  height: 318,
                  color: Colors.black,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(0),
                      bottomRight: Radius.circular(0),
                    ),
                    child: Image.network(
                      widget.recipe.image_url ?? 'https://via.placeholder.com/400x300?text=No+Image',
                      height: 318,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                Transform.translate(
                  offset: const Offset(0, -20), // overlap by 20 pixels
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.all(26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20.0),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left: Title

                              Flexible(
                                child: Text(
                                  widget.recipe.name,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 24,
                                    fontVariations: [FontVariation('wght', 600)],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Right: Icon + Time
                              Row(
                                children: [
                                  Opacity(
                                    opacity: 0.75,
                                    child: SvgPicture.asset(
                                      'assets/icons/time_circle.svg',
                                      width: 16,
                                      height: 16,
                                      color: const Color(0xFF748189),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Opacity(
                                    opacity: 0.75,
                                    child: Text(
                                      '${widget.recipe.time} Min',
                                      style: const TextStyle(
                                        color: Color(0xFF748189),
                                        fontSize: 14,
                                        fontVariations: [FontVariation('wght', 400)],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        /*
                        Text(
                          'This Pudding is the perfect fresh breakfast for a hot summer morning',
                          style: const TextStyle(
                            color: Color(0xFF748189),
                            fontSize: 16,
                            fontVariations: [FontVariation('wght', 400)],
                          ),
                        ),
                        */
                        const SizedBox(height: 10),
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12.0,
                            runSpacing: 12.0,
                            children: [
                              _buildItem('${widget.recipe.type.isNotEmpty ? widget.recipe.type[0] : ''}', Icons.watch_later_outlined),
                              _buildItem('${widget.recipe.diet}', Icons.info_outline),
                              _buildItem('${widget.recipe.calories} Kcal', Icons.local_fire_department),
                              _buildItem('${widget.recipe.protein}g protein', Icons.fitness_center),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: ShapeDecoration(
                              color: const Color(0xFFE6EBF2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Stack(
                              children: [
                                AnimatedPositioned(
                                  duration: Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                  left: _selectedTab == 0 ? 0 : 159.0 + 8.0, // 159 width + 8 spacing
                                  top: 0,
                                  child: Container(
                                    width: 159,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Color(0xFF2C2C2C),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() { _selectedTab = 0; });
                                      },
                                      child: Container(
                                        width: 159,
                                        height: 48,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          'Ingredients',
                                          style: TextStyle(
                                            color: _selectedTab == 0 ? Colors.white : Color(0xFF0A2533),
                                            fontSize: 16,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w700,
                                            height: 1.35,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() { _selectedTab = 1; });
                                      },
                                      child: Container(
                                        width: 159,
                                        height: 48,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          'Instructions',
                                          style: TextStyle(
                                            color: _selectedTab == 1 ? Colors.white : Color(0xFF0A2533),
                                            fontSize: 16,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w700,
                                            height: 1.35,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                          child: _selectedTab == 0
                              ? Column(
                                  key: ValueKey('ingredients'),
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Ingredients', style: TextStyle(color: Colors.black, fontSize: 18,fontVariations: [FontVariation('wght', 700),],)),
                                    Text('${widget.recipe.ingredients.length} Items', style: TextStyle(color: const Color(0xFF748189), fontSize: 16,fontVariations: [FontVariation('wght', 400),],),),
                                    const SizedBox(height: 8),
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: widget.recipe.ingredients.length,
                                      separatorBuilder: (context, i) => SizedBox(height: 12),
                                      itemBuilder: (context, i) {
                                        final ingredient = widget.recipe.ingredients[i];
                                        final name = ingredient.isNotEmpty ? ingredient[0] : '';
                                        final amount = ingredient.length > 1 ? ingredient[1] : '';
                                        final imageUrl = ingredient.length > 2 ? ingredient[2] : null;
                                        return Container(
                                          height: 80,
                                          decoration: ShapeDecoration(
                                            color: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            shadows: [
                                              BoxShadow(
                                                color: Color(0x19053336),
                                                blurRadius: 16,
                                                offset: Offset(0, 2),
                                                spreadRadius: 0,
                                              )
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 56,
                                                height: 56,
                                                margin: const EdgeInsets.symmetric(horizontal: 12),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF2F2F2),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: imageUrl != null && imageUrl.isNotEmpty
                                                    ? ClipRRect(
                                                        borderRadius: BorderRadius.circular(12),
                                                        child: Image.network(
                                                          imageUrl,
                                                          fit: BoxFit.cover,
                                                          width: 56,
                                                          height: 56,
                                                          loadingBuilder: (context, child, loadingProgress) {
                                                            if (loadingProgress == null) return child;
                                                            return Center(
                                                              child: SizedBox(
                                                                width: 24,
                                                                height: 24,
                                                                child: CircularProgressIndicator(strokeWidth: 2),
                                                              ),
                                                            );
                                                          },
                                                          errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, color: Colors.grey, size: 32),
                                                        ),
                                                      )
                                                    : Icon(Icons.image, color: Colors.grey, size: 32),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(name, style: TextStyle(fontSize: 18, fontVariations: const [FontVariation('wght', 700)],)),
                                                    if (amount.isNotEmpty)
                                                      Padding(
                                                        padding: const EdgeInsets.only(top: 2.0),
                                                        child: Text(amount, style: TextStyle(fontSize: 15, color: Colors.grey[700])),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                )
                              : Column(
                                  key: ValueKey('instructions'),
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Recipe', style: TextStyle(color: Colors.black, fontSize: 18,fontVariations: [FontVariation('wght', 700),],)),
                                    Text('${widget.recipe.steps.length} Steps', style: TextStyle(color: const Color(0xFF748189), fontSize: 16,fontVariations: [FontVariation('wght', 400),],),),
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.only(top: 24, bottom: 24, left: 16, right: 16),
                                      decoration: ShapeDecoration(
                                        color: Colors.white,
                                        shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        ),
                                        shadows: [
                                        BoxShadow(
                                        color: Color(0x19053336),
                                        blurRadius: 16,
                                        offset: Offset(0, 2),
                                        spreadRadius: 0,
                                        )
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: List.generate(widget.recipe.steps.length, (i) => Padding(
                                          padding: const EdgeInsets.only(bottom: 12.0, top: 12, left: 6, right: 6),
                                          child: Text('${i+1}. ${widget.recipe.steps[i]}', style: TextStyle(color: const Color(0xFF757575), fontSize: 16,fontVariations: [FontVariation('wght', 400),],)),
                                        )),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        // Add more content here as needed
                        const SizedBox(height: 32),
                        Center(
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.add_shopping_cart, color: Colors.white),
                              label: Text('Add ingredients to shopping list', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              style: biteBudgetBlackButtonStyle.copyWith(
                                padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 18)),
                                shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                              ),
                              onPressed: () async {
                                final user = await FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  await ShoppingListPage.addIngredientsToShoppingList(
                                    user.uid,
                                    widget.recipe.ingredients,
                                  );
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Ingredients added to your shopping list!')),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 16,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.close, color: Colors.black),
                ),
              )
            ),
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.favorite_outline_outlined, color: Colors.black),
                ),
              )
            ),
            
          ],
        ),
      ),
    );
  }
}

Widget _buildItem(String label, IconData icon) {
  return SizedBox(
    width: 170,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: ShapeDecoration(
            color: const Color(0xFFE6EBF2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Icon(
            icon,
            color: Colors.black,
            size: 24.0,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontVariations: [FontVariation('wght', 400)],
          ),
        ),
      ],
    ),
  );
}