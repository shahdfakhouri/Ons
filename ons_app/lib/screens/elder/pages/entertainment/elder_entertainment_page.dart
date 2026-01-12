import 'package:flutter/material.dart';

import 'tabs/entertainment_continue_tab.dart';
import 'tabs/entertainment_favorites_tab.dart';
import 'tabs/entertainment_feed_tab.dart';
import 'tabs/entertainment_history_tab.dart';

class ElderEntertainmentPage extends StatefulWidget {
  const ElderEntertainmentPage({super.key});

  @override
  State<ElderEntertainmentPage> createState() => _ElderEntertainmentPageState();
}

class _ElderEntertainmentPageState extends State<ElderEntertainmentPage>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entertainment'),
        bottom: TabBar(
          controller: _controller,
          tabs: const [
            Tab(icon: Icon(Icons.explore), text: 'Feed'),
            Tab(icon: Icon(Icons.play_circle), text: 'Continue'),
            Tab(icon: Icon(Icons.favorite), text: 'Favorites'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          EntertainmentFeedTab(),
          EntertainmentContinueTab(),
          EntertainmentFavoritesTab(),
          EntertainmentHistoryTab(),
        ],
      ),
    );
  }
}
