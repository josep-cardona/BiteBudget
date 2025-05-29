import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class RecipePage extends StatefulWidget {
  const RecipePage({super.key});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Black top section
            Container(
              height: 318,
              color: Colors.black,
            ),

            // Red section that overlaps and grows with content
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
                        children: [
                          // Left: Title
                          Text(
                            'Chia Seed Pudding',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 24,
                              fontVariations: [FontVariation('wght', 600)],
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
                                  color: Color(0xFF748189),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Opacity(
                                opacity: 0.75,
                                child: Text(
                                  '5 Min',
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
                    Text(
                      'This Pudding is the perfect fresh breakfast for a hot summer morning',
                      style: const TextStyle(
                        color: Color(0xFF748189),
                        fontSize: 16,
                        fontVariations: [FontVariation('wght', 400)],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12.0,
                        runSpacing: 12.0,
                        children: [
                          _buildItem('Breakfast', Icons.watch_later_outlined),
                          _buildItem('Vegan', Icons.info_outline),
                          _buildItem('180 Kcal', Icons.question_mark_outlined),
                          _buildItem('6g protein', Icons.question_mark_outlined),
                        ],
                      ),
                    ),

                    
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



Widget _buildItem(String label, IconData icon) {
  return Container(
    width: 170,
    child:Row(
    mainAxisSize: MainAxisSize.min,  // shrink to fit content
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
          icon,         // Choose any icon from the Icons class
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
  )
  );
}
