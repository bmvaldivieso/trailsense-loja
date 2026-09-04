import 'package:get/get.dart';
import '../../data/models/sesion_model.dart';
import '../../data/repositories/sesiones_repository.dart';

class DetalleRecorridoController extends GetxController {
  final SesionesRepository _repository = SesionesRepository();

  final Rx<SesionModel?> sesion = Rx<SesionModel?>(null);
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final id = Get.arguments as int?;
    if (id != null) cargarSesion(id);
  }

  Future<void> cargarSesion(int id) async {
    try {
      isLoading.value = true;
      sesion.value = await _repository.obtenerSesion(id);
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cargar el recorrido');
    } finally {
      isLoading.value = false;
    }
  }
}