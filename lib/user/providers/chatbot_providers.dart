import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/env_config.dart';

class ChatMessage {
  final String role; 
  final String content;

  const ChatMessage({required this.role, required this.content});
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? errorMessage;

  const ChatState({this.messages = const [], this.isLoading = false, this.errorMessage});

  ChatState copyWith({List<ChatMessage>? messages, bool? isLoading, String? errorMessage}) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() => const ChatState();

  SupabaseClient get supabase => Supabase.instance.client;
  Future<String> buildContext() async {
    final products = await supabase
        .from('products')
        .select('name, category, brand, material, recyclable, reusable, certification, packaging, eco_score, price')
        .limit(200);

    final stores = await supabase
        .from('store_summary')
        .select('name, address, average_rating, rating_count, description')
        .limit(100);

    final productLines = (products as List).map((p) {
      return '- ${p['name']} | category: ${p['category'] ?? '—'} | brand: ${p['brand'] ?? '—'} | '
          'material: ${p['material']} | recyclable: ${p['recyclable']} | reusable: ${p['reusable']} | '
          'certification: ${p['certification']} | packaging: ${p['packaging']} | '
          'eco_score: ${p['eco_score']}/100 | price: \$${p['price']}';
    }).join('\n');

    final storeLines = (stores as List).map((s) {
      final rating = s['average_rating'] != null
          ? '${(s['average_rating'] as num).toStringAsFixed(1)} (${s['rating_count']} ratings)'
          : 'no ratings yet';
      return '- ${s['name']} | address: ${s['address']} | rating: $rating | ${s['description'] ?? ''}';
    }).join('\n');

    return 'PRODUCTS:\n$productLines\n\nSTORES:\n$storeLines';
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(role: 'user', content: text.trim());
    state = state.copyWith(messages: [...state.messages, userMessage], isLoading: true, errorMessage: null);

    try {
      final context = await buildContext();

      const systemPrompt = '''
You are the EcoWise shopping assistant. You help users compare eco-friendly
products, learn about materials and packaging, and find store info and
ratings — using ONLY the real product and store data provided below.

Rules:
- Answer strictly from the PRODUCTS and STORES data given in this context.
  If something isn't in the data, say you don't have that information —
  never invent products, prices, or ratings.
- You NEVER answer questions about admin accounts, user accounts, how many
  admins or users exist, login credentials, system architecture, or any
  app-internal/account information. If asked, say that's not something you
  can help with and redirect to products or stores.
- Keep answers short, friendly, and focused on helping the person shop
  sustainably.
''';

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${EnvConfig.groqApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'openai/gpt-oss-120b',
          'temperature': 0.4,
          'messages': [
            {'role': 'system', 'content': '$systemPrompt\n\n$context'},
            ...state.messages.map((m) => {'role': m.role, 'content': m.content}),
          ],
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Groq API error: ${response.statusCode} ${response.body}');
      }

      final data = jsonDecode(response.body);
      final reply = data['choices'][0]['message']['content'] as String;

      state = state.copyWith(
        messages: [...state.messages, ChatMessage(role: 'assistant', content: reply)],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Something went wrong: $e');
    }
  }

  void clear() {
    state = const ChatState();
  }
}

final chatNotifierProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);