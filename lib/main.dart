import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مُنزل الفيديوهات',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
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
  bool _isAudioOnly = false;
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusMessage = '';

  Future<void> _startDownload() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _statusMessage = 'يرجى إدخال رابط أولاً!';
      });
      return;
    }

    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _statusMessage = 'جاري تحليل الرابط...';
    });

    try {
      await Permission.storage.request();

      var yt = YoutubeExplode();
      var video = await yt.videos.get(url);
      var manifest = await yt.videos.streamsClient.getManifest(url);

      StreamInfo streamInfo;
      String fileExt;

      if (_isAudioOnly) {
        streamInfo = manifest.audioOnly.withHighestBitrate();
        fileExt = 'mp3';
      } else {
        var videoStreams = manifest.muxed.sortByVideoQuality();
        streamInfo = videoStreams.first;
        fileExt = 'mp4';
      }

      var stream = yt.videos.streamsClient.get(streamInfo);
      
      Directory? directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory();
      }

      String cleanTitle = video.title.replaceAll(RegExp(r'[^\w\s]+'), '');
      final filePath = '${directory!.path}/$cleanTitle.$fileExt';
      final file = File(filePath);
      final fileStream = file.openWrite();

      var count = 0;
      var total = streamInfo.size.totalBytes;

      setState(() {
        _statusMessage = 'جاري التنزيل...';
      });

      await for (final data in stream) {
        count += data.length;
        fileStream.add(data);
        setState(() {
          _progress = count / total;
        });
      }

      await fileStream.flush();
      await fileStream.close();
      yt.close();

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

