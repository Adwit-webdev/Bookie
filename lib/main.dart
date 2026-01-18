import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; 
import 'package:flutter/services.dart'; 
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

const String _apiKey = "PASTE_YOUR_API_KEY_HERE"; // INSTRUCTIONS: Get your FREE API Key from aistudio.google.com and paste it here.

void main() {
  runApp(const MyPdfApp());
}

class MyPdfApp extends StatelessWidget {
  const MyPdfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const PdfViewerPage(),
    );
  }
}

class PdfViewerPage extends StatefulWidget {
  const PdfViewerPage({super.key});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  String? localPath;
  List<String> _recentFiles = [];
  
  final PdfViewerController _pdfController = PdfViewerController();
  final FocusNode _focusNode = FocusNode(); 
  
  int _colorMode = 0; 
  final List<ColorFilter> _colorFilters = [
    const ColorFilter.mode(Colors.transparent, BlendMode.multiply), 
    const ColorFilter.matrix([ 
      -1,  0,  0, 0, 255,
       0, -1,  0, 0, 255,
       0,  0, -1, 0, 255,
       0,  0,  0, 1,   0,
    ]),
    ColorFilter.mode(Colors.brown.withValues(alpha: 0.4), BlendMode.srcATop),
  ];

  @override
  void initState() {
    super.initState();
    _refreshHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _pdfController.dispose();
    super.dispose();
  }

  void _requestFocus() {
    if (mounted && localPath != null) {
      _focusNode.requestFocus();
    }
  }

  void _refreshHistory() async {
    final files = await HistoryManager.getRecentFiles();
    if (mounted) {
      setState(() {
        _recentFiles = files;
      });
    }
  }

  void _deleteFromHistory(String path) async {
    await HistoryManager.removeFile(path);
    _refreshHistory();
  }

  Future<void> _scanFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      final dir = Directory(selectedDirectory);
      List<FileSystemEntity> entities = dir.listSync(recursive: false);
      int count = 0;
      for (var entity in entities) {
        if (entity is File && entity.path.toLowerCase().endsWith('.pdf')) {
          await HistoryManager.addToHistoryOnly(entity.path);
          count++;
        }
      }
      _refreshHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Imported $count PDFs!")),
        );
      }
    }
  }

  void _openPdf(String path) async {
    int savedPage = await HistoryManager.getSavedPage(path);
    if (!mounted) return;
    setState(() {
      localPath = path;
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestFocus();
    });
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _pdfController.jumpToPage(savedPage);
      }
    });
    
    await HistoryManager.saveProgress(path, savedPage);
    _refreshHistory();
  }

  void _closePdf() async {
    if (localPath != null) {
      await HistoryManager.saveProgress(localPath!, _pdfController.pageNumber);
    }
    setState(() {
      localPath = null;
    });
    _refreshHistory();
  }

  Future<void> pickPdfFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      _openPdf(result.files.single.path!);
    }
  }

  Future<void> _summarizeCurrentPage() async {
    if (localPath == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final File file = File(localPath!);
      final PdfDocument document = PdfDocument(inputBytes: file.readAsBytesSync());
      
      int pageIndex = _pdfController.pageNumber - 1;
      String pageText = PdfTextExtractor(document).extractText(
        startPageIndex: pageIndex, 
        endPageIndex: pageIndex
      );
      document.dispose();

      if (pageText.trim().isEmpty) {
        throw Exception("This page is empty or contains only images.");
      }

      GenerativeModel? model;
      String? responseText;
      
      final modelNames = [
        'gemini-1.5-flash',
        'gemini-1.5-flash-latest',
        'gemini-pro',
        'gemini-1.5-pro',
      ];
      
      Exception? lastError;
      
      for (String modelName in modelNames) {
        try {
          model = GenerativeModel(
            model: modelName, 
            apiKey: _apiKey,
          );
          
          final content = [
            Content.text("Summarize this text in 3 concise bullet points:\n\n$pageText")
          ];
          
          final response = await model.generateContent(content);
          responseText = response.text;
          
          if (responseText != null && responseText.isNotEmpty) {
            break;
          }
        } catch (e) {
          lastError = e as Exception;
          continue;
        }
      }

      if (!mounted) return; 

      Navigator.pop(context);
      
      if (responseText != null && responseText.isNotEmpty) {
        _showAiResult(responseText);
      } else {
        _showAiResult("Error: Could not generate summary. ${lastError?.toString() ?? 'All models failed'}");
      }

    } catch (e) {
      if (!mounted) return; 
      Navigator.pop(context);
      _showAiResult("Error: ${e.toString()}\n\nPlease check:\n1. Your API key is valid\n2. You have enabled Gemini API in Google Cloud Console\n3. Your internet connection is working");
    }
  }

  void _showAiResult(String text) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        height: 400,
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "✨ AI Summary", 
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold, 
                color: Colors.deepPurple
              )
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Text(text, style: const TextStyle(fontSize: 16))
              )
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Close"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bookie"),
        actions: [
          if (localPath != null) ...[
            IconButton(
              icon: const Icon(Icons.auto_awesome, color: Colors.amber), 
              onPressed: _summarizeCurrentPage,
              tooltip: "Summarize Page",
            ),
            IconButton(
              icon: const Icon(Icons.zoom_in), 
              onPressed: () => _pdfController.zoomLevel += 0.5,
              tooltip: "Zoom In",
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out), 
              onPressed: () { 
                if (_pdfController.zoomLevel > 1) {
                  _pdfController.zoomLevel -= 0.5; 
                }
              },
              tooltip: "Zoom Out",
            ),
            IconButton(
              icon: const Icon(Icons.palette), 
              onPressed: () => setState(() => _colorMode = (_colorMode + 1) % 3),
              tooltip: "Color Filter",
            ),
            IconButton(
              icon: const Icon(Icons.close), 
              onPressed: _closePdf,
              tooltip: "Close PDF",
            ),
          ]
        ],
      ),
      body: localPath == null
          ? _buildHistoryList()
          : Focus(
              focusNode: _focusNode,
              autofocus: true,
              onKeyEvent: (node, event) => KeyEventResult.handled,
              child: Listener(
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    // Check if Ctrl key is pressed
                    final isCtrlPressed = HardwareKeyboard.instance.logicalKeysPressed
                        .contains(LogicalKeyboardKey.controlLeft) ||
                        HardwareKeyboard.instance.logicalKeysPressed
                        .contains(LogicalKeyboardKey.controlRight);

                    if (isCtrlPressed) {
                      setState(() {
                        double currentZoom = _pdfController.zoomLevel;
                        double delta = event.scrollDelta.dy;
                        double zoomChange = -delta / 500;
                        
                        double newZoom = (currentZoom + zoomChange).clamp(0.5, 5.0);
                        _pdfController.zoomLevel = newZoom;
                      });
                    }
                  }
                },
                child: GestureDetector(
                  onTap: _requestFocus,
                  child: ColorFiltered(
                    colorFilter: _colorFilters[_colorMode],
                    child: SfPdfViewer.file(
                      File(localPath!),
                      controller: _pdfController,
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHistoryList() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: pickPdfFile,
              icon: const Icon(Icons.file_open),
              label: const Text("Open File"),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
            ),
            const SizedBox(width: 20),
            ElevatedButton.icon(
              onPressed: _scanFolder,
              icon: const Icon(Icons.folder_copy),
              label: const Text("Import Folder"),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(),
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "Library & History", 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
          ),
        ),
        Expanded(
          child: _recentFiles.isEmpty
              ? const Center(
                  child: Text("No history. Open a file or Import a folder!")
                )
              : ListView.builder(
                  itemCount: _recentFiles.length,
                  itemBuilder: (context, index) {
                    final path = _recentFiles[index];
                    final name = path.split(Platform.pathSeparator).last; 
                    return ListTile(
                      leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                      title: Text(name),
                      subtitle: Text(path, maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () => _openPdf(path),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.grey),
                        onPressed: () => _deleteFromHistory(path),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class HistoryManager {
  static Future<void> saveProgress(String path, int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(path, page);
    List<String> recentFiles = prefs.getStringList('recent_files') ?? [];
    recentFiles.remove(path);
    recentFiles.insert(0, path);
    await prefs.setStringList('recent_files', recentFiles);
  }

  static Future<void> addToHistoryOnly(String path) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recentFiles = prefs.getStringList('recent_files') ?? [];
    if (!recentFiles.contains(path)) {
      recentFiles.add(path);
      await prefs.setStringList('recent_files', recentFiles);
    }
  }

  static Future<void> removeFile(String path) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recentFiles = prefs.getStringList('recent_files') ?? [];
    recentFiles.remove(path);
    await prefs.setStringList('recent_files', recentFiles);
    await prefs.remove(path);
  }

  static Future<List<String>> getRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('recent_files') ?? [];
  }

  static Future<int> getSavedPage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(path) ?? 1;
  }
}
