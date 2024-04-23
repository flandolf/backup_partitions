import 'dart:io';
import 'package:path/path.dart' as path;
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
  List<String> partitionNamesPath = [];
  List<String> partitonNames = [];
  TextEditingController outputController = TextEditingController();
  bool flashing = false;

  Future<void> retrievePartitionNames() async {
    List<FileSystemEntity> files = backupFolder?.listSync() ?? [];

    setState(() {
      partitionNamesPath = files
          .where((element) => element.path.endsWith('.img'))
          .map((e) => e.path)
          .toList();
    });
  }

  Future<void> flashAllPartitions() async {
    setState(() {
      flashing = true;
    });
    for (String partitionName in partitionNamesPath) {
      await Process.run('fastboot', [
        'flash',
        partitionName,
        '${backupFolder?.path}\\$partitionName.img'
      ]).then((result) {
        outputController.text += '${result.stdout}\n';
      });
    }
    setState(() {
      flashing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("Flash partitions"),
            Text(
              " | ${backupFolder?.path ?? "No folder selected"} | ",
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              "Device: ${device.trim()}",
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Flashing Partitions Info"),
                        content: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                "Flashing partitions can be a dangerous thing. Please take caution while flashing. Do NOT unplug the device while flashing.\nDevices should be in fastbootd for less room for error.")
                          ],
                        ),
                        actions: [
                          TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text("Ok"))
                        ],
                      );
                    });
              },
              icon: const Icon(Icons.info))
        ],
      ),
      body: Column(
        children: [
          if (flashing)
            const Padding(
              padding: EdgeInsets.all(8),
              child: LinearProgressIndicator(),
            ),
          const SizedBox(
            height: 8,
          ),
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
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text("Lock bootloader"),
                          content: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                  "Are you sure you want to lock the bootloader? Ensure all partitions are at their stock state or you may need EDL. Continue?")
                            ],
                          ),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  Process.run("fastboot", ["flashing", "lock"]);
                                },
                                child: const Text("Yes")),
                            FilledButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text("No"))
                          ],
                        );
                      });
                },
                child: const Text('Lock Bootloader'),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text("Unlock bootloader"),
                          content: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                  "Are you sure you want to unlock the bootloader? All data will be wiped and your device won't be trusted. Continue?")
                            ],
                          ),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  Process.run(
                                      "fastboot", ["flashing", "unlock"]);
                                },
                                child: const Text("Yes")),
                            FilledButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text("No"))
                          ],
                        );
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
              FilledButton(
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
                FilledButton(
                  onPressed: flashAllPartitions,
                  child: const Text("Flash All"),
                ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  outputController.text = "";
                },
                child: const Text('Clear Output'),
              ),
            ],
          ),
          const SizedBox(
            height: 8,
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: partitionNamesPath.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(partitionNamesPath[index]),
                        subtitle: Text(
                            'Flashing to ${path.basenameWithoutExtension(partitionNamesPath[index])} partition'),
                        trailing: FilledButton(
                          onPressed: () {
                            setState(() {
                              flashing = true;
                            });
                            outputController.text +=
                                "Running 'fastboot flash ${path.basenameWithoutExtension(partitionNamesPath[index])} ${partitionNamesPath[index]}'";
                            Process.run('fastboot', [
                              'flash',
                              path.basenameWithoutExtension(
                                  partitionNamesPath[index]),
                              partitionNamesPath[index],
                            ]).then((result) {
                              outputController.text += result.stdout.toString();
                              outputController.text += result.stderr.toString();
                              setState(() {
                                flashing = false;
                              });
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
                  child: TextField(
                    controller: outputController,
                    readOnly: true,
                    maxLines: 100,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
