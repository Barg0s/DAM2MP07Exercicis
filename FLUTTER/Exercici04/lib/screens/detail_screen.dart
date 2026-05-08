import 'package:exercici04/models/detail.dart';
import 'package:flutter/material.dart';
import '../services/details_service.dart';
import '../widgets/detailCard.dart';

class DetailScreen extends StatefulWidget {
  final int id;
  final String name;

  const DetailScreen({
    super.key,
    required this.id,
    required this.name,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Detail? detail;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDetails();
  }

  Future<void> loadDetails() async {
    try {
      final data = await DetailsService.getDetail(widget.id);

      setState(() {
        detail = data;
        isLoading = false;
      });
    } catch (e) {
      print("Error loading details: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        title: Text(widget.name),
        backgroundColor: Colors.red,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : detail == null
              ? const Center(
                  child: Text("No se encontraron detalles"),
                )
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: DetailCard(detail: detail!),
                  ),
                ),
    );
  }
}