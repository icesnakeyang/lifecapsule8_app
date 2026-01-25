import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoveLetterUserSearch extends ConsumerStatefulWidget {
  const LoveLetterUserSearch({super.key});

  @override
  ConsumerState<LoveLetterUserSearch> createState() =>
      _LoveLetterUserSearchState();
}

class _LoveLetterUserSearchState extends ConsumerState<LoveLetterUserSearch> {
  String _code = '';
  String? _foundNickname;

  Future<void> _search() async {
    // TODO: 调后端 apiSearchUserByCode(_code)
    // 这里先 mock：code 长度>=4 认为找到
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() {
      _foundNickname = _code.trim().length >= 4 ? 'User_${_code.trim()}' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final canSearch = _code.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Find user by code')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter userCode',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g. A1B2C3',
                ),
                onChanged: (v) => setState(() => _code = v),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canSearch ? _search : null,
                  child: const Text('Search'),
                ),
              ),
              const SizedBox(height: 12),
              if (_foundNickname != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Found: $_foundNickname')),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        'userCode': _code.trim(),
                        'nickname': _foundNickname,
                      });
                    },
                    child: const Text('Select this user'),
                  ),
                ),
              ] else ...[
                const Text(
                  'No result yet. If you cannot find them, go back and use email.',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
