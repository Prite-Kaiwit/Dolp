import 'package:flutter/material.dart';
import '../../models/pickup_point.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';

class AdminPickupPointsScreen extends StatelessWidget {
  const AdminPickupPointsScreen({super.key});

  void _showAddPointDialog(BuildContext context, AppState appState) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final zoneCtrl = TextEditingController(text: 'เขตเมือง');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('เพิ่มจุดนัดรับใหม่'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'ชื่อจุดนัดรับสาธารณะ',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: zoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'ย่านหรือเขตพื้นที่',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'จุดสังเกต / รายละเอียดตำแหน่ง',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                appState.addPickupPoint(
                  PickupPointModel(
                    id: 'point_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim().isNotEmpty
                        ? descCtrl.text.trim()
                        : 'ไม่มีรายละเอียด',
                    zone: zoneCtrl.text.trim(),
                  ),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('เพิ่มจุดนัดรับใหม่เรียบร้อยแล้ว'),
                  ),
                );
              }
            },
            child: const Text('เพิ่มจุดนัดรับ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState();

    return Scaffold(
      appBar: AppBar(title: const Text('จัดการจุดนัดรับ')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPointDialog(context, appState),
        backgroundColor: AppColors.greenPrimary,
        icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
        label: const Text(
          'เพิ่มจุดนัดรับ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: appState.pickupPoints.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final point = appState.pickupPoints[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: point.isActive
                          ? AppColors.greenPale
                          : AppColors.grayLine,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.place_rounded,
                      color: point.isActive
                          ? AppColors.greenPrimary
                          : AppColors.graySecondary,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          point.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: point.isActive
                                ? AppColors.inkText
                                : AppColors.graySecondary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.grayBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          point.zone,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.graySecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        point.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.graySecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 12,
                            color: AppColors.graySecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            point.openHours,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.graySecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: point.isActive,
                        activeThumbColor: AppColors.greenPrimary,
                        onChanged: (_) =>
                            appState.togglePickupPointActive(point.id),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                          size: 20,
                        ),
                        onPressed: () => appState.deletePickupPoint(point.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
