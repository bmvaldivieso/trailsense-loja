import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/perfil_controller.dart';

class PerfilScreen extends GetView<PerfilController> {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 24.r),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final u = controller.usuario.value;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10.h),

                // Foto de perfil
                Center(
                  child: CircleAvatar(
                    radius: 80.r,
                    backgroundImage:
                        (u?.fotoPerfilUrl != null &&
                            u!.fotoPerfilUrl!.isNotEmpty)
                        ? NetworkImage(u.fotoPerfilUrl!)
                        : const NetworkImage('https://picsum.photos/300/300'),
                  ),
                ),

                SizedBox(height: 24.h),

                Text(
                  'Perfil',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                SizedBox(height: 16.h),

                // Género
                Text(
                  'Genero',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8.h),

                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: controller.genero.value == 'M'
                            ? const Color(0xFF3B82F6)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: controller.genero.value == 'M'
                              ? const Color(0xFF3B82F6)
                              : Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.man,
                        color: controller.genero.value == 'M'
                            ? Colors.white
                            : Colors.grey.shade600,
                        size: 28.r,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: controller.genero.value == 'F'
                            ? const Color(0xFF3B82F6)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: controller.genero.value == 'F'
                              ? const Color(0xFF3B82F6)
                              : Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.woman,
                        color: controller.genero.value == 'F'
                            ? Colors.white
                            : Colors.grey.shade600,
                        size: 28.r,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // Fecha de Nacimiento
                Text(
                  'Fecha Nacimiento',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12.h),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDateField('Dia', controller.diaNacimientoDisplay),
                    Container(height: 30.h, width: 1.w, color: Colors.black45),
                    _buildDateField('Mes', controller.mesNacimientoDisplay),
                    Container(height: 30.h, width: 1.w, color: Colors.black45),
                    _buildDateField('Año', controller.anioNacimientoDisplay),
                  ],
                ),

                SizedBox(height: 23.h),

                // Nombre
                _buildCampoSeccion(
                  'Nombres y Apellidos',
                  '${u?.nombre ?? ''} ${u?.apellido ?? ''}'.trim(),
                ),

                // Correo
                _buildCampoSeccion('Correo', u?.email ?? ''),

                // Cédula
                _buildCampoSeccion(
                  'Cedula',
                  (u?.cedula != null && u!.cedula!.isNotEmpty)
                      ? u.cedula!
                      : 'No registrada',
                ),

                // Teléfono
                _buildCampoSeccion(
                  'Numero de telefono',
                  (u?.telefono != null && u!.telefono!.isNotEmpty)
                      ? u.telefono!
                      : 'No registrado',
                ),

                SizedBox(height: 24.h),

                // Botón Editar Perfil
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onPressed: () => Get.toNamed('/editar-perfil'),
                    icon: Text(
                      'Editar Perfil',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    label: Icon(
                      Icons.edit_note_outlined,
                      color: Colors.white,
                      size: 22.r,
                    ),
                  ),
                ),

                SizedBox(height: 24.h),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDateField(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14.sp, color: Colors.black87),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w300,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  // Widget reutilizable para "Título" + valor + separador
  Widget _buildCampoSeccion(String titulo, String valor) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            valor,
            style: TextStyle(fontSize: 16.sp, color: Colors.black87),
          ),
          SizedBox(height: 12.h),
          const Divider(color: Colors.black38, thickness: 1),
        ],
      ),
    );
  }
}
