import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ListTileSkeleton extends StatelessWidget {
  const ListTileSkeleton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // return Shimmer.fromColors(
    //   baseColor: Colors.grey[300],
    //   highlightColor: Colors.grey[100],
    //   child: Padding(
    //     padding: const EdgeInsets.only(bottom: 8.0),
    //     child: Row(
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         Container(
    //           width: 48.0,
    //           height: 48.0,
    //           color: Colors.white,
    //         ),
    //         const Padding(
    //           padding: EdgeInsets.symmetric(horizontal: 8.0),
    //         ),
    //         Expanded(
    //           child: Column(
    //             crossAxisAlignment: CrossAxisAlignment.start,
    //             children: <Widget>[
    //               Container(
    //                 width: double.infinity,
    //                 height: 8.0,
    //                 color: Colors.white,
    //               ),
    //               const Padding(
    //                 padding: EdgeInsets.symmetric(vertical: 2.0),
    //               ),
    //               Container(
    //                 width: double.infinity,
    //                 height: 8.0,
    //                 color: Colors.white,
    //               ),
    //               const Padding(
    //                 padding: EdgeInsets.symmetric(vertical: 2.0),
    //               ),
    //               Container(
    //                 width: 40.0,
    //                 height: 8.0,
    //                 color: Colors.white,
    //               ),
    //             ],
    //           ),
    //         )
    //       ],
    //     ),
    //   ),
    // );
    return Container(
      height: _twoLineHight,
      width: double.infinity,
      padding: _twoLinePadding,
      child: Shimmer.fromColors(
        enabled: true,
        baseColor: Theme.of(context).disabledColor,
        highlightColor: Colors.white,
        child: Container(
          // height: _twoLineHight,
          // padding: _twoLinePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 10,
                width: 80,
                color: Theme.of(context).disabledColor,
              ),
              SizedBox(height: 10),
              Container(
                height: 10,
                width: 180,
                color: Theme.of(context).disabledColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static double _twoLineHight = 64;
  static EdgeInsets _twoLinePadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 16);
}
