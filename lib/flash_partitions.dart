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
        title: Row(
          children: [
            const Text("Flash partitions"),
            Text(" | ${backupFolder?.path ?? "No folder selected"} | ", style: const TextStyle(fontSize: 18),),
            Text("Device: $device", style: const TextStyle(fontSize: 18),),

          ],
        )
      ),
      body: Column(
        children: [
          const SizedBox(height: 8,),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                onPressed: () {
                  Process.run('fastboot', ['-w']).then((result) {
                    setState(() {
                      device = result.stdout.toString();
                    });
                  });
                },
                child: const Text('Wipe userdata'),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: () {
                  Process.run('fastboot', ['flashing', 'lock'])
                      .then((result) {
                    setState(() {
                      device = result.stdout.toString();
                    });
                  });
                },
                child: const Text('Lock Bootloader'),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: () {
                  Process.run('fastboot', ['flashing', 'unlock'])
                      .then((result) {
                    setState(() {
                      device = result.stdout.toString();
                    });
                  });
                },
                child: const Text('Unlock Bootloader'),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: () {
                  Process.run('fastboot', ['reboot', 'fastboot'])
                      .then((result) {
                    setState(() {
                      device = result.stdout.toString();
                    });
                  });
                },
                child: const Text('Reboot to fastbootd'),
              ),
              const SizedBox(width: 16),
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
          const SizedBox(height: 8,),
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
                        trailing: FilledButton(
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
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Output",
                      style: TextStyle(fontSize: 24),
                    ),
                    Expanded(
                      child: TextField(
                        controller: outputController,
                        readOnly: true,
                        maxLines: 100,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                      ),
                    )
                  ],
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
