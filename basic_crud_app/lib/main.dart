// main.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class User {
  final int id;
  String name;
  String username;
  String email;

  User(
      {required this.id,
      required this.name,
      required this.username,
      required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
    };
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User Management App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: UserListPage(),
    );
  }
}

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  List<User> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  // Fetch Users (Read Operation)
  Future<void> fetchUsers() async {
    try {
      final response = await http
          .get(Uri.parse('https://jsonplaceholder.typicode.com/users'));

      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        setState(() {
          users = body.map((dynamic item) => User.fromJson(item)).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        _showErrorDialog('Failed to load users');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('Error: ${e.toString()}');
    }
  }

  // Create User
  Future<void> createUser(User newUser) async {
    try {
      final response = await http.post(
        Uri.parse('https://jsonplaceholder.typicode.com/users'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(newUser.toJson()),
      );

      if (response.statusCode == 201) {
        setState(() {
          users.add(newUser);
        });
        Navigator.pop(context);
      } else {
        _showErrorDialog('Failed to create user');
      }
    } catch (e) {
      _showErrorDialog('Error: ${e.toString()}');
    }
  }

  // Update User
  Future<void> updateUser(User updatedUser) async {
    try {
      final response = await http.put(
        Uri.parse(
            'https://jsonplaceholder.typicode.com/users/${updatedUser.id}'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(updatedUser.toJson()),
      );

      if (response.statusCode == 200) {
        setState(() {
          int index = users.indexWhere((user) => user.id == updatedUser.id);
          if (index != -1) {
            users[index] = updatedUser;
          }
        });
        Navigator.pop(context);
      } else {
        _showErrorDialog('Failed to update user');
      }
    } catch (e) {
      _showErrorDialog('Error: ${e.toString()}');
    }
  }

  // Delete User
  Future<void> deleteUser(int userId) async {
    try {
      final response = await http.delete(
          Uri.parse('https://jsonplaceholder.typicode.com/users/$userId'));

      if (response.statusCode == 200) {
        setState(() {
          users.removeWhere((user) => user.id == userId);
        });
      } else {
        _showErrorDialog('Failed to delete user');
      }
    } catch (e) {
      _showErrorDialog('Error: ${e.toString()}');
    }
  }

  // Show Error Dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  // Show Create/Edit User Dialog
  void _showUserDialog({User? existingUser}) {
    final nameController =
        TextEditingController(text: existingUser?.name ?? '');
    final usernameController =
        TextEditingController(text: existingUser?.username ?? '');
    final emailController =
        TextEditingController(text: existingUser?.email ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existingUser == null ? 'Create User' : 'Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: Text(existingUser == null ? 'Create' : 'Update'),
            onPressed: () {
              final user = User(
                id: existingUser?.id ?? DateTime.now().millisecondsSinceEpoch,
                name: nameController.text,
                username: usernameController.text,
                email: emailController.text,
              );

              if (existingUser == null) {
                createUser(user);
              } else {
                updateUser(user);
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showUserDialog(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (ctx, index) {
                final user = users[index];
                return ListTile(
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showUserDialog(existingUser: user),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => deleteUser(user.id),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
