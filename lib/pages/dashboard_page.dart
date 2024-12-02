import 'package:flutter/material.dart';
// Import your page classes here
// import 'package:your_app/pages/home_page.dart';
// import 'package:your_app/pages/transactions_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Method to handle navigation with different destinations
  void _navigateTo(BuildContext context, String destination) {
    switch (destination) {
      case 'Accueil':
        Navigator.pushNamed(context, '/home');
        break;
      case 'Transactions':
        Navigator.pushNamed(context, '/chantier');
        break;
      default:
        // Optional: Handle unexpected destinations
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navigation non disponible')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Dashboard",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth * 0.04,
                  vertical: constraints.maxWidth * 0.04,
                ),
                child: OrientationBuilder(
                  builder: (context, orientation) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            orientation == Orientation.portrait ? 2 : 4,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: 2,
                      itemBuilder: (context, index) {
                        final List<Map<String, dynamic>> dashboardItems = [
                          {'icon': Icons.home_outlined, 'text': 'Accueil'},
                          {'icon': Icons.list_alt, 'text': 'Transactions'},
                        ];

                        final item = dashboardItems[index];
                        return DashboardItemCard(
                          icon: item['icon'],
                          text: item['text'],
                          onTap: () => _navigateTo(context, item['text']),
                        );
                      },
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class DashboardItemCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final void Function() onTap;

  const DashboardItemCard({
    Key? key,
    required this.icon,
    required this.text,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                text,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
