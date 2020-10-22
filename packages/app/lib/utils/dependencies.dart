import 'package:flutter/material.dart';
import 'package:pub_api_client/pub_api_client.dart';

final client = PubClient();

class PackageDetail {
  @required
  final PubPackage package;
  @required
  final PackageScore score;
  PackageDetail({this.package, this.score});
}

Map<String, PubPackage> mapPackages;

/// Fetches all packages info from pub.dev
Future<List<PackageDetail>> fetchAllDependencies(Set<String> packages) async {
  final pkgFutures = <Future<PubPackage>>[];

  for (var pkg in packages) {
    pkgFutures.add(client.getPackage(pkg));
  }
  final packagesRes = await Future.wait(pkgFutures);

  final validPubPkgs = packagesRes.where((dep) => dep.name != null).toList();

  return fetchAllScores(validPubPkgs);
}

Future<List<PackageDetail>> fetchAllScores(List<PubPackage> packages) async {
  final pkgs = <Future<PackageDetail>>[];

  Future<PackageDetail> _assignScore(PubPackage package) async {
    final score = await client.getScore(package.name);
    return PackageDetail(
      score: score,
      package: package,
    );
  }

  for (var pkg in packages) {
    pkgs.add(_assignScore(pkg));
  }

  return await Future.wait(pkgs);
}
