import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyber_launcher/features/mod_browser/providers/mod_browser_cubit.dart';
import 'package:kyber_launcher/features/mod_browser/providers/mod_search_cubit.dart';
import 'package:kyber_launcher/features/mod_browser/widgets/nmb_mod_tile.dart';
import 'package:kyber_launcher/features/nexusmods/dialogs/nexusmods_login.dart';
import 'package:kyber_launcher/features/nexusmods/services/nexusmods_service.dart';
import 'package:kyber_launcher/gen/fonts.gen.dart';
import 'package:kyber_launcher/injection_container.dart';
import 'package:kyber_launcher/shared/ui/buttons/button.dart';
import 'package:kyber_launcher/shared/ui/dialog/kyber_dialog.dart';
import 'package:nexus_gql/nexus_gql.dart';

class CategorizedModList extends StatefulWidget {
  const CategorizedModList({
    super.key,
    this.scrollController,
  });

  final ScrollController? scrollController;

  @override
  State<CategorizedModList> createState() => _CategorizedModListState();
}

class _CategorizedModListState extends State<CategorizedModList> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: sl.isReady<NexusModsService>(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error!.toString()));
        }

        if (!snapshot.hasData) {
          return const Center(child: ProgressRing());
        }

        if (sl.get<NexusModsService>().apiToken == null) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 20,
            children: [
              const Text('Please sign in to Nexus Mods to view mods'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  KyberButton(
                    text: 'LOGIN',
                    onPressed: () async {
                      await showKyberDialog(
                        context: context,
                        builder: (_) => const NexusmodsLogin(),
                        routeSettings: const RouteSettings(
                          name: 'nexusmods_login',
                        ),
                      );
                      context.read<ModBrowserCubit>().loadPage();
                      setState(() => null);
                    },
                  ),
                ],
              ),
            ],
          );
        }

        return BlocBuilder<ModSearchCubit, SearchState>(
          builder: (context, searchState) {
            if (searchState is SearchLoading) {
              return const Center(child: ProgressRing());
            }

            if (searchState is SearchLoaded) {
              if (searchState.results.isEmpty) {
                return Center(
                  child: Text(
                    'No mods found'.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: FontFamily.battlefrontUI,
                      fontSize: 17,
                    ),
                  ),
                );
              }

              return GridView.builder(
                controller: widget.scrollController,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 375,
                  childAspectRatio: 16 / 9,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 20,
                ),
                itemBuilder: (context, index) {
                  final mod = searchState.results[index];
                  return NMBModTile(
                    key: Key(mod.id),
                    mod: Query$modsByCategory$mods$nodes(
                      name: mod.name,
                      downloads: mod.downloads,
                      id: mod.id,
                      modId: mod.modId,
                      summary: mod.summary,
                      uid: mod.uid,
                      uploader: Query$modsByCategory$mods$nodes$uploader(
                        name: mod.uploader.name,
                        avatar: mod.uploader.avatar,
                      ),
                      author: mod.author,
                      fileSize: mod.fileSize,
                      pictureUrl: mod.pictureUrl,
                      thumbnailUrl: mod.thumbnailUrl,
                    ),
                  );
                },
                itemCount: searchState.results.length,
              );
            }

            if (searchState is SearchError) {
              return Center(child: Text(searchState.error));
            }

            return BlocBuilder<ModBrowserCubit, ModBrowserState>(
              builder: (context, state) {
                if (state is ModBrowserLoading &&
                    (state.mods == null || state.mods!.isEmpty)) {
                  return const Center(child: ProgressRing());
                }

                if (state is ModBrowserError) {
                  return Center(child: Text(state.error));
                }

                List<Query$modsByCategory$mods$nodes> mods = [];
                if (state is ModBrowserLoaded) {
                  mods = state.mods;
                } else if (state is ModBrowserLoading && state.mods != null) {
                  mods = state.mods!;
                }

                if (mods.isEmpty) {
                  return Center(
                    child: Text(
                      'No mods found'.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: FontFamily.battlefrontUI,
                        fontSize: 17,
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  controller: widget.scrollController,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 375,
                    childAspectRatio: 16 / 9,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 20,
                  ),
                  itemBuilder: (context, index) {
                    final mod = mods[index];
                    return NMBModTile(
                      key: Key(mod.id),
                      mod: mod,
                    );
                  },
                  itemCount: mods.length,
                );
              },
            );
          },
        );
      },
    );
  }
}
