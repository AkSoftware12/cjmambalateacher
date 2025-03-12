import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewPage extends StatefulWidget {
  final String url;
  const WebViewPage({super.key, required this.url});

  @override
  _WebViewPageState createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late WebViewController _controller;
  bool _isLoading = true;


  @override
  Widget build(BuildContext context) {
    String url = widget.url.toLowerCase();
    bool isDownloadable = url.endsWith('.jpg') || url.endsWith('.jpeg') || url.endsWith('.png') || url.endsWith('.gif') || url.endsWith('.pdf') || url.endsWith('.xls') || url.endsWith('.xlsx');

    if (url.endsWith('.jpg') || url.endsWith('.jpeg') || url.endsWith('.png') || url.endsWith('.gif')) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Image Viewer'),
          actions: isDownloadable ? [_buildDownloadButton(widget.url)] : [],
        ),
        body: Center(
          child: Image.network(widget.url, fit: BoxFit.contain),
        ),
      );
    } else if (url.endsWith('.pdf') || url.endsWith('.xls') || url.endsWith('.xlsx')) {
      String googleDocsUrl = 'https://docs.google.com/viewer?url=${Uri.encodeComponent(widget.url)}';
      return buildWebView(googleDocsUrl, 'Document Viewer', isDownloadable);
    } else {
      return buildWebView(widget.url, 'WebView', isDownloadable);
    }
  }

  Widget buildWebView(String url, String title, bool isDownloadable) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: isDownloadable ? [_buildDownloadButton(widget.url)] : [],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: WebView(
              initialUrl: url,
              javascriptMode: JavascriptMode.unrestricted,
              onWebViewCreated: (WebViewController webViewController) {
                _controller = webViewController;
              },
              onPageStarted: (String url) {
                print('Page started loading: $url');
                _isLoading = false; // Jab load start ho, progress bar dikhaye

              },
              onPageFinished: (String url) {
                print('Page finished loading: $url');
                _isLoading = false; // Jab load start ho, progress bar dikhaye

              },
              onWebResourceError: (WebResourceError error) {
                print('Error: ${error.description}');
                _isLoading = false; // Jab load start ho, progress bar dikhaye

              },
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildDownloadButton(String url) {
    return IconButton(
      icon: const Icon(Icons.download),
      onPressed: () async {
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not download file')),
          );
        }
      },
    );
  }
}
