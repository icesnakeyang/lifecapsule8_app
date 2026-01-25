import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyProfile extends ConsumerStatefulWidget {
  const MyProfile({super.key});

  @override
  ConsumerState<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends ConsumerState<MyProfile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('My Profile')));
  }
}
