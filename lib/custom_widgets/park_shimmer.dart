import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ParkShimmer extends StatelessWidget {
  const ParkShimmer({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Container(
              padding: const EdgeInsetsDirectional.all(5),
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(7)),
                  border: Border.all(color: Colors.grey.shade200)),
              child: Shimmer.fromColors(
                highlightColor: Colors.grey.shade100,
                baseColor: Colors.grey.shade300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Container(
                          height: 15,
                          width: MediaQuery.of(context).size.width / 2.5,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          height: 10,
                          width: 80,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 10,
                      width: 180,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(70)),
                                  color: Colors.white,
                                ),
                                height: 30,
                                width: 30,
                              ),
                              Container(width: 10),
                              Container(
                                width: 60,
                                height: 10,
                                color: Colors.white,
                              )
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(70)),
                                  color: Colors.white,
                                ),
                                height: 30,
                                width: 30,
                              ),
                              Container(width: 10),
                              Container(
                                width: 60,
                                height: 10,
                                color: Colors.white,
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        color: Colors.white,
                      ),
                      height: 10,
                      width: 240,
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const Divider(
          endIndent: 1,
          height: 5,
        ),
      ),
    );
  }
}
