name: Build Android APK

on:
  push:
    branches:
      - main
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Java JDK
        uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: '17'

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: 'stable'

      - name: Create Clean App
        run: flutter create temp_app --org com.example.socialdownloader

      - name: Add Packages
        working-directory: temp_app
        run: flutter pub add dio path_provider youtube_explode_dart

      - name: Write Main File
        run: |
          cat << 'EOF' > temp_app/lib/main.dart
          import 'dart:io';
          import 'package:flutter/material.dart';
          import 'package:path_provider/path_provider.dart';
          import 'package:youtube_explode_dart/youtube_explode_dart.dart';

          void main() => runApp(const MyApp());

          class MyApp extends StatelessWidget {
            const MyApp({super.key});
            @override
            Widget build(BuildContext context) {
              return MaterialApp(
                title: 'مُنزل الفيديوهات',
                debugShowCheckedModeBanner: false,
                home: const DownloaderHome(),
              );
            }
          }

          class DownloaderHome extends StatefulWidget {
            const DownloaderHome({super.key});
            @override
            State<DownloaderHome> createState() => _DownloaderHomeState();
          }

          class _DownloaderHomeState extends State<DownloaderHome> {
            final TextEditingController _urlController = TextEditingController();
            bool _isDownloading = false;
            String _statusMessage = '';

            Future<void> _startDownload() async {
              final url = _urlController.text.trim();
              if (url.isEmpty) {
                setState(() => _statusMessage = 'يرجى إدخال رابط أولاً!');
                return;
              }
              setState(() {
                _isDownloading = true;
                _statusMessage = 'جاري التحميل...';
              });
              try {
                var yt = YoutubeExplode();
                var video = await yt.videos.get(url);
                var manifest = await yt.videos.streamsClient.getManifest(url);
                var streamInfo = manifest.muxed.sortByVideoQuality().first;
                var stream = yt.videos.streamsClient.get(streamInfo);
                
                Directory? directory = Directory('/storage/emulated/0/Download');
                if (!await directory.exists()) {
                  directory = await getExternalStorageDirectory();
                }

                String cleanTitle = video.title.replaceAll(RegExp(r'[^\w\s]+'), '');
                final file = File('${directory!.path}/$cleanTitle.mp4');
                var sink = file.openWrite();
                await for (var data in stream) {
                  sink.add(data);
                }
                await sink.close();
                yt.close();
                setState(() => _statusMessage = 'تم الحفظ في مجلد التنزيلات بنجاح!');
              } catch (e) {
                setState(() => _statusMessage = 'خطأ: $e');
              } finally {
                setState(() => _isDownloading = false);
              }
            }

            @override
            Widget build(BuildContext context) {
              return Scaffold(
                appBar: AppBar(title: const Text('مُنزل الفيديوهات')),
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(labelText: 'أدخل رابط يوتيوب', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isDownloading ? null : _startDownload,
                        child: Text(_isDownloading ? 'جاري التنزيل...' : 'تحميل الفيديو'),
                      ),
                      const SizedBox(height: 20),
                      Text(_statusMessage, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            }
          }
          EOF

      - name: Build APK
        working-directory: temp_app
        run: flutter build apk --release

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: SocialMediaDownloader-APK
          path: temp_app/build/app/outputs/flutter-apk/app-release.apk
        _statusMessage = 'تم التحميل بنجاح وحفظه في مجلد Downloads!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'حدث خطأ أثناء التحميل: $e';
      });
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مُنزل الفيديوهات والصوتيات'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'أدخل رابط الفيديو',
                hintText: 'https://...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilterChip(
                  label: const Text('فيديو (MP4)'),
                  selected: !_isAudioOnly,
                  onSelected: (val) => setState(() => _isAudioOnly = false),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: const Text('صوت (MP3)'),
                  selected: _isAudioOnly,
                  onSelected: (val) => setState(() => _isAudioOnly = true),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isDownloading ? null : _startDownload,
              icon: const Icon(Icons.download),
              label: Text(_isDownloading ? 'جاري التحميل...' : 'بدء التنزيل'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
            if (_isDownloading) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 12),
              Text('${(_progress * 100).toStringAsFixed(1)}%'),
            ],
            const SizedBox(height: 12),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
      setState(() {
        _statusMessage = 'تم التحميل بنجاح وحفظه في مجلد Downloads!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'حدث خطأ أثناء التحميل: $e';
      });
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مُنزل الفيديوهات والصوتيات'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'أدخل رابط الفيديو',
                hintText: 'https://...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilterChip(
                  label: const Text('فيديو (MP4)'),
                  selected: !_isAudioOnly,
                  onSelected: (val) => setState(() => _isAudioOnly = false),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: const Text('صوت (MP3)'),
                  selected: _isAudioOnly,
                  onSelected: (val) => setState(() => _isAudioOnly = true),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isDownloading ? null : _startDownload,
              icon: const Icon(Icons.download),
              label: Text(_isDownloading ? 'جاري التحميل...' : 'بدء التنزيل'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
            if (_isDownloading) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 12),
              Text('${(_progress * 100).toStringAsFixed(1)}%'),
            ],
            const SizedBox(height: 12),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

      setState(() {
        _statusMessage = 'تم التحميل بنجاح وحفظه في مجلد Downloads!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'حدث خطأ أثناء التحميل: $e';
      });
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مُنزل الفيديوهات والصوتيات'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'أدخل رابط الفيديو',
                hintText: 'https://...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilterChip(
                  label: const Text('فيديو (MP4)'),
                  selected: !_isAudioOnly,
                  onSelected: (val) => setState(() => _isAudioOnly = false),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: const Text('صوت (MP3)'),
                  selected: _isAudioOnly,
                  onSelected: (val) => setState(() => _isAudioOnly = true),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isDownloading ? null : _startDownload,
              icon: const Icon(Icons.download),
              label: Text(_isDownloading ? 'جاري التحميل...' : 'بدء التنزيل'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
            if (_isDownloading) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 12),
              Text('${(_progress * 100).toStringAsFixed(1)}%'),
            ],
            const SizedBox(height: 12),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

