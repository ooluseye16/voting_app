import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const VotingApp());
}

class VotingApp extends StatelessWidget {
  const VotingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Point Voting System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Models
class Nominee {
  final String id;
  final String name;

  Nominee({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory Nominee.fromJson(Map<String, dynamic> json) =>
      Nominee(id: json['id'], name: json['name']);
}

class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory Category.fromJson(Map<String, dynamic> json) =>
      Category(id: json['id'], name: json['name']);
}

class Vote {
  final String categoryId;
  String? first; // 5 points
  String? second; // 3 points
  String? third; // 1 point

  Vote({required this.categoryId, this.first, this.second, this.third});

  Map<String, dynamic> toJson() => {
    'categoryId': categoryId,
    'first': first,
    'second': second,
    'third': third,
  };
}

class AccessCode {
  final String code;
  final String generatedFor;
  final DateTime generated;
  final bool used;

  AccessCode({
    required this.code,
    required this.generatedFor,
    required this.generated,
    this.used = false,
  });
}

class VoteResult {
  final String categoryId;
  final String categoryName;
  final Map<String, int> scores; // nominee -> total points

  VoteResult({
    required this.categoryId,
    required this.categoryName,
    required this.scores,
  });
}

// Mock API Service
class ApiService {
  static const String adminCode = 'ADMIN123';

  // Mock data storage
  static final List<Nominee> _nominees = [
    Nominee(id: '1', name: 'John Doe'),
    Nominee(id: '2', name: 'Jane Smith'),
    Nominee(id: '3', name: 'Bob Johnson'),
    Nominee(id: '4', name: 'Alice Williams'),
    Nominee(id: '5', name: 'Sarah Davis'),
  ];

  static final List<Category> _categories = [
    Category(id: '1', name: 'Best Analyst'),
    Category(id: '2', name: 'Best Team Player'),
  ];

  static final List<AccessCode> _accessCodes = [];
  static final Map<String, List<Vote>> _submittedVotes = {};

  static Future<String> validateCodeAndGetRole(String code) async {
    await Future.delayed(const Duration(seconds: 1));
    if (code == adminCode) return 'admin';
    if (_accessCodes.any((ac) => ac.code == code && !ac.used)) return 'user';
    return 'invalid';
  }

  static Future<bool> checkIfAlreadyVoted(String code) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _submittedVotes.containsKey(code);
  }

  static Future<List<Category>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_categories);
  }

  static Future<List<Nominee>> getNominees() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_nominees);
  }

  static Future<bool> submitVotes(String code, List<Vote> votes) async {
    await Future.delayed(const Duration(seconds: 1));
    _submittedVotes[code] = votes;
    final codeIndex = _accessCodes.indexWhere((ac) => ac.code == code);
    if (codeIndex != -1) {
      _accessCodes[codeIndex] = AccessCode(
        code: _accessCodes[codeIndex].code,
        generatedFor: _accessCodes[codeIndex].generatedFor,
        generated: _accessCodes[codeIndex].generated,
        used: true,
      );
    }
    return true;
  }

  // Admin endpoints
  static Future<String> generateAccessCode(String name) async {
    await Future.delayed(const Duration(milliseconds: 500));
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    String code;
    do {
      code = List.generate(
        8,
        (index) => chars[random.nextInt(chars.length)],
      ).join();
    } while (_accessCodes.any((ac) => ac.code == code));

    _accessCodes.add(
      AccessCode(code: code, generatedFor: name, generated: DateTime.now()),
    );
    return code;
  }

  static Future<List<AccessCode>> getAccessCodes() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_accessCodes);
  }

  static Future<bool> addCategory(String name) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final id = ((_categories.length) + 1).toString();
    _categories.add(Category(id: id, name: name));
    return true;
  }

  static Future<bool> deleteCategory(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _categories.removeWhere((cat) => cat.id == id);
    return true;
  }

  static Future<bool> addNominee(String name) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final id = ((_nominees.length) + 1).toString();
    _nominees.add(Nominee(id: id, name: name));
    return true;
  }

  static Future<bool> deleteNominee(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _nominees.removeWhere((nom) => nom.id == id);
    return true;
  }

  static Future<List<VoteResult>> getResults() async {
    await Future.delayed(const Duration(milliseconds: 500));
    List<VoteResult> results = [];

    for (var category in _categories) {
      Map<String, int> scores = {};

      for (var nominee in _nominees) {
        scores[nominee.name] = 0;
      }

      for (var votes in _submittedVotes.values) {
        final categoryVote = votes.firstWhere(
          (v) => v.categoryId == category.id,
          orElse: () => Vote(categoryId: category.id),
        );

        if (categoryVote.first != null) {
          scores[categoryVote.first!] = (scores[categoryVote.first!] ?? 0) + 5;
        }
        if (categoryVote.second != null) {
          scores[categoryVote.second!] =
              (scores[categoryVote.second!] ?? 0) + 3;
        }
        if (categoryVote.third != null) {
          scores[categoryVote.third!] = (scores[categoryVote.third!] ?? 0) + 1;
        }
      }

      results.add(
        VoteResult(
          categoryId: category.id,
          categoryName: category.name,
          scores: scores,
        ),
      );
    }

    return results;
  }
}

// Login Page
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter your access code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final role = await ApiService.validateCodeAndGetRole(code);

      if (role == 'invalid') {
        setState(() => _errorMessage = 'Invalid access code');
        return;
      }

      if (role == 'admin') {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
        }
        return;
      }

      final hasVoted = await ApiService.checkIfAlreadyVoted(code);

      if (hasVoted) {
        setState(() => _errorMessage = 'You have already submitted your votes');
        return;
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => VotingPage(userCode: code)),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'An error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.how_to_vote, size: 64, color: Colors.blue),
                    const SizedBox(height: 24),
                    const Text(
                      'Voting System',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter your access code to continue',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        labelText: 'Access Code',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        errorText: _errorMessage,
                      ),
                      onSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}

// Admin Dashboard
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ResultsPage(),
    const CategoriesPage(),
    const NomineesPage(),
    const AccessCodesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart),
                label: Text('Results'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.category),
                label: Text('Categories'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Nominees'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.vpn_key),
                label: Text('Access Codes'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}

// Results Page
class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  List<VoteResult>? _results;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    final results = await ApiService.getResults();
    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results == null || _results!.isEmpty) {
      return const Center(child: Text('No results available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results!.length,
      itemBuilder: (context, index) {
        final result = _results![index];
        final sortedEntries = result.scores.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.categoryName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...sortedEntries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${entry.value} pts',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
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
      },
    );
  }
}

// Categories Page
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<Category>? _categories;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await ApiService.getCategories();
    setState(() {
      _categories = categories;
      _isLoading = false;
    });
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Category Name',
              border: OutlineInputBorder(),
              hintText: 'e.g., Best Analyst',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a category name')),
                );
                return;
              }

              await ApiService.addCategory(name);
              Navigator.pop(context);
              _loadCategories();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Category added successfully')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.deleteCategory(category.id);
      _loadCategories();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Category deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Categories',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _showAddCategoryDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Category'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _categories == null || _categories!.isEmpty
              ? const Center(child: Text('No categories yet'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories!.length,
                  itemBuilder: (context, index) {
                    final category = _categories![index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          category.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteCategory(category),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// Nominees Page
class NomineesPage extends StatefulWidget {
  const NomineesPage({super.key});

  @override
  State<NomineesPage> createState() => _NomineesPageState();
}

class _NomineesPageState extends State<NomineesPage> {
  List<Nominee>? _nominees;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNominees();
  }

  Future<void> _loadNominees() async {
    final nominees = await ApiService.getNominees();
    setState(() {
      _nominees = nominees;
      _isLoading = false;
    });
  }

  void _showAddNomineeDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Nominee'),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nominee Name',
              border: OutlineInputBorder(),
              hintText: 'e.g., John Doe',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a nominee name')),
                );
                return;
              }

              await ApiService.addNominee(name);
              Navigator.pop(context);
              _loadNominees();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nominee added successfully')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNominee(Nominee nominee) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Nominee'),
        content: Text('Are you sure you want to delete "${nominee.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.deleteNominee(nominee.id);
      _loadNominees();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Nominee deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nominees',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _showAddNomineeDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Nominee'),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'These nominees can be voted for in any category',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _nominees == null || _nominees!.isEmpty
              ? const Center(child: Text('No nominees yet'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _nominees!.length,
                  itemBuilder: (context, index) {
                    final nominee = _nominees![index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            nominee.name[0].toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          nominee.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteNominee(nominee),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// Access Codes Page
class AccessCodesPage extends StatefulWidget {
  const AccessCodesPage({super.key});

  @override
  State<AccessCodesPage> createState() => _AccessCodesPageState();
}

class _AccessCodesPageState extends State<AccessCodesPage> {
  List<AccessCode>? _codes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCodes();
  }

  Future<void> _loadCodes() async {
    final codes = await ApiService.getAccessCodes();
    setState(() {
      _codes = codes;
      _isLoading = false;
    });
  }

  void _showGenerateCodeDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Access Code'),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Name of Person',
              border: OutlineInputBorder(),
              hintText: 'e.g., John Doe',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a name')),
                );
                return;
              }

              setState(() => _isLoading = true);
              final code = await ApiService.generateAccessCode(name);
              Navigator.pop(context);
              _loadCodes();

              if (mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Code Generated'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Access code for $name:'),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            code,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Code copied to clipboard'),
                            ),
                          );
                        },
                        child: const Text('Copy Code'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Access Codes',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _showGenerateCodeDialog,
                icon: const Icon(Icons.add),
                label: const Text('Generate Code'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _codes == null || _codes!.isEmpty
              ? const Center(child: Text('No access codes generated yet'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _codes!.length,
                  itemBuilder: (context, index) {
                    final code = _codes![index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          code.used ? Icons.check_circle : Icons.pending,
                          color: code.used ? Colors.green : Colors.orange,
                        ),
                        title: Row(
                          children: [
                            Text(
                              code.code,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• ${code.generatedFor}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          'Generated: ${_formatDate(code.generated)} • ${code.used ? "Used" : "Unused"}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: code.code));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Code copied to clipboard'),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Voting Page (User)
class VotingPage extends StatefulWidget {
  final String userCode;

  const VotingPage({super.key, required this.userCode});

  @override
  State<VotingPage> createState() => _VotingPageState();
}

class _VotingPageState extends State<VotingPage> {
  List<Category>? _categories;
  List<Nominee>? _nominees;
  Map<String, Vote> _votes = {};
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final categories = await ApiService.getCategories();
      final nominees = await ApiService.getNominees();
      setState(() {
        _categories = categories;
        _nominees = nominees;
        _votes = {for (var cat in categories) cat.id: Vote(categoryId: cat.id)};
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to load data')));
      }
    }
  }

  bool _canSubmit() {
    return _votes.values.every(
      (vote) => vote.first != null && vote.second != null && vote.third != null,
    );
  }

  Future<void> _submitVotes() async {
    if (!_canSubmit()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all categories')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final success = await ApiService.submitVotes(
        widget.userCode,
        _votes.values.toList(),
      );

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SuccessPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to submit votes')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_categories == null || _categories!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cast Your Votes')),
        body: const Center(child: Text('No categories available')),
      );
    }

    if (_nominees == null || _nominees!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cast Your Votes')),
        body: const Center(child: Text('No nominees available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cast Your Votes'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                'Code: ${widget.userCode}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _categories!.length,
              itemBuilder: (context, index) {
                final category = _categories![index];
                return CategoryCard(
                  category: category,
                  nominees: _nominees!,
                  vote: _votes[category.id]!,
                  onVoteChanged: (vote) {
                    setState(() => _votes[category.id] = vote);
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting || !_canSubmit()
                      ? null
                      : _submitVotes,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.green,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit All Votes',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Category Card Widget
class CategoryCard extends StatelessWidget {
  final Category category;
  final List<Nominee> nominees;
  final Vote vote;
  final Function(Vote) onVoteChanged;

  const CategoryCard({
    super.key,
    required this.category,
    required this.nominees,
    required this.vote,
    required this.onVoteChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete =
        vote.first != null && vote.second != null && vote.third != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isComplete)
                  const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Select 3 nominees (1st: 5pts, 2nd: 3pts, 3rd: 1pt)',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            VoteSelector(
              label: '1st Choice (5 points)',
              nominees: nominees,
              selectedNominee: vote.first,
              excludedNominees: [
                vote.second,
                vote.third,
              ].whereType<String>().toList(),
              onChanged: (nominee) {
                onVoteChanged(
                  Vote(
                    categoryId: vote.categoryId,
                    first: nominee,
                    second: vote.second,
                    third: vote.third,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            VoteSelector(
              label: '2nd Choice (3 points)',
              nominees: nominees,
              selectedNominee: vote.second,
              excludedNominees: [
                vote.first,
                vote.third,
              ].whereType<String>().toList(),
              onChanged: (nominee) {
                onVoteChanged(
                  Vote(
                    categoryId: vote.categoryId,
                    first: vote.first,
                    second: nominee,
                    third: vote.third,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            VoteSelector(
              label: '3rd Choice (1 point)',
              nominees: nominees,
              selectedNominee: vote.third,
              excludedNominees: [
                vote.first,
                vote.second,
              ].whereType<String>().toList(),
              onChanged: (nominee) {
                onVoteChanged(
                  Vote(
                    categoryId: vote.categoryId,
                    first: vote.first,
                    second: vote.second,
                    third: nominee,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Vote Selector Widget
class VoteSelector extends StatelessWidget {
  final String label;
  final List<Nominee> nominees;
  final String? selectedNominee;
  final List<String> excludedNominees;
  final Function(String?) onChanged;

  const VoteSelector({
    super.key,
    required this.label,
    required this.nominees,
    required this.selectedNominee,
    required this.excludedNominees,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: selectedNominee,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          hint: const Text('Select nominee'),
          isExpanded: true,
          items: nominees
              .where((nominee) => !excludedNominees.contains(nominee.name))
              .map(
                (nominee) => DropdownMenuItem(
                  value: nominee.name,
                  child: Text(nominee.name),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// Success Page
class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 100, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                'Votes Submitted Successfully!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Thank you for participating in the voting process.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
