import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final client = Supabase.instance.client;

  // USUARIOS
  static Future<Map<String, dynamic>?> getUserByPhone(String phone) async {
    try {
      final response = await client
          .from('users')
          .select()
          .eq('telefono', phone)
          .maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Error al obtener usuario: ${e.toString()}');
    }
  }

  static Future<void> updateUserPoints(String userId, int newPoints) async {
    await client
        .from('users')
        .update({'puntos': newPoints})
        .eq('id', userId);
  }

  static Future<void> registerPurchase(
      String userId, double amount, int pointsEarned) async {
    await client.from('transactions').insert({
      'user_id': userId,
      'monto_compra': amount,
      'puntos_otorgados': pointsEarned,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ADMIN
  static Future<Map<String, dynamic>?> getAdminByEmail(String email) async {
    try {
      final response = await client
          .from('admin')
          .select()
          .eq('email', email)
          .maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Error al obtener admin: ${e.toString()}');
    }
  }

  // PREMIOS
  static Future<List<Map<String, dynamic>>> getActiveRewards() async {
    final response = await client
        .from('rewards')
        .select()
        .eq('activo', true)
        .order('created_at', ascending: false);
    return response;
  }

  static Future<void> createReward(
      String name, int requiredPoints, bool active) async {
    await client.from('rewards').insert({
      'nombre': name,
      'puntos_necesarios': requiredPoints,
      'activo': active,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // BENEFICIOS
  static Future<List<Map<String, dynamic>>> getActivePartners() async {
    final response = await client
        .from('partners')
        .select()
        .eq('activo', true)
        .order('created_at', ascending: false);
    return response;
  }

  // OPERACIONES ESPECIALES
  static Future<void> redeemReward(
      String userId, String rewardId, int pointsNeeded, int newPoints) async {
    await client.rpc('redeem_reward', params: {
      'user_id': userId,
      'reward_id': rewardId,
      'points_needed': pointsNeeded,
      'new_points': newPoints,
    });
  }

  // Método genérico para operaciones CRUD
  static Future<List<Map<String, dynamic>>> fetchData(
    String tableName, {
    String? filterColumn,
    dynamic filterValue,
    String? orderBy,
    bool ascending = false,
  }) async {
    final query = client.from(tableName).select();

    if (filterColumn != null && filterValue != null) {
      query.eq(filterColumn, filterValue);
    }

    if (orderBy != null) {
      query.order(orderBy, ascending: ascending);
    }

    return await query;
  }
}