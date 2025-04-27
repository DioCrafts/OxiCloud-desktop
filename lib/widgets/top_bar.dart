import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TopBar extends StatelessWidget {
  final String title;
  final Function(String) onSearch;
  final VoidCallback onLogout;

  const TopBar({
    Key? key,
    required this.title,
    required this.onSearch,
    required this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE6E6E6),
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        children: [
          Expanded(
            child: _buildSearchBar(),
          ),
          _buildUserControls(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.only(right: 20),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: onSearch,
              decoration: InputDecoration(
                hintText: 'Buscar archivos...',
                prefixIcon: Icon(Icons.search, color: Color(0xFF8895A7)),
                filled: true,
                fillColor: Color(0xFFF0F3F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.accentColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.search, color: Colors.white, size: 20),
              onPressed: () {},
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserControls() {
    return Row(
      children: [
        _buildLanguageSelector(),
        SizedBox(width: 15),
        _buildUserAvatar(),
        SizedBox(width: 15),
        _buildLogoutButton(),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Color(0xFFF0F3F7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Text(
            'ES',
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 14,
            ),
          ),
          SizedBox(width: 5),
          Icon(
            Icons.arrow_drop_down,
            size: 16,
            color: Color(0xFF718096),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'U',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return IconButton(
      icon: Icon(
        Icons.logout,
        color: Color(0xFF64748B),
        size: 24,
      ),
      onPressed: onLogout,
    );
  }
} 