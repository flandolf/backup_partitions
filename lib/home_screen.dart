import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  dynamic info = {};
  String saveFolder = '';
  List<String> partitions = [];
  List<String> selectedPartitions = [];
  String filter = '';

  Future<void> checkRoot() async {
    Process.run('adb', ['shell', 'su', 'echo', 'test']).then((value) {
      if (value.exitCode == 0) {
        info["Root"] = 'Yes';
        Process.run('adb', [
          'shell',
          'su -c',
          'ls',
          '/dev/block/bootdevice/by-name'
        ]).then((value) {
          setState(() {
            partitions = value.stdout.toString().trim().split('\n');
          });
        });
        Process.run('adb', ['shell', 'su -c', 'getprop', 'ro.boot.slot_suffix'])
            .then((value) {
          setState(() {
            info["Slot"] = value.stdout.toString().trim().replaceAll("_", "");
          });
        });
      } else {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Root Required'),
              content: const Text(
                  'This app requires root access to function properly.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                )
              ],
            );
          },
        );
      }
    });
  }

  Future<void> getInfo() async {
    Process.run('adb', ['shell', 'getprop', 'ro.product.model']).then((value) {
      setState(() {
        info["Model"] = value.stdout.toString().trim();
      });
    });
    Process.run('adb', ['shell', 'getprop', 'ro.product.odm.manufacturer'])
        .then((value) {
      setState(() {
        info["Manufacturer"] = value.stdout.toString().trim();
      });
    });
    Process.run('adb', ['shell', 'getprop', 'ro.product.odm.brand'])
        .then((value) {
      setState(() {
        info["Brand"] = value.stdout.toString().trim();
      });
    });
    Process.run('adb', ['shell', 'getprop', 'ro.product.odm.device'])
        .then((value) {
      setState(() {
        info["Device"] = value.stdout.toString().trim();
      });
    });
    Process.run('adb', ['shell', 'getprop', 'ro.product.cpu.abi'])
        .then((value) {
      setState(() {
        info["Arch"] = value.stdout.toString().trim();
      });
    });
    Process.run('adb', ['shell', 'getprop', 'ro.product.build.version.release'])
        .then((value) {
      setState(() {
        info["Android Version"] = value.stdout.toString().trim();
      });
    });
    Process.run('adb', ['shell', 'getprop', 'ro.product.build.version.release'])
        .then((value) {
      setState(() {
        info["Android Version"] = value.stdout.toString().trim();
      });
    });
  }

  Future<void> backupSelected() async {
    if (saveFolder.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a backup folder.')),
      );
      return;
    }
    if (Directory(saveFolder).listSync().isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Backup Folder Not Empty'),
            content: const Text(
                'The selected backup folder is not empty. Please select an empty folder.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              )
            ],
          );
        },
      );
      return;
    }
    for (var partition in selectedPartitions) {
      if (partition == 'userdata') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Not backing up userdata partition.')),
          );
          return;
        }
      } else {
        await Process.run('adb', [
          'shell',
          'su -c',
          'dd',
          'if=/dev/block/bootdevice/by-name/$partition'.trim(),
          'of=/sdcard/${partition.trim()}.img'.trim()
        ]).then((ProcessResult result) {
          if (result.exitCode == 0) {
            Process.run('adb', [
              'pull',
              '/storage/emulated/0/${partition.trim()}.img'.trim(),
              saveFolder
            ]).then((value) => print(value.stdout));

            Process.run('adb', [
              'shell',
              'su -c',
              'rm',
              '/sdcard/${partition.trim()}.img'.trim()
            ]).then((value) => print(value.stdout));

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Backup of $partition.img successful.')),
            );
          } else {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Backup Failed'),
                  content: Text('Backup of $partition.img failed.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('OK'),
                    )
                  ],
                );
              },
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<String> filteredPartitions = partitions
        .where((partition) =>
            partition.toLowerCase().contains(filter.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partition Backup'),
        actions: [
          IconButton(
            onPressed: () {
              getInfo();
              checkRoot();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(
            height: 16,
          ),
          Row(
            children: [
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  String? selectedDirectory =
                      await FilePicker.platform.getDirectoryPath();

                  if (selectedDirectory == null) {
                    return;
                  } else {
                    info["Backup Folder"] = selectedDirectory.split('/').last;
                    setState(() {
                      saveFolder = selectedDirectory;
                    });
                  }
                },
                child: const Text('Browse Backup Folder'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedPartitions = [];
                  });
                  setState(() {});
                },
                child: const Text('Clear All Partitions'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedPartitions = partitions;
                  });
                  setState(() {});
                },
                child: const Text('Select All Partitions'),
              ),
              const SizedBox(width: 8),
              if (selectedPartitions.isNotEmpty)
                ElevatedButton(
                    onPressed: backupSelected,
                    child: const Text("Backup Selected"))
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  filter = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search partitions...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(info.keys.elementAt(index)),
                              subtitle: Text(info.values.elementAt(index)),
                            );
                          },
                          itemCount: info.length,
                          shrinkWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(selectedPartitions[index]),
                            );
                          },
                          itemCount: selectedPartitions.length,
                          shrinkWrap: true,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: ListView.builder(
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: Checkbox(
                          value: selectedPartitions
                              .contains(filteredPartitions[index]),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                selectedPartitions
                                    .add(filteredPartitions[index]);
                              } else {
                                selectedPartitions
                                    .remove(filteredPartitions[index]);
                              }
                            });
                          },
                        ),
                        title: Text(filteredPartitions[index]),
                      );
                    },
                    itemCount: filteredPartitions.length,
                    shrinkWrap: true,
                    physics:
                        const AlwaysScrollableScrollPhysics(), // Ensure the ListView is always scrollable
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
