import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/course_controller.dart';

class PostCourseView extends GetView<CourseController> {
  const PostCourseView({super.key});

  @override
  Widget build(BuildContext context) {
    final titleController = TextEditingController();
    final instructorController = TextEditingController();
    final thumbnailController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();
    final categoryController = TextEditingController(text: 'Development');

    return Scaffold(
      appBar: AppBar(title: const Text('Publish New Course')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Course Listing',
                style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Share your expertise with thousands of aspiring students',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              Text('Course Title *', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(hintText: 'e.g. Master Flutter & Dart Development'),
              ),
              const SizedBox(height: 16),

              Text('Instructor Name *', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: instructorController,
                decoration: const InputDecoration(hintText: 'e.g. Rohit Shrivastava'),
              ),
              const SizedBox(height: 16),

              Text('Thumbnail Image URL *', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: thumbnailController,
                decoration: const InputDecoration(hintText: 'https://images.unsplash.com/...'),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Category', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: categoryController,
                          decoration: const InputDecoration(hintText: 'Development, Design, AI'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Price (\$ USD)', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '49.99'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text('Course Description *', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Detailed summary of what students will learn...'),
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                onPressed: () {
                  if (titleController.text.trim().isEmpty || instructorController.text.trim().isEmpty) {
                    Get.snackbar('Required', 'Please fill in required fields', backgroundColor: Colors.red, colorText: Colors.white);
                    return;
                  }
                  final price = double.tryParse(priceController.text.trim()) ?? 49.99;
                  controller.publishCourse(
                    title: titleController.text.trim(),
                    instructorName: instructorController.text.trim(),
                    thumbnail: thumbnailController.text.trim().isNotEmpty
                        ? thumbnailController.text.trim()
                        : 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800',
                    category: categoryController.text.trim().isNotEmpty ? categoryController.text.trim() : 'Development',
                    price: price,
                    description: descriptionController.text.trim(),
                  );
                },
                child: const Text('Publish Course 🚀'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
