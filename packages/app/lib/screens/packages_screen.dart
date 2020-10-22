import 'package:fvm_app/components/atoms/screen.dart';
import 'package:fvm_app/components/atoms/typography.dart';
import 'package:fvm_app/providers/project_dependencies.provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class PackagesScreen extends HookWidget {
  const PackagesScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final packages = useProvider(projectDependenciesProvider);

    return packages.when(
        data: (data) {
          return FvmScreen(
            title: 'Packages Screen',
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 60, 0, 0),
              child: DataTable(
                dataRowHeight: 100,
                columns: const [
                  DataColumn(label: Text('Name')),
                  // DataColumn(label: Text('Version'), numeric: true),
                  DataColumn(label: Text('Popularity'), numeric: true),
                  DataColumn(label: Text('Likes'), numeric: true),
                  DataColumn(label: Text('Health'), numeric: true),
                ],
                rows: data
                    .map((e) => DataRow(
                          key: Key(e.package.name),
                          cells: [
                            DataCell(Container(
                              child: ListTile(
                                title: Text(e.package.name),
                                subtitle: Text(
                                  e.package.description,
                                  maxLines: 2,
                                  style: Theme.of(context).textTheme.caption,
                                ),
                              ),
                            )),
                            // DataCell(Text(e.package.version)),
                            DataCell(Text(
                              (e.score.popularityScore * 100)
                                  .toStringAsFixed(2),
                            )),
                            DataCell(Text(
                              e.score.likeCount.toString(),
                            )),
                            DataCell(Text(
                              e.score.grantedPoints.toString(),
                            )),
                          ],
                        ))
                    .toList(),
              ),
            ),
          );
        },
        loading: () => const CircularProgressIndicator(),
        error: (_, __) => Container());
  }
}
