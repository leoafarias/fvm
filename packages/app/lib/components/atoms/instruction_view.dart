import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class InstructionView extends StatelessWidget {
  final String name;
  const InstructionView(this.name, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = ScrollController();
    return Scaffold(
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 400, maxHeight: 300),
              child: FutureBuilder(
                  future: rootBundle.loadString("assets/$name.md"),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Markdown(
                        controller: controller,
                        onTapLink: (href) async {
                          if (await canLaunch(href)) {
                            await launch(href);
                          } else {
                            throw 'Could not launch $href';
                          }
                        },
                        selectable: false,
                        data: snapshot.data,
                        imageDirectory: 'https://raw.githubusercontent.com',
                      );
                    }

                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }
}
