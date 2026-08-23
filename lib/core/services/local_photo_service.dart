import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../errors/error_mapper.dart';

/// Serviço para persistir e ler a foto do veículo **no dispositivo** (local),
/// evitando Firebase Storage (plano gratuito Spark).
class LocalPhotoService {
  /// Nome do subdiretório interno do app para fotos de veículos.
  static const _dirName = 'vehicle_photos';

  /// Salva a imagem escolhida (de ImagePicker) em `vehicle_photos/{vehicleId}.png`.
  /// Atualiza o arquivo se já existir. Retorna o **path local** salvo.
  Future<String> saveVehiclePhoto({
    required String vehicleId,
    required String tempFilePath,
  }) async {
    try {
      final temp = File(tempFilePath);
      if (!await temp.exists()) {
        throw Exception('Arquivo temporário não encontrado: $tempFilePath');
      }

      final dir = await _dir();
      final savedFile = File('${dir.path}/$vehicleId.png');
      await temp.copy(savedFile.path);
      return savedFile.path;
    } catch (e) {
      throw handleError(e, 'Não foi possível salvar a foto no dispositivo.');
    }
  }

  /// Retorna o arquivo de foto do veículo ou null se não existir.
  Future<File?> getVehiclePhoto(String vehicleId) async {
    try {
      final dir = await _dir();
      final file = File('${dir.path}/$vehicleId.png');
      return await file.exists() ? file : null;
    } catch (_) {
      return null;
    }
  }

  /// Remove a foto do veículo (usado ao excluir o veículo).
  Future<void> deleteVehiclePhoto(String vehicleId) async {
    final file = await getVehiclePhoto(vehicleId);
    await file?.delete();
  }

  Future<Directory> _dir() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${docsDir.path}/$_dirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}

/// Provider do serviço (singleton).
final localPhotoServiceProvider = Provider<LocalPhotoService>(
  (ref) => LocalPhotoService(),
);
