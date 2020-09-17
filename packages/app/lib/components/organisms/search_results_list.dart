import 'package:fvm_app/components/atoms/sliver_section_header.dart';
import 'package:fvm_app/components/atoms/sliver_section.dart';
import 'package:fvm_app/components/molecules/project_item.dart';
import 'package:fvm_app/components/molecules/version_item.dart';
import 'package:fvm_app/providers/search_results_provider.dart';
import 'package:flutter/material.dart';

class SearchResultsList extends StatelessWidget {
  final SearchResults results;
  const SearchResultsList(this.results, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      constraints: BoxConstraints(
        minHeight: 4,
        maxHeight: MediaQuery.of(context).size.height / 1.2,
      ),
      child: CustomScrollView(
        slivers: <Widget>[
          SliverSection(
            shouldDisplay: results.channels.isNotEmpty,
            slivers: [
              SliverPersistentHeader(
                delegate: SectionHeaderDelegate(
                  title: 'Channels',
                  count: results.channels.length,
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return VersionItem(results.channels[index]);
                  },
                  childCount: results.channels.length,
                ),
              ),
            ],
          ),
          SliverSection(
            shouldDisplay: results.projects.isNotEmpty,
            slivers: [
              SliverPersistentHeader(
                delegate: SectionHeaderDelegate(
                  title: 'Projects',
                  count: results.projects.length,
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return ProjectItem(results.projects[index]);
                }, childCount: results.projects.length),
              ),
            ],
          ),
          SliverSection(
            shouldDisplay: results.stableReleases.isNotEmpty,
            slivers: [
              SliverPersistentHeader(
                delegate: SectionHeaderDelegate(
                  title: 'Stable Releases',
                  count: results.stableReleases.length,
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return VersionItem(results.stableReleases[index]);
                }, childCount: results.stableReleases.length),
              ),
            ],
          ),
          SliverSection(
            shouldDisplay: results.betaReleases.isNotEmpty,
            slivers: [
              SliverPersistentHeader(
                delegate: SectionHeaderDelegate(
                  title: 'Beta Releases',
                  count: results.betaReleases.length,
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return VersionItem(results.betaReleases[index]);
                }, childCount: results.betaReleases.length),
              ),
            ],
          ),
          SliverSection(
            shouldDisplay: results.devReleases.isNotEmpty,
            slivers: [
              SliverPersistentHeader(
                delegate: SectionHeaderDelegate(
                  title: 'Dev Releases',
                  count: results.devReleases.length,
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return VersionItem(results.devReleases[index]);
                }, childCount: results.devReleases.length),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
