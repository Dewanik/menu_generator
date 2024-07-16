import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'pdf_generator.dart';
import 'package:flutter/services.dart';
import 'file_operations.dart' if (dart.library.html) 'file_operations_web.dart' if (dart.library.io) 'file_operations_non_web.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Menu Generator',
      home: SkeletonUI(),
    );
  }
}

class SkeletonUI extends StatefulWidget {
  @override
  _SkeletonUIState createState() => _SkeletonUIState();
}

class _SkeletonUIState extends State<SkeletonUI> {
  List<String> categories = [];
  String? selectedCategory;
  String newCategory = '';
  List<Map<String, dynamic>> items = [];
  Uint8List? frontCoverImage;
  Uint8List? backCoverImage;
  Uint8List? designImage;
  String companyName = '';
  Uint8List? companyLogo;
  String frontTitle = '';
  String frontDetails = '';
  String backDetails = '';
  String? selectedFont;
  List<String> fonts = [];
  Color selectedColor = Colors.black;
  bool isLoading = false; // New field for loading state

  @override
  void initState() {
    super.initState();
    loadFonts();
  }

  Future<void> loadFonts() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    final fontPaths = manifestMap.keys
        .where((String key) => key.contains('assets/fonts/'))
        .toList();
    setState(() {
      fonts = fontPaths;
    });
  }

  void addCategory() {
    if (newCategory.isNotEmpty) {
      setState(() {
        categories.add(newCategory);
        newCategory = '';
      });
    }
  }

  void deleteCategory(String category) {
    setState(() {
      categories.remove(category);
      if (selectedCategory == category) {
        selectedCategory = null;
      }
      items.removeWhere((item) => item['category'] == category);
    });
  }

  void addItem() {
    if (selectedCategory != null) {
      setState(() {
        items.add({
          'category': selectedCategory!,
          'name': TextEditingController(),
          'description': TextEditingController(),
          'price': TextEditingController(),
        });
      });
    }
  }

  void deleteItem(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  void resetAll() {
    setState(() {
      categories = [];
      selectedCategory = null;
      newCategory = '';
      items = [];
      frontCoverImage = null;
      backCoverImage = null;
      designImage = null;
      companyName = '';
      companyLogo = null;
      frontTitle = '';
      frontDetails = '';
      backDetails = '';
      selectedFont = null;
      selectedColor = Colors.black;
    });
  }

  Future<void> showPreview() async {
    setState(() {
      isLoading = true; // Set loading state to true
    });
    try {
      Map<String, List<Map<String, String>>> data = {};
      for (var category in categories) {
        data[category] = items
            .where((item) => item['category'] == category)
            .map((item) => {
                  'name': (item['name'] as TextEditingController).text,
                  'description': (item['description'] as TextEditingController).text,
                  'price': (item['price'] as TextEditingController).text,
                })
            .toList();
      }
      await generateAndPreviewPdf(
        data,
        frontCoverImage,
        backCoverImage,
        designImage,
        companyName,
        companyLogo,
        frontTitle,
        frontDetails,
        backDetails,
        selectedFont,
        selectedColor,
      );
    } catch (e) {
      // Handle error by resetting state
      resetAll();
      // Optionally, show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load. State has been reset.')),
      );
    } finally {
      setState(() {
        isLoading = false; // Set loading state to false
      });
    }
  }

  Future<void> pickImage(bool isFrontCover) async {
    try {
      final fileOperations = getFileOperations();
      final imageBytes = await fileOperations.pickImage();
      setState(() {
        if (isFrontCover) {
          frontCoverImage = imageBytes;
        } else {
          backCoverImage = imageBytes;
        }
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> pickDesignImage() async {
    try {
      final fileOperations = getFileOperations();
      final imageBytes = await fileOperations.pickImage();
      setState(() {
        designImage = imageBytes;
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> pickLogo() async {
    try {
      final fileOperations = getFileOperations();
      final imageBytes = await fileOperations.pickImage();
      setState(() {
        companyLogo = imageBytes;
      });
    } catch (e) {
      // Handle error
    }
  }

  void showDetailsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newCompanyName = companyName;
        String newFrontTitle = frontTitle;
        String newFrontDetails = frontDetails;
        String newBackDetails = backDetails;
        return AlertDialog(
          title: Text('Enter Details'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(labelText: 'Company Name'),
                  onChanged: (value) {
                    newCompanyName = value;
                  },
                  controller: TextEditingController(text: companyName),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: pickLogo,
                  child: Text('Select Company Logo'),
                ),
                SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(labelText: 'Front Page Title'),
                  onChanged: (value) {
                    newFrontTitle = value;
                  },
                  controller: TextEditingController(text: frontTitle),
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Front Page Details'),
                  onChanged: (value) {
                    newFrontDetails = value;
                  },
                  controller: TextEditingController(text: frontDetails),
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Back Page Details'),
                  onChanged: (value) {
                    newBackDetails = value;
                  },
                  controller: TextEditingController(text: backDetails),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  companyName = newCompanyName;
                  frontTitle = newFrontTitle;
                  frontDetails = newFrontDetails;
                  backDetails = newBackDetails;
                });
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void showColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pick a Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (color) {
                setState(() {
                  selectedColor = color;
                });
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Menu Generator'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: resetAll,
          ),
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: showDetailsDialog,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      CoverButton(
                        label: 'Front',
                        imageFile: frontCoverImage,
                        onImageSelected: () => pickImage(true),
                      ),
                      CoverButton(
                        label: 'Back',
                        imageFile: backCoverImage,
                        onImageSelected: () => pickImage(false),
                      ),
                      CoverButton(
                        label: 'For all design',
                        imageFile: designImage,
                        onImageSelected: pickDesignImage,
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Add Category',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            newCategory = value;
                          },
                          onSubmitted: (_) => addCategory(),
                        ),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: addCategory,
                        child: Text('Add Category'),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  if (categories.isNotEmpty)
                    DropdownButton<String>(
                      hint: Text('Select Category'),
                      value: selectedCategory,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCategory = newValue;
                        });
                      },
                      items: categories.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(value),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => deleteCategory(value),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  SizedBox(height: 20),
                  if (selectedCategory != null)
                    ElevatedButton(
                      onPressed: addItem,
                      child: Text('Add Item'),
                    ),
                  SizedBox(height: 20),
                  if (fonts.isNotEmpty)
                    DropdownButton<String>(
                      hint: Text('Select Font'),
                      value: selectedFont,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedFont = newValue;
                        });
                      },
                      items: fonts.map<DropdownMenuItem<String>>((String font) {
                        return DropdownMenuItem<String>(
                          value: font,
                          child: Text(font.split('/').last),
                        );
                      }).toList(),
                    ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: showColorPicker,
                    child: Text('Pick Color'),
                  ),
                  SizedBox(height: 20),
                  Container(
                    height: 300,
                    width: 400,
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        if (items[index]['category'] == selectedCategory) {
                          return Container(
                            margin: EdgeInsets.symmetric(vertical: 5),
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Category: ${items[index]['category']}'),
                                      TextField(
                                        controller: items[index]['name'] as TextEditingController,
                                        decoration: InputDecoration(labelText: 'Item Name'),
                                      ),
                                      TextField(
                                        controller: items[index]['description'] as TextEditingController,
                                        decoration: InputDecoration(labelText: 'Description'),
                                      ),
                                      TextField(
                                        controller: items[index]['price'] as TextEditingController,
                                        decoration: InputDecoration(labelText: 'Price'),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => deleteItem(index),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return Container();
                        }
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  Text('Choose Theme'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ThemeIcon(),
                      ThemeIcon(),
                      ThemeIcon(),
                    ],
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: showPreview,
                    child: Text('Launch Preview'),
                  ),
                ],
              ),
            ),
    );
  }
}

class CoverButton extends StatelessWidget {
  final String label;
  final Uint8List? imageFile;
  final VoidCallback onImageSelected;

  CoverButton({required this.label, required this.imageFile, required this.onImageSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: Icon(imageFile == null ? Icons.add : Icons.image),
          iconSize: 50,
          onPressed: onImageSelected,
        ),
        Text(label),
      ],
    );
  }
}

class ThemeIcon extends StatefulWidget {
  @override
  _ThemeIconState createState() => _ThemeIconState();
}

class _ThemeIconState extends State<ThemeIcon> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
