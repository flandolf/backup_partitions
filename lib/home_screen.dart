import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  dynamic info = {};
  String saveFolder = '';
  List<String> partitions = [];
  List<String> selectedPartitions = [];
  String filter = '';
  String adbVersion = '';
  bool backupInProgress = false;
  TextEditingController outputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    checkPlatformTools(context);
    checkDevice();
    getInfo();
    checkRoot();
  }

  Future<void> downloadPlatformTools() async {
    if (Platform.isWindows) {
      String url =
          "https://dl.google.com/android/repository/platform-tools-latest-windows.zip";
      var response = await http.get(Uri.parse(url));
      File file = File('platform-tools.zip');
      file.writeAsBytesSync(response.bodyBytes);
      // Extract to C:\platform-tools
      Process.run('powershell', [
        'Expand-Archive',
        '-Path',
        'platform-tools.zip',
        '-DestinationPath',
        'C:\\platform-tools'
      ]);
      Process.run('setx', ['PATH', 'C:\\platform-tools', '/M']);
    } else if (Platform.isMacOS) {
      String url =
          "https://dl.google.com/android/repository/platform-tools-latest-darwin.zip";
      var response = await http.get(Uri.parse(url));
      File file = File('platform-tools.zip');
      file.writeAsBytesSync(response.bodyBytes);
      // Extract to /usr/local/bin/platform-tools
      Process.run('unzip',
          ['platform-tools.zip', '-d', '/usr/local/bin/platform-tools']);
    } else if (Platform.isLinux) {
      String url =
          "https://dl.google.com/android/repository/platform-tools-latest-linux.zip";
      var response = await http.get(Uri.parse(url));
      File file = File('platform-tools.zip');
      file.writeAsBytesSync(response.bodyBytes);
      Process.run('unzip',
          ['platform-tools.zip', '-d', '/usr/local/bin/platform-tools']);
    }
  }

  Future<void> checkRoot() async {
    outputController.text += 'Checking root access...\n';
    Process.run('adb', ['shell', 'su', 'echo', 'test']).then((value) {
      if (value.exitCode == 0) {
        outputController.text += 'Root access granted.\n';
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
        outputController.text += 'Root access denied.\n';
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Root Required'),
              content: const Text(
                  'This app requires root access to function properly. \n A device may also not be detected.'),
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

  Future<void> checkDevice() async {
    Process.run('adb', ['devices']).then((value) {
      outputController.text += value.stdout.toString();
      if (value.stdout.toString().contains('unauthorized')) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Unauthorized Device'),
              content:
                  const Text('Please authorize your device and try again.'),
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
      } else if (value.stdout.toString().split("\n")[1] == "") {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('No Device Found'),
              content: const Text('Please connect your device and try again.'),
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

  Future<void> checkPlatformTools(BuildContext c) async {
    await Process.run('adb', ['version']).then((value) => {
          if (value.exitCode == 1)
            {
              outputController.text += 'ADB not found.\n',
              showDialog(
                context: c,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('ADB Not Found'),
                    content: const Text(
                        'Please install ADB and add it to your PATH to continue.'),
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
              )
            }
          else
            {
              outputController.text += 'ADB found.\n',
              setState(() {
                adbVersion = value.stdout.toString().split('\n')[1];
              })
            }
        });
  }

  Future<void> getInfo() async {
    outputController.text += 'Getting device info...\n';
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

  void backupSelected() async {
    if (Directory(saveFolder).existsSync() == false) {
      return showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Backup Folder Required"),
              content: const Text("Please select a folder to back up to."),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Ok"))
              ],
            );
          });
    }

    setState(() {
      backupInProgress = true;
    });

    for (var partition in selectedPartitions) {
      if (partition == 'userdata') {
        if (context.mounted) {
          outputController.text += "Not backing up userdata partition.\n";
          return;
        }
      } else {
        partition = partition.trim();
        var sourcePath = '/dev/block/bootdevice/by-name/$partition';
        outputController.text += 'Backing up $partition.img...\n';
        try {
          var result = await Process.run('adb', [
            'shell',
            'su -c',
            'dd if=${sourcePath.trim()} of=/sdcard/$partition.img',
          ]);

          outputController.text += result.stderr.toString();

          if (result.exitCode == 0) {
            await Process.run('adb', [
              'pull',
              '/sdcard/$partition.img'.trim(),
              saveFolder
            ]).then((value) => {
                  Process.run('adb', [
                    'shell',
                    'su -c',
                    'rm /sdcard/$partition.img',
                  ])
                });

            outputController.text += 'Backup of $partition.img successful.\n';
          } else {
            outputController.text += 'Backup of $partition.img failed.\n';
          }
        } catch (e) {
          outputController.text += 'Error: $e\n';
        }
      }
    }

    setState(() {
      backupInProgress = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<String> filteredPartitions = partitions
        .where((partition) =>
            partition.toLowerCase().contains(filter.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Partition Backup - ADB $adbVersion - ${saveFolder == "" ? "No save folder selected" : saveFolder}'),
        actions: [
          IconButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("About this app"),
                        content: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("(c) 2024 Andrew Wang."),
                          ],
                        ),
                        actions: [
                          TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text("Ok")),
                          TextButton(
                              onPressed: () {
                                launchUrl(
                                    Uri.parse("https://github.com/flandolf"));
                              },
                              child: const Text("Github"))
                        ],
                      );
                    });
              },
              icon: const Icon(Icons.info))
        ],
      ),
      body: Column(
        children: [
          const SizedBox(
            height: 8,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  checkPlatformTools(context);
                  checkDevice();
                  getInfo();
                  checkRoot();
                },
                child: const Text("Refresh"),
              ),
              const SizedBox(width: 8),
              FilledButton(
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
              FilledButton(
                onPressed: () {
                  setState(() {
                    selectedPartitions = [];
                  });
                },
                child: const Text('Clear All Selected Partitions'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  setState(() {
                    selectedPartitions = partitions;
                  });
                },
                child: const Text('Select All Partitions'),
              ),
              const SizedBox(width: 8),
              if (selectedPartitions.isNotEmpty)
                FilledButton(
                    onPressed: backupSelected,
                    child: const Text("Backup Selected")),
              const SizedBox(width: 8),
              FilledButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/flash');
                  },
                  child: const Text("Flash Partitions Page")),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    outputController.clear();
                  });
                },
                child: const Text('Clear Output'),
              ),
            ],
          ),
          if (backupInProgress)
            const Padding(
              padding: EdgeInsets.all(8),
              child: LinearProgressIndicator(),
            )
          else
            const SizedBox(
              height: 8,
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
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Device Info'),
                      ),
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
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Avaliable Partitions'),
                      ),
                      Expanded(
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
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Selected Partitions'),
                      ),
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
                  flex: 2,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: outputController,
                          readOnly: true,
                          maxLines: 100,
                          decoration: const InputDecoration(
                            hintText: 'Output',
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10.0)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 16,
          )
        ],
      ),
    );
  }
}
