import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_to_busan_handson/model.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

String url = "http://127.0.0.1:3000";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Go to Busan Hands-on'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DateTime _selectedDateTime = DateTime.now();
  TextEditingController textEditingController = TextEditingController();
  List<Items> diaryItems = [];

  fetchDiary() async {
    final uri = Uri.http(
      '127.0.0.1:3000',
      '/diary',
      {
        // 'search': "2023-04-30",
        'search': _selectedDateTime.toString()
      },
    );
    final resp = await http.get(uri);
    print(resp.body);
    final items =
        ResponseModel.fromJson(jsonDecode(utf8.decode(resp.bodyBytes)));
    setState(() {
      diaryItems.clear();
      diaryItems.addAll(items.items ?? []);
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchDiary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: () async {
              fetchDiary();
            },
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          CalendarDatePicker(
            initialDate: DateTime.now(),
            firstDate: DateTime(2022),
            lastDate: DateTime.now(),
            currentDate: _selectedDateTime,
            onDateChanged: (d) {
              _selectedDateTime = d;
              fetchDiary();
              setState(() {});
            },
          ),
          const Divider(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await fetchDiary();
              },
              child: diaryItems.isEmpty
                  ? Center(
                      child: Text("기록이 없습니다."),
                    )
                  : ListView.separated(
                      separatorBuilder: (context, _) {
                        return Divider();
                      },
                      itemCount: diaryItems.length,
                      itemBuilder: (context, index) {
                        print(diaryItems.length);
                        return Dismissible(
                          direction: DismissDirection.endToStart,
                          key: UniqueKey(),
                          onDismissed: (d) {
                            print(d);
                            setState(() {});
                          },
                          confirmDismiss: (b) async {
                            print("confirmDismiss");
                            final result = await showAdaptiveDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog.adaptive(
                                    title: Text("삭제할까요?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(false);
                                        },
                                        child: Text("취소"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(true);
                                        },
                                        child: Text("진행"),
                                      )
                                    ],
                                  );
                                });

                            return result;
                          },
                          background: Container(
                            color: Colors.red,
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          child: ListTile(
                            title: Text(diaryItems[index].note ?? ""),
                            subtitle:
                                Text(diaryItems[index].dt.toString() ?? ""),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
              isDismissible: false,
              enableDrag: false,
              context: context,
              builder: (context) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        "다이어리 작성",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 24),
                      ),
                      Expanded(
                        child: TextField(
                          controller: textEditingController,
                          expands: true,
                          decoration: InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          textAlignVertical: TextAlignVertical.top,
                          maxLines: null,
                          maxLength: 140,
                          keyboardType: TextInputType.multiline,
                        ),
                      ),
                      ButtonBar(
                        children: [
                          ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text("취소")),
                          ElevatedButton(
                              onPressed: () async {
                                if (textEditingController.text.isEmpty) {
                                  return;
                                }
                                final resp = await http.post(
                                  Uri.parse(
                                    url + "/diary",
                                  ),
                                  body: {
                                    "uuid": const Uuid().v4(),
                                    "note": textEditingController.text,
                                    "dt": _selectedDateTime.toString(),
                                    "timestamp": DateTime.now()
                                        .millisecondsSinceEpoch
                                        .toString(),
                                  },
                                );
                                textEditingController.clear();

                                print(resp.body);
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                              child: const Text("저장"))
                        ],
                      ),
                      const SizedBox(
                        height: 24,
                      )
                    ],
                  ),
                );
              });
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
