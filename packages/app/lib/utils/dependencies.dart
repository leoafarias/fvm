import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:fvm_app/utils/github_parse.dart';
import 'package:fvm_app/utils/http_cache.dart';
import 'package:pub_api_client/pub_api_client.dart';

// ignore: avoid_classes_with_only_static_members

final client = PubClient(client: CacheHttpClient());

class PackageDetail {
  @required
  final PubPackage package;
  @required
  final PackageScore score;
  @required
  final int count;
  PackageDetail({
    this.package,
    this.score,
    this.count,
  });

  int compareTo(PackageDetail other) {
    if (other.count > count) return -1;
    if (other.count == count) return 0;
    return 1;
  }
}

Map<String, PubPackage> mapPackages;

/// Fetches all packages info from pub.dev
Future<List<PackageDetail>> fetchAllDependencies(
    Map<String, int> packages) async {
  final pkgFutures = <Future<PubPackage>>[];

  for (var pkg in packages.keys) {
    pkgFutures.add(client.packageInfo(pkg));
  }
  final packagesRes = await Future.wait(pkgFutures);

  final validPubPkgs = packagesRes.where((dep) => dep.name != null).toList();

  return fetchAllScores(validPubPkgs, packages);
}

Future<List<PackageDetail>> fetchAllScores(
  List<PubPackage> validPubPkgs,
  Map<String, int> packages,
) async {
  final pkgs = <Future<PackageDetail>>[];

  Future<PackageDetail> _assignScore(PubPackage package, int count) async {
    final score = await client.packageScore(package.name);
    return PackageDetail(
      score: score,
      package: package,
      count: count,
    );
  }

  for (var pkg in validPubPkgs) {
    getRepoSlugFromPubspec(pkg.latestPubspec);
    pkgs.add(_assignScore(pkg, packages[pkg.name]));
  }

  return await Future.wait(pkgs);
}
