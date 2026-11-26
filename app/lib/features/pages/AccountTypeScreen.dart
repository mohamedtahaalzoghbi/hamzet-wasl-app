
import 'package:flutter/material.dart';
import 'package:graduation_project/widgets/Colors.dart';
import 'package:graduation_project/widgets/Colors.dart';

import '../../core/usersection.dart';
import 'Login_screen.dart';
class AccountTypeScreen extends StatefulWidget {
  const AccountTypeScreen({super.key});

  @override
  State<AccountTypeScreen> createState() => _AccountTypeScreenState();
}

class _AccountTypeScreenState extends State<AccountTypeScreen> {
  int selectedType = 0;

  final List<Map<String, dynamic>> accountTypes = [
    {
      'title': 'شركة',
      'description': 'تقديم فرص وخدمات',
      'image': 'assets/Frame 15.png',
    },
    {
      'title': 'فرد مهتم',
      'description': 'ابحث عن فرص تطوعية وساعد الآخرين',
      'image': 'assets/Text.png',
    },
    {
      'title': 'جمعية/منظمة',
      'description': 'شارك بفرصك ومبادراتك',
      'image': 'assets/Text (1).png',
    },
    {
      'title': 'متطوع',
      'description': 'شارك بمهاراتك وساعد الآخرين',
      'image':'assets/Text (2).png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: Stack(
          children: [

            Positioned.fill(
              child: Image.asset(
                'assets/Ellipse 1 (1).png',
                fit: BoxFit.fill,
              ),
            ),

            // Screen Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),

              child: Column(
                children: [

                  // Top Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18.5,
                    ),

                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const SizedBox(
                            width: 6,
                            height: 12,
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              color: AppColors.IconColor_back,
                            ),
                          ),
                        ),

                        GestureDetector(
                          onTap: () {
                            // Navigate to Home Screen
                          },
                          child: SizedBox(
                            width: 44,
                            height: 21,
                            child: Text(
                              'تخطي',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: AppColors.PremaryText,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 33),

                  // Page Title
                  Text(
                    'اختار نوع الحساب الأنسب ليك',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: AppColors.PremaryText,
                    ),
                  ),

                  const SizedBox(height: 34),

                  // Account Types
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                      ),
                      itemCount: accountTypes.length,

                      itemBuilder: (context, index) {

                        final account = accountTypes[index];

                        final isSelected = selectedType == index;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedType = index;
                            });
                          },

                          child: Container(
                            height: 135,
                            width: 333,
                            margin: const EdgeInsets.only(
                              bottom: 24,
                            ),

                            decoration: BoxDecoration(
                              color: const Color(0xFFFBF8F5),

                              borderRadius: BorderRadius.circular(15),

                              border: Border.all(
                                color: isSelected
                                    ? AppColors.PremaryText
                                    : AppColors.border,
                              ),
                            ),

                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [

                               SizedBox(height: 14,),
                                Container(
                                  width: 42,
                                  height: 42,

                                  child: Image.asset(account['image']),
                                ),

                                SizedBox(height: 14,),

                                // Account Title
                                Text(
                                  account['title'],
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.PremaryText,
                                  ),
                                ),

                                const SizedBox(height: 2),

                                // Description
                                Text(
                                  account['description'],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.PremaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 53),

                  // Next Button
                  SizedBox(
                    width: 363,
                    height: 55,

                    child: ElevatedButton(
                      onPressed: () {
                        UserSession.accountKind = AccountKind.values[selectedType]; // 3 = متطوع
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary_button,
                        foregroundColor: Colors.white,
                        elevation: 0,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),

                      child: const Text(
                        'التالي',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFDF6EF),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 34),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

