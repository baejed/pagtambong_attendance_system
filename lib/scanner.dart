import 'package:flutter/material.dart';
import 'package:pagtambong_attendance_system/generic_component.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:fluttertoast/fluttertoast.dart';


class ScannerPage extends StatefulWidget {

  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();

}

class _ScannerPageState extends State<ScannerPage>{

  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  String _output = "none";

  @override
  Widget build(BuildContext context){

    return Scaffold(
      appBar: const DefaultAppBar(),
      body: Center(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {

            final Size layoutSize = constraints.biggest;
            const double scanWindowHeight = 100;
            const double scanWindowWidth = 300;

            final Rect scanWindow = Rect.fromCenter(
              center: layoutSize.center(Offset.zero),
              width: scanWindowWidth,
              height: scanWindowHeight,
            );

            return MobileScanner(
              controller: controller,
              scanWindow: scanWindow,
              overlayBuilder: (context, constraints) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Align(
                          child: Container(
                            width: scanWindowWidth,
                            height: scanWindowHeight,
                            decoration: BoxDecoration(
                              border: Border.all()
                            ),
                            child: Text(_output),
                          ),
                        )
                      ),
                      Column(
                        children: [
                          Container(
                            color: Colors.blue[700],
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: GestureDetector(
                                onTap: () {
                                  Fluttertoast.showToast(
                                    msg: "TAPPED",
                                    toastLength: Toast.LENGTH_SHORT,
                                    gravity: ToastGravity.CENTER,
                                    timeInSecForIosWeb: 1,
                                    backgroundColor: Colors.red,
                                    textColor: Colors.white,
                                    fontSize: 16.0
                                  );
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      "Event name",
                                      style: TextStyle(
                                        fontSize: 30
                                      ),
                                    ),
                                    Spacer(),
                                    Icon(Icons.arrow_downward_rounded)
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                );
              },
              onDetect: (barcodes) {
                String output = barcodes.barcodes.first.displayValue!;

                setState(() {
                  _output = output.substring(1, output.length);
                });

              },
            );
          }
        )
      ),
      bottomNavigationBar: const DefaultBottomNavbar(
        index: 0
      ),
    );
  }

}