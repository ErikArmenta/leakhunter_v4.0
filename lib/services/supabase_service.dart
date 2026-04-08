import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fuga.dart';
import '../models/audit_log.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  final _client = SupabaseConfig.client;

  Future<List<Fuga>> getFugas() async {
    try {
      final response = await _client.from('fugas').select();
      return (response as List).map((e) => Fuga.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching fugas: $e');
      return [];
    }
  }

  Future<Fuga?> insertFuga(Fuga fuga) async {
    try {
      final response = await _client.from('fugas').insert(fuga.toJson()).select().single();
      return Fuga.fromJson(response);
    } catch (e) {
      print('Error inserting fuga: $e');
      return null;
    }
  }

  Future<Fuga?> updateFuga(Fuga fuga) async {
    try {
      if (fuga.id == null) return null;
      final response = await _client
          .from('fugas')
          .update(fuga.toJson())
          .eq('id', fuga.id as Object)
          .select()
          .single();
      return Fuga.fromJson(response);
    } catch (e) {
      print('Error updating fuga: $e');
      return null;
    }
  }

  Future<bool> deleteFuga(int id) async {
    try {
      await _client.from('fugas').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error deleting fuga: $e');
      return false;
    }
  }

  Future<String?> uploadEvidencePhoto(Uint8List fileBytes, String fileName) async {
    try {
      final path = 'evidencia_$fileName';
      String mimeType = 'image/jpeg';
      final lowerName = fileName.toLowerCase();
      if (lowerName.endsWith('.mp4')) mimeType = 'video/mp4';
      else if (lowerName.endsWith('.mov')) mimeType = 'video/quicktime';
      else if (lowerName.endsWith('.webm')) mimeType = 'video/webm';
      else if (lowerName.endsWith('.png')) mimeType = 'image/png';

      await _client.storage.from('evidencia_fugas').uploadBinary(
        path,
        fileBytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: mimeType,
        ),
      );
      final publicUrl = _client.storage.from('evidencia_fugas').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      print('Error uploading photo: $e');
      return null;
    }
  }

  Future<List<AuditLog>> getFugaAuditLogs(int fugaId) async {
    try {
      final response = await _client
          .from('fugas_audit_log')
          .select()
          .eq('fuga_id', fugaId)
          .order('fecha', ascending: false);
      return (response as List).map((e) => AuditLog.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching audit logs: $e');
      return [];
    }
  }
}
