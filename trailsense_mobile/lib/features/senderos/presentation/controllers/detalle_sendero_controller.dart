import 'package:get/get.dart';
import '../../data/models/sendero_model.dart';
import '../../data/repositories/senderos_repository.dart';

class DetalleSenderoController extends GetxController {
  final SenderosRepository _repository = SenderosRepository();

  final Rx<SenderoModel?> sendero = Rx<SenderoModel?>(null);
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final id = Get.arguments as int?;
    if (id != null) {
      cargarSendero(id);
    }
  }

  Future<void> cargarSendero(int id) async {
    try {
      isLoading.value = true;
      sendero.value = await _repository.obtenerSendero(id);
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cargar el sendero');
    } finally {
      isLoading.value = false;
    }
  }
}