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

  @override
  Widget build(BuildContext context){

    return Scaffold(
      appBar: const DefaultAppBar(),
      body: Center(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {

            final Size layoutSize = constraints.biggest;
            const double scanWindowHeight = 100;
            const double scanWindowWidth = 400;

            final Rect scanWindow = Rect.fromCenter(
              center: layoutSize.center(Offset.zero),
              width: scanWindowWidth,
              height: scanWindowHeight,
            );

            return MobileScanner(
              controller: controller,
              scanWindow: scanWindow,
              overlayBuilder: (context, constraints) {
                return Container(
                  width: scanWindowWidth,
                  height: scanWindowHeight,
                  decoration: BoxDecoration(
                    border: Border.all()
                  ),
                );
              },
              onDetect: (barcodes) {
                String output = barcodes.barcodes.first.displayValue!;
                Fluttertoast.showToast(
                  msg: output.substring(1, output.length),
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.CENTER,
                  timeInSecForIosWeb: 1,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  fontSize: 16.0
                );
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