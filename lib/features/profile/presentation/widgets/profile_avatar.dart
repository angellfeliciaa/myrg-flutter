import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Keeps the original Figma photo crop until the user selects a local photo.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.name,
    required this.isFixture,
    this.bytes,
    this.url,
    this.size = 64,
    super.key,
  });

  final String name;
  final bool isFixture;
  final Uint8List? bytes;

  /// Backend mode: the photo stored at MyRG. A freshly picked photo ([bytes]) wins.
  final String? url;
  final double size;

  Widget get _initials => CircleAvatar(
    radius: size / 2,
    backgroundColor: AppColors.primarySoft,
    child: Text(
      name.trim().isEmpty ? 'RG' : name.trim().characters.first.toUpperCase(),
      style: TextStyle(fontSize: size * .375, color: AppColors.primary),
    ),
  );

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'Foto profil $name',
    child: ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: bytes != null
            ? Image.memory(
                bytes!,
                fit: BoxFit.cover,
                cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                    .ceil(),
                errorBuilder: (_, _, _) => _initials,
              )
            : url != null
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                // One decode size for every place the photo appears (Akun 64, Edit Akun 112):
                // a size per place would download the same photo once per size.
                cacheWidth: 336,
                errorBuilder: (_, _, _) => _initials,
              )
            : isFixture
            ? OverflowBox(
                alignment: Alignment.topCenter,
                maxWidth: size,
                maxHeight: size * 1.3933,
                child: Image.asset(
                  'assets/images/profile_avatar.png',
                  width: size,
                  height: size * 1.3933,
                  fit: BoxFit.fill,
                ),
              )
            : _initials,
      ),
    ),
  );
}
