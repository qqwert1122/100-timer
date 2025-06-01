import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project1/theme/app_color.dart';
import 'package:project1/theme/app_text_style.dart';
import 'package:project1/utils/color_service.dart';
import 'package:project1/utils/icon_utils.dart';
import 'package:project1/utils/responsive_size.dart';

class ActivityPickerModal extends StatelessWidget {
  final List<Map<String, dynamic>> activities;
  final String selectedActivityName;
  final Function(String id, String name, String icon, String color) onActivitySelected;

  const ActivityPickerModal({
    super.key,
    required this.activities,
    required this.selectedActivityName,
    required this.onActivitySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.hp(70),
      padding: context.paddingSM,
      decoration: BoxDecoration(
        color: AppColors.background(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16.0),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: context.hp(1)),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: 60,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary(context),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          SizedBox(height: context.hp(1)),
          Padding(
            padding: context.paddingSM,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '활동 선택하기',
                style: AppTextStyles.getTitle(context),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: context.paddingSM,
              child: ListView.builder(
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  final iconName = activity['activity_icon'];
                  final iconData = getIconImage(iconName);

                  return Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: activity['activity_name'] == selectedActivityName ? Colors.red[50] : null,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: Image.asset(
                          iconData,
                          width: context.xl,
                          height: context.xl,
                          errorBuilder: (context, error, stackTrace) {
                            // 이미지를 로드하는 데 실패한 경우의 대체 표시
                            return Container(
                              width: context.xl,
                              height: context.xl,
                              color: Colors.grey.withValues(alpha: 0.2),
                              child: Icon(
                                Icons.broken_image,
                                size: context.xl,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              activity['activity_name'],
                              style: AppTextStyles.getBody(context).copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: activity['activity_name'] == selectedActivityName ? Colors.redAccent.shade200 : null),
                            ),
                            SizedBox(
                              width: context.wp(4),
                            ),
                            Container(
                              width: 12,
                              height: 12,
                              margin: const EdgeInsets.symmetric(vertical: 2.0),
                              decoration: BoxDecoration(
                                color: ColorService.hexToColor(activity['activity_color']),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onActivitySelected(
                            activity['activity_id'],
                            activity['activity_name'],
                            activity['activity_icon'],
                            activity['activity_color'],
                          );
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
