import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/tenant.dart';

class MessMenuScreen extends StatefulWidget {
  final bool isWarden;
  const MessMenuScreen({super.key, this.isWarden = false});
  @override
  State<MessMenuScreen> createState() => _MessMenuScreenState();
}
class _MessMenuScreenState extends State<MessMenuScreen> {
  int _selectedDay = DateTime.now().weekday - 1;
  final List<String> _days     = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
  final List<String> _fullDays = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
  final List<Map<String, List<String>>> _defaultMenu = [
    {'breakfast':['Poha','Boiled Eggs','Bread & Butter','Tea / Coffee'],'lunch':['Dal Tadka','Jeera Rice','Roti','Mix Veg Sabzi','Salad'],'snacks':['Samosa','Chai'],'dinner':['Paneer Butter Masala','Naan','Dal Makhani','Steamed Rice','Sweet']},
    {'breakfast':['Idli Sambhar','Coconut Chutney','Banana','Tea / Coffee'],'lunch':['Rajma','Rice','Roti','Aloo Gobi','Raita'],'snacks':['Bread Pakora','Chai'],'dinner':['Chicken Curry','Roti','Dal Fry','Rice','Kheer']},
    {'breakfast':['Aloo Paratha','Curd','Pickle','Tea / Coffee'],'lunch':['Chhole','Puri','Rice','Baingan Bharta','Salad'],'snacks':['Vada Pav','Chai'],'dinner':['Mutton Curry','Roti','Yellow Dal','Steamed Rice','Halwa']},
    {'breakfast':['Upma','Boiled Eggs','Toast','Tea / Coffee'],'lunch':['Dal Palak','Rice','Roti','Dum Aloo','Salad'],'snacks':['Dhokla','Chai'],'dinner':['Egg Curry','Naan','Dal','Rice','Payasam']},
    {'breakfast':['Puri Bhaji','Curd','Fruit','Tea / Coffee'],'lunch':['Kadhi Pakora','Rice','Roti','Jeera Aloo','Papad'],'snacks':['Kachori','Chai'],'dinner':['Fish Curry','Rice','Dal','Roti','Gulab Jamun']},
    {'breakfast':['Dosa','Sambhar','Chutney','Tea / Coffee'],'lunch':['Biryani','Raita','Mirchi ka Salan','Salad'],'snacks':['Popcorn','Juice'],'dinner':['Shahi Paneer','Naan','Dal','Rice','Ice Cream']},
    {'breakfast':['Chole Bhature','Lassi','Fruit Salad'],'lunch':['Special Thali','Dal Makhani','Shahi Paneer','Naan','Rice','Sweet'],'snacks':['Jalebi','Chai'],'dinner':['Chicken Biryani','Raita','Dal','Roti','Kheer']},
  ];
  final _mealIcons  = [Icons.free_breakfast, Icons.lunch_dining, Icons.fastfood, Icons.dinner_dining];
  final _mealNames  = ['Breakfast','Lunch','Snacks','Dinner'];
  final _mealTimes  = ['7:00 – 9:00 AM','12:30 – 2:30 PM','5:00 – 6:00 PM','8:00 – 10:00 PM'];
  final _mealColors = [0xFFF57F17, 0xFF1565C0, 0xFF6A1B9A, 0xFF1A3A5C];
  final _mealKeys   = ['breakfast','lunch','snacks','dinner'];

  void _editMeal(BuildContext context, String mealKey, String mealName, List<String> currentItems) {
    final ctrl = TextEditingController(text: currentItems.join(', '));
    showModalBottomSheet(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Edit $mealName — ${_fullDays[_selectedDay]}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C))),
          const SizedBox(height: 6),
          const Text('Separate items with commas', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 14),
          TextField(controller: ctrl, maxLines: 3,
            decoration: InputDecoration(hintText: 'e.g. Poha, Boiled Eggs, Tea',
              filled: true, fillColor: const Color(0xFFF5F7FA),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: () async {
                final items = ctrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                await Tenant.col('messMenuDays').doc('$_selectedDay').set(
                  {mealKey: items.join(', ')}, SetOptions(merge: true));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A3A5C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
          const SizedBox(height: 20),
        ])));
  }

  @override
  Widget build(BuildContext context) {
    final defaultDayMenu = _defaultMenu[_selectedDay];
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(backgroundColor: const Color(0xFF1A3A5C),
        title: const Text('Mess Menu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white)),
      body: Column(children: [
        Container(color: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(children: List.generate(7, (i) {
            final sel = _selectedDay == i; final isToday = i == DateTime.now().weekday - 1;
            return Expanded(child: GestureDetector(onTap: () => setState(() => _selectedDay = i),
              child: Container(margin: const EdgeInsets.symmetric(horizontal: 3), padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: sel ? const Color(0xFF1A3A5C) : Colors.transparent, borderRadius: BorderRadius.circular(10),
                  border: isToday && !sel ? Border.all(color: const Color(0xFFF0A500), width: 1.5) : null),
                child: Column(children: [
                  Text(_days[i], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sel ? Colors.white : isToday ? const Color(0xFFF0A500) : Colors.grey)),
                  if (isToday) Container(width: 4, height: 4, margin: const EdgeInsets.only(top: 3), decoration: BoxDecoration(color: sel ? Colors.white : const Color(0xFFF0A500), shape: BoxShape.circle)),
                ]))));
          }))),
        Container(width: double.infinity, color: const Color(0xFF1A3A5C).withOpacity(0.05), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            const Icon(Icons.calendar_today, size: 14, color: Color(0xFF1A3A5C)), const SizedBox(width: 6),
            Text(_fullDays[_selectedDay], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A3A5C), fontSize: 13)),
            if (_selectedDay == DateTime.now().weekday - 1) ...[
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFF0A500), borderRadius: BorderRadius.circular(10)),
                child: const Text('Today', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
            ],
            if (widget.isWarden) ...[
              const Spacer(),
              const Icon(Icons.edit_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              const Text('Tap any meal to edit', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ])),
        const Divider(height: 1),
        Expanded(child: StreamBuilder<DocumentSnapshot>(
          stream: Tenant.col('messMenuDays').doc('$_selectedDay').snapshots(),
          builder: (context, snap) {
            final overrideData = (snap.data?.exists ?? false) ? snap.data!.data() as Map<String, dynamic> : {};
            return ListView.builder(padding: const EdgeInsets.all(12), itemCount: 4,
              itemBuilder: (context, i) {
                final mealKey = _mealKeys[i];
                final overrideStr = overrideData[mealKey] as String?;
                final items = overrideStr != null
                    ? overrideStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
                    : defaultDayMenu[mealKey] ?? [];
                return GestureDetector(
                  onTap: widget.isWarden ? () => _editMeal(context, mealKey, _mealNames[i], items) : null,
                  child: Container(margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(color: Color(_mealColors[i]).withOpacity(0.08), borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14))),
                        child: Row(children: [
                          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Color(_mealColors[i]).withOpacity(0.15), shape: BoxShape.circle),
                            child: Icon(_mealIcons[i], color: Color(_mealColors[i]), size: 20)),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_mealNames[i], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(_mealColors[i]))),
                            Text(_mealTimes[i], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ])),
                          if (widget.isWarden) Icon(Icons.edit, size: 16, color: Color(_mealColors[i])),
                        ])),
                      Padding(padding: const EdgeInsets.all(14),
                        child: Wrap(spacing: 8, runSpacing: 8, children: items.map((item) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Color(_mealColors[i]).withOpacity(0.07), borderRadius: BorderRadius.circular(20), border: Border.all(color: Color(_mealColors[i]).withOpacity(0.2))),
                          child: Text(item, style: TextStyle(fontSize: 12, color: Color(_mealColors[i]), fontWeight: FontWeight.w500)))).toList())),
                    ])));
              });
          })),
      ]),
    );
  }
}

