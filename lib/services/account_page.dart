import 'package:BiteBudget/pages/edit_profile_page.dart';
import 'package:BiteBudget/pages/settings_page.dart';
import 'package:BiteBudget/pages/help_page.dart';
import 'package:BiteBudget/pages/appearance_page.dart';
import 'package:BiteBudget/pages/future_features_page.dart';
import 'package:BiteBudget/pages/about_us_page.dart';
import 'package:flutter/material.dart';

class AccountPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit Profile'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfilePage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.help),
            title: Text('Help'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HelpPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.color_lens),
            title: Text('Appearance'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AppearancePage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.stars),
            title: Text('Future Features'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FutureFeaturesPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('About Us'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AboutUsPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Log Out'),
            onTap: () {
              // Handle log out logic here
            },
          ),
        ],
      ),
    );
  }
}
