import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:charts_flutter/flutter.dart' as charts;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Screen 1',
      home: Builder(
        builder: (context) {
          return Screen1();
        },
      ),
    );
  }
}

class Screen1 extends StatefulWidget {
  @override
  _Screen1State createState() => _Screen1State();
}

class _Screen1State extends State<Screen1> {
  List<String> products = [
    "20mm SM", "16mm SM", "12mm SM", "10mm SM", "8mm SM", "20mm AS",
    "16mm AS", "12mm AS", "10mm AS", "8mm AS",
    "Local Wire", "Tata Wire", "Cover block", "Patiya", "Ch 2.2K", "6mm TMT", "6mm ring",
    "5mm", "2mm", "1mm", "Garter 4K", "Garter 3K", "Garter 2.5K", "Tee 2.7",
    "Tee 2.2", "AL 50/6", "AL 40/6", "AL 35/6", "AL 35/5", "AL 25/3"
  ];
  List<String> filteredProducts = [];
  List<Map<String, dynamic>> tableData = [];
  bool isSheet1Active = false;

  @override
  void initState() {
    filteredProducts = products;
    super.initState();
  }

  void navigateToScreen3() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Screen3.withSampleData()),
    );
  }

  

  ThemeData _getTheme() {
    return isSheet1Active
        ? ThemeData(primarySwatch: Colors.blue)
        : ThemeData(primarySwatch: Colors.orange);
  }

  void filterProducts(String query) {
    setState(() {
      filteredProducts = products
          .where((product) => product.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void navigateToScreen2(String selectedProduct) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Screen2(
          selectedProduct: selectedProduct,
          onSave: (data) {
            setState(() {
              tableData.add(data);
            });
          },
          isSheet1Active: isSheet1Active,
        ),
      ),
    );
  }

  Future<void> writeToExcel(List<Map<String, dynamic>> data) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String excelPath = '${appDocDir.path}/sales.xlsx';

    var file = File(excelPath);
    bool fileExists = await file.exists();

    var excel = Excel.createExcel();
    if (fileExists) {
      var bytes = File(excelPath).readAsBytesSync();
      excel = Excel.decodeBytes(bytes);
    }

    Sheet sheetObject;
    if (isSheet1Active) {
      sheetObject = excel['Sheet2'];
    } else {
      sheetObject = excel['Sheet1'];
    }

    int rowInd = 1;
    while (sheetObject.cell(CellIndex.indexByString('A$rowInd')).value != null) {
      rowInd++;
    }
    sheetObject.cell(CellIndex.indexByString('A$rowInd')).value = DateTime.now().toString();

    data.forEach((entry) {
      String productName = entry['name'];
      double weight = entry['weight'];

      int productColumnIndex = 1;
      while ((sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: productColumnIndex, rowIndex: 0)).value).toString() != productName.toString()) {
        productColumnIndex++;
      }
      int r = 0;
      while (sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: productColumnIndex, rowIndex: r)).value != null) {
        r++;
      }
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: productColumnIndex, rowIndex: r)).value = weight;
    });

    List<int>? encodedExcel = excel.encode();
    if (encodedExcel != null) {
      file.writeAsBytesSync(encodedExcel);
    }
  }

  void launchExcel() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String excelPath = '${appDocDir.path}/sales.xlsx';

    File file = File(excelPath);
    if (await file.exists()) {
      await launch(excelPath);
    }
  }

    double calculateTotalWeight() {
    double totalWeight = 0.0;
    for (var data in tableData) {
      if (data['weight'] != null) {
        totalWeight += data['weight'];
      }
    }
    return totalWeight;
  }

      double calculateTotalRate() {
    double totalWeight = 0.0;
    for (var data in tableData) {
      if (data['rate'] != null) {
        totalWeight += data['rate'];
      }
    }
    return totalWeight;
  }

        double calculateTotalTotal() {
    double totalWeight = 0.0;
    for (var data in tableData) {
      if (data['total'] != null) {
        totalWeight += data['total'];
      }
    }
    return totalWeight;
  }

 @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Available Goods',
      theme: _getTheme(),
      home: Scaffold(
        appBar: AppBar(
          title: Text(isSheet1Active ? 'Purchase Sheet' : 'Sales Sheet'),
          actions: [
            SizedBox(width: 30),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Screen3.withSampleData()),
                );
              },
              icon: Icon(Icons.analytics),
            ),
            SizedBox(width: 30),
            Switch(
              value: isSheet1Active,
              onChanged: (newValue) {
                setState(() {
                  isSheet1Active = newValue;
                });
              },
            ),
            SizedBox(width: 30),
            IconButton(
              onPressed: () {
                launchExcel();
              },
              icon: Icon(Icons.description),
            ),
          ],
        ),
        body: Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search for goods',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) {
                          filterProducts(value);
                        },
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: () {
                                navigateToScreen2(filteredProducts[index]);
                              },
                              child: Text(
                                filteredProducts[index],
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Goods Table',
                      style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 300, height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: [
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Weight')),
                            DataColumn(label: Text('Rate')),
                            DataColumn(label: Text('Total')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: [
                            ...tableData.map((data) {
                              return DataRow(cells: [
                                DataCell(Text(data['name'] ?? '')),
                                DataCell(Text(data['weight']?.toString() ?? '')),
                                DataCell(Text(data['rate']?.toString() ?? '')),
                                DataCell(Text(data['total']?.toString() ?? '')),
                                DataCell(Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () {
                                        setState(() {
                                          tableData.remove(data);
                                        });
                                      },
                                    ),
                                  ],
                                )),
                              ]);
                            }).toList(),
                            DataRow(cells: [
                              DataCell(Text(
                                'Total',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              )),
                              DataCell(Text("")),
                              DataCell(Text("")),
                              DataCell(Text(
                                calculateTotalTotal().toStringAsFixed(2),
                                style: TextStyle(fontWeight: FontWeight.bold),                                 
                              )),
                              DataCell(Text('')),
                            ]),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        await writeToExcel(tableData);
                        setState(() {
                          tableData.clear();
                        });
                      },
                      child: Text('Save'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Screen2 extends StatefulWidget {
  final String selectedProduct;
  final Function(Map<String, dynamic>) onSave;
  final bool isSheet1Active;

  const Screen2({
    Key? key,
    required this.selectedProduct,
    required this.onSave,
    required this.isSheet1Active,
  }) : super(key: key);

  @override
  _Screen2State createState() => _Screen2State();
}

class _Screen2State extends State<Screen2> {
  double weight = 0.0;
  double rate = 0.0;
  double total = 0.0;

  void calculateTotal() {
    setState(() {
      total = weight * rate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSheet1Active
            ? 'Details for ${widget.selectedProduct} in Purchase'
            : 'Details for ${widget.selectedProduct} in Sales'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Product: ${widget.selectedProduct}',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter Weight',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  weight = double.tryParse(value) ?? 0.0;
                });
              },
            ),
            SizedBox(height: 20),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter Rate',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  rate = double.tryParse(value) ?? 0.0;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                calculateTotal();
                Map<String, dynamic> newData = {
                  'name': widget.selectedProduct,
                  'weight': weight,
                  'rate': rate,
                  'total': total,
                };
                widget.onSave(newData);
                Navigator.pop(context);
              },
              child: Text('Insert into the table'),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class Screen3 extends StatelessWidget {
  final List<charts.Series<OrdinalSales, String>> seriesList;
  final bool animate;

  Screen3(this.seriesList, {required this.animate});

  factory Screen3.withSampleData() {
    return Screen3(
      _createSampleData(),
      animate: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sci-Fi Dashboard'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 300.0,
              padding: EdgeInsets.all(16.0),
              child: charts.BarChart(
                seriesList,
                animate: animate,
              ),
            ),
            Container(
              height: 300.0,
              padding: EdgeInsets.all(16.0),
              child: charts.PieChart(
                seriesList,
                animate: animate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<charts.Series<OrdinalSales, String>> _createSampleData() {
    final data = [
      OrdinalSales('2018', 100),
      OrdinalSales('2019', 150),
      OrdinalSales('2020', 200),
      OrdinalSales('2021', 75),
      OrdinalSales('2022', 300),
    ];

    return [
      charts.Series<OrdinalSales, String>(
        id: 'Sales',
        domainFn: (OrdinalSales sales, _) => sales.year,
        measureFn: (OrdinalSales sales, _) => sales.sales,
        data: data,
      )
    ];
  }
}

class OrdinalSales {
  final String year;
  final double sales;

  OrdinalSales(this.year, this.sales);
}

