import 'package:flutter/material.dart';

enum AppPlatform {
  youtube,
  instagram,
  tiktok,
  twitter,
  linkedin,
  facebook,
  reddit,
  github,
  medium,
  web,
}

class PlatformDetector {
  static AppPlatform detect(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return AppPlatform.web;

    final host = uri.host.toLowerCase();
    final domain = host.startsWith('www.') ? host.substring(4) : host;

    if (domain == 'youtube.com' || domain == 'youtu.be' || domain.endsWith('.youtube.com')) {
      return AppPlatform.youtube;
    }
    if (domain == 'instagram.com' || domain.endsWith('.instagram.com')) {
      return AppPlatform.instagram;
    }
    if (domain == 'tiktok.com' || domain.endsWith('.tiktok.com')) {
      return AppPlatform.tiktok;
    }
    if (domain == 'twitter.com' || domain == 'x.com' || domain.endsWith('.twitter.com')) {
      return AppPlatform.twitter;
    }
    if (domain == 'linkedin.com' || domain.endsWith('.linkedin.com')) {
      return AppPlatform.linkedin;
    }
    if (domain == 'facebook.com' || domain == 'fb.com' || domain.endsWith('.facebook.com')) {
      return AppPlatform.facebook;
    }
    if (domain == 'reddit.com' || domain.endsWith('.reddit.com')) {
      return AppPlatform.reddit;
    }
    if (domain == 'github.com' || domain.endsWith('.github.com') || domain.endsWith('.github.io')) {
      return AppPlatform.github;
    }
    if (domain == 'medium.com' || domain.endsWith('.medium.com')) {
      return AppPlatform.medium;
    }
    return AppPlatform.web;
  }
}

class PlatformInfo {
  final String label;
  final Color color;
  final IconData icon;

  const PlatformInfo({
    required this.label,
    required this.color,
    required this.icon,
  });

  static PlatformInfo forPlatform(AppPlatform platform) {
    switch (platform) {
      case AppPlatform.youtube:
        return const PlatformInfo(
          label: 'YouTube',
          color: Color(0xFFFF0000),
          icon: Icons.play_circle_outline,
        );
      case AppPlatform.instagram:
        return const PlatformInfo(
          label: 'Instagram',
          color: Color(0xFFE1306C),
          icon: Icons.camera_alt_outlined,
        );
      case AppPlatform.tiktok:
        return const PlatformInfo(
          label: 'TikTok',
          color: Color(0xFF010101),
          icon: Icons.music_note,
        );
      case AppPlatform.twitter:
        return const PlatformInfo(
          label: 'Twitter / X',
          color: Color(0xFF1DA1F2),
          icon: Icons.alternate_email,
        );
      case AppPlatform.linkedin:
        return const PlatformInfo(
          label: 'LinkedIn',
          color: Color(0xFF0A66C2),
          icon: Icons.work_outline,
        );
      case AppPlatform.facebook:
        return const PlatformInfo(
          label: 'Facebook',
          color: Color(0xFF1877F2),
          icon: Icons.people_outline,
        );
      case AppPlatform.reddit:
        return const PlatformInfo(
          label: 'Reddit',
          color: Color(0xFFFF4500),
          icon: Icons.forum_outlined,
        );
      case AppPlatform.github:
        return const PlatformInfo(
          label: 'GitHub',
          color: Color(0xFF181717),
          icon: Icons.code,
        );
      case AppPlatform.medium:
        return const PlatformInfo(
          label: 'Medium',
          color: Color(0xFF00AB6C),
          icon: Icons.article_outlined,
        );
      case AppPlatform.web:
        return const PlatformInfo(
          label: 'Web',
          color: Color(0xFF607D8B),
          icon: Icons.language,
        );
    }
  }
}
