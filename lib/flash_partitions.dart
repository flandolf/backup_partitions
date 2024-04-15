import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class FlashPartitions extends StatefulWidget {
  const FlashPartitions({super.key});

  @override
  State<FlashPartitions> createState() => _FlashPartitionsState();
}

class _FlashPartitionsState extends State<FlashPartitions> {
  String device = "Unknown";
  Directory? backupFolder;
  List<String> partitionNames = [];

  Future<void> retrievePartitionNames() async {
    List<FileSystemEntity> files = backupFolder?.listSync() ?? [];
    List<String> imgFiles = files
        .where((element) => element.path.endsWith('.img'))
        .map((e) => e.path)
        .toList();
    setState(() {
      partitionNames =
          imgFiles.map((e) => e.split('/').last.split('.').first).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flash Partitions'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Device: $device'),
                    const SizedBox(height: 4),
                    Text(
                        'Backup Folder: ${backupFolder?.path ?? "Not selected"}'),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Process.run('fastboot', ['devices']).then((result) {
                          setState(() {
                            device = result.stdout.toString();
                          });
                        });
                      },
                      child: const Text('Refresh'),
                    ),
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: () async {
                        String directoryPath = await FilePicker.platform
                            .getDirectoryPath() as String;
                        setState(() {
                          backupFolder = Directory(directoryPath);
                        });
                        retrievePartitionNames();
                      },
                      child: const Text('Select Backup Folder'),
                    ),
                    const SizedBox(width: 8),
                    if (backupFolder != null)
                      FilledButton(
                          onPressed: () {
                            //TODO: Implement flash all partitions
                          },
                          child: const Text("Flash All"))
                  ],
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            itemCount: partitionNames.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(partitionNames[index]),
                subtitle: Text(
                    'Flashing to ${partitionNames[index].split('\\').last} partition'),
                trailing: ElevatedButton(
                  onPressed: () {
                    Process.run('fastboot', [
                      'flash',
                      partitionNames[index],
                      '${backupFolder?.path}\\${partitionNames[index]}.img'
                    ]).then((result) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(result.stdout.toString()),
                      ));
                    });
                  },
                  child: const Text('Flash'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
