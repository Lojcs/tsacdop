import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../util/extension_helper.dart';
import '../widgets/custom_widget.dart';
import 'licenses.dart';

class Libries extends StatelessWidget {
  const Libries({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.overlay,
      child: Scaffold(
        backgroundColor: context.surface,
        appBar: AppBar(
          title: Text(
            context.s.settingsLibraries,
            style: context.textTheme.titleLarge,
          ),
          leading: CustomBackButton(),
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: context.surface,
        ),
        body: SafeArea(
          child: Scrollbar(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.all(10.0),
                  ),
                  Container(
                    height: 30.0,
                    padding: EdgeInsets.symmetric(horizontal: 70),
                    alignment: Alignment.centerLeft,
                    child: Text('Google',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .copyWith(color: context.accentColor)),
                  ),
                  Column(
                    children: google.map<Widget>(
                      (e) {
                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 80),
                          onTap: () => e.link.launchUrl,
                          title: Text(e.name),
                          subtitle: Text(e.license),
                        );
                      },
                    ).toList(),
                  ),
                  Container(
                    height: 30.0,
                    padding: EdgeInsets.symmetric(horizontal: 70),
                    alignment: Alignment.centerLeft,
                    child: Text(context.s.fonts,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .copyWith(color: context.accentColor)),
                  ),
                  Column(
                    children: fonts.map<Widget>(
                      (e) {
                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 80),
                          onTap: () => e.link.launchUrl,
                          title: Text(e.name),
                          subtitle: Text(e.license),
                        );
                      },
                    ).toList(),
                  ),
                  Container(
                    height: 30.0,
                    padding: EdgeInsets.symmetric(horizontal: 70),
                    alignment: Alignment.centerLeft,
                    child: Text(context.s.plugins,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .copyWith(color: context.accentColor)),
                  ),
                  Container(
                    child: Column(
                      children: plugins.map<Widget>(
                        (e) {
                          return ListTile(
                            onTap: () => e.link.launchUrl,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 80),
                            title: Text(e.name),
                            subtitle: Text(e.license),
                          );
                        },
                      ).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
