import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const WebViewScreen({Key? key, required this.url, required this.title}) : super(key: key);

  @override
  State<WebViewScreen> createState() => WebViewScreenState();
}

class WebViewScreenState extends State<WebViewScreen> {
  static const Color pureWhite = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color primaryGreen = Color(0xFF1B7A43);

  late final WebViewController controller;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();

    var url = widget.url.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            isLoading = true;
            hasError = false;
          }),
          onPageFinished: (_) => setState(() => isLoading = false),
          onWebResourceError: (error) {
            // A page loads many sub-resources (ads, fonts, analytics,
            // third-party widgets) — any one of those failing still
            // triggers this callback even though the actual page is
            // fine. Only treat it as a real failure when the error is
            // for the main frame (the page itself), not a sub-resource.
            if (error.isForMainFrame != true) return;
            setState(() {
              isLoading = false;
              hasError = true;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pureWhite,
      appBar: AppBar(
        backgroundColor: pureWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Stack(
        children: [
          if (hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, color: textDark, size: 40),
                    const SizedBox(height: 12),
                    const Text('Could not load this website.', style: TextStyle(color: textDark, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(widget.url, style: TextStyle(color: textDark.withOpacity(0.6), fontSize: 12), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          hasError = false;
                          isLoading = true;
                        });
                        controller.reload();
                      },
                      child: const Text('Try again', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            )
          else
            WebViewWidget(controller: controller),
          if (isLoading && !hasError)
            const Center(child: CircularProgressIndicator(color: primaryGreen)),
        ],
      ),
    );
  }
}