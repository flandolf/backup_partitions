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
  TextEditingController outputController = TextEditingController();

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

  Future<void> flashAllPartitions() async {
    for (String partitionName in partitionNames) {
      await Process.run('fastboot', [
        'flash',
        partitionName,
        '${backupFolder?.path}\\$partitionName.img'
      ]).then((result) {
        outputController.text += '${result.stdout}\n';
      });
    }
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
                    ElevatedButton(
                      onPressed: () {
                        outputController.text = "";
                      },
                      child: const Text('Clear Output'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () async {
                        String? directoryPath =
                            await FilePicker.platform.getDirectoryPath();
                        if (directoryPath != null) {
                          setState(() {
                            backupFolder = Directory(directoryPath);
                          });
                          retrievePartitionNames();
                        }
                      },
                      child: const Text('Select Backup Folder'),
                    ),
                    const SizedBox(width: 8),
                    if (backupFolder != null)
                      ElevatedButton(
                        onPressed: flashAllPartitions,
                        child: const Text("Flash All"),
                      )
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: partitionNames.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(partitionNames[index]),
                        subtitle: Text(
                            'Flashing to ${partitionNames[index].split('\\').last} partition'),
                        trailing: ElevatedButton(
                          onPressed: () {
                            outputController.text +=
                                "Flashing ${partitionNames[index]}\n";
                            Process.run('fastboot', [
                              'flash',
                              partitionNames[index],
                              '${backupFolder?.path}\\${partitionNames[index]}.img'
                            ]).then((result) {
                              outputController.text = result.stdout.toString();
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(result.stdout.toString()),
                              ));
                            });
                          },
                          child: const Text('Flash'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: outputController,
                      readOnly: true,
                      maxLines: 100,
                      decoration: const InputDecoration(
                        labelText: 'Output',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
