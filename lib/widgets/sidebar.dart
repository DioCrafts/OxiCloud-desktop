import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const Sidebar({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: AppTheme.primaryColor,
      child: Column(
        children: [
          _buildLogo(),
          Expanded(
            child: _buildNavigation(),
          ),
          _buildStorageIndicator(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.accentColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: 10),
          Text(
            'OxiCloud',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation() {
    final items = [
      {'icon': Icons.folder, 'label': 'Mis archivos'},
      {'icon': Icons.share, 'label': 'Compartidos'},
      {'icon': Icons.star, 'label': 'Favoritos'},
      {'icon': Icons.history, 'label': 'Recientes'},
      {'icon': Icons.delete, 'label': 'Papelera'},
    ];

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 15),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildNavItem(
          icon: item['icon'] as IconData,
          label: item['label'] as String,
          isSelected: selectedIndex == index,
          onTap: () => onItemSelected(index),
        );
      },
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        margin: EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.secondaryColor : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 15),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageIndicator() {
    return Container(
      margin: EdgeInsets.all(15),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'Almacenamiento',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 10),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: Color(0xFF6B7E8F),
              borderRadius: BorderRadius.circular(5),
            ),
            child: FractionallySizedBox(
              widthFactor: 0.65, // 65% de uso
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.accentColor,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          Text(
            '6.5 GB de 10 GB usados',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
} 