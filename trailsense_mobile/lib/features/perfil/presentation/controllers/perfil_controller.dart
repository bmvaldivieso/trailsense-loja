import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/repositories/perfil_repository.dart';
import '../../../auth/data/models/usuario_model.dart';

class PerfilController extends GetxController {
  final PerfilRepository _repository = PerfilRepository();

  final Rx<UsuarioModel?> usuario = Rx<UsuarioModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString genero = ''.obs;
  final Rx<File?> nuevaFoto = Rx<File?>(null);

  final nombreCtrl = TextEditingController();
  final apellidoCtrl = TextEditingController();
  final cedulaCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
  final diaCtrl = TextEditingController();
  final mesCtrl = TextEditingController();
  final anioCtrl = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    cargarPerfil();
  }

  Future<void> cargarPerfil() async {
    try {
      isLoading.value = true;
      final u = await _repository.obtenerPerfil();
      usuario.value = u;
      nombreCtrl.text = u.nombre ?? '';
      apellidoCtrl.text = u.apellido ?? '';
      cedulaCtrl.text = u.cedula ?? '';
      telefonoCtrl.text = u.telefono ?? '';
      genero.value = u.genero ?? '';
      if (u.fechaNacimiento != null) {
        diaCtrl.text = u.fechaNacimiento!.day.toString().padLeft(2, '0');
        mesCtrl.text = u.fechaNacimiento!.month.toString().padLeft(2, '0');
        anioCtrl.text = u.fechaNacimiento!.year.toString();
      }
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cargar tu perfil');
    } finally {
      isLoading.value = false;
    }
  }

  String get diaNacimientoDisplay {
    final fecha = usuario.value?.fechaNacimiento;
    return fecha != null ? fecha.day.toString().padLeft(2, '0') : '--';
  }

  String get mesNacimientoDisplay {
    final fecha = usuario.value?.fechaNacimiento;
    return fecha != null ? fecha.month.toString().padLeft(2, '0') : '--';
  }

  String get anioNacimientoDisplay {
    final fecha = usuario.value?.fechaNacimiento;
    return fecha != null ? fecha.year.toString() : '----';
  }

  void setGenero(String val) => genero.value = val;

  Future<void> seleccionarFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) nuevaFoto.value = File(picked.path);
  }

  Future<void> guardarPerfil() async {
    try {
      isSaving.value = true;
      DateTime? fecha;
      if (diaCtrl.text.isNotEmpty &&
          mesCtrl.text.isNotEmpty &&
          anioCtrl.text.isNotEmpty) {
        fecha = DateTime(
          int.parse(anioCtrl.text),
          int.parse(mesCtrl.text),
          int.parse(diaCtrl.text),
        );
      }

      final actualizado = await _repository.actualizarPerfil(
        nombre: nombreCtrl.text,
        apellido: apellidoCtrl.text,
        cedula: cedulaCtrl.text,
        telefono: telefonoCtrl.text,
        genero: genero.value,
        fechaNacimiento: fecha,
        fotoPerfil: nuevaFoto.value,
      );

      usuario.value = actualizado;
      nuevaFoto.value = null;
      Get.back();
      Get.snackbar('Perfil', 'Datos actualizados correctamente');
    } on DioException catch (e) {
      Get.snackbar('Error', _obtenerMensajeErrorPerfil(e));
    } catch (e) {
      Get.snackbar('Error', 'No se pudo actualizar tu perfil');
    } finally {
      isSaving.value = false;
    }
  }

  // ============================================================
  // MANEJO DE ERRORES
  // ============================================================

  String _obtenerMensajeErrorPerfil(DioException error) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final cedulaError = data['cedula'];
      if (cedulaError is List && cedulaError.isNotEmpty) {
        return cedulaError.first.toString();
      }

      final mensaje = data['detail'] ?? data['message'];
      if (mensaje is String && mensaje.isNotEmpty) return mensaje;
    }

    return 'No se pudo actualizar tu perfil.';
  }

  @override
  void onClose() {
    nombreCtrl.dispose();
    apellidoCtrl.dispose();
    cedulaCtrl.dispose();
    telefonoCtrl.dispose();
    diaCtrl.dispose();
    mesCtrl.dispose();
    anioCtrl.dispose();
    super.onClose();
  }
}
