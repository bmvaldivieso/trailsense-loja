import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/perfil_controller.dart';

class EditarPerfilScreen extends GetView<PerfilController> {
  const EditarPerfilScreen({super.key});

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
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10.h),

              // Foto de perfil
              Center(
                child: Stack(
                  children: [
                    Obx(() {
                      final foto = controller.nuevaFoto.value;
                      final url = controller.usuario.value?.fotoPerfilUrl;

                      return CircleAvatar(
                        radius: 80.r,
                        backgroundImage: foto != null
                            ? FileImage(foto) as ImageProvider
                            : (url != null && url.isNotEmpty
                                  ? NetworkImage(url)
                                  : const NetworkImage(
                                      'https://picsum.photos/300/300',
                                    )),
                      );
                    }),
                    Positioned(
                      bottom: 0,
                      right: 4.w,
                      child: GestureDetector(
                        onTap: controller.seleccionarFoto,
                        child: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.camera_alt_outlined,
                            color: const Color(0xFF3B82F6),
                            size: 20.r,
                          ),
                        ),
                      ),
                    ),
                  ],
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

              _buildInputField('Nombres:', controller.nombreCtrl),
              _buildInputField('Apellidos:', controller.apellidoCtrl),
              _buildInputField('Cedula:', controller.cedulaCtrl),

              // Correo
              _buildCampoSoloLectura('Correo:', controller.usuario),

              _buildInputField('Numero de telefono:', controller.telefonoCtrl),

              // Fecha de nacimiento
              Text(
                'Fecha de Nacimiento',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: _buildDateInputField('Día', controller.diaCtrl, 2),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildDateInputField('Mes', controller.mesCtrl, 2),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 2,
                    child: _buildDateInputField('Año', controller.anioCtrl, 4),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              const Divider(color: Colors.black38, thickness: 1),
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

              Obx(
                () => Row(
                  children: [
                    GestureDetector(
                      onTap: () => controller.setGenero('M'),
                      child: Container(
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
                    ),
                    SizedBox(width: 16.w),
                    GestureDetector(
                      onTap: () => controller.setGenero('F'),
                      child: Container(
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
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32.h),

              // Botones Guardar y Cancelar
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50.h,
                      child: Obx(
                        () => ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          onPressed: controller.isSaving.value
                              ? null
                              : controller.guardarPerfil,
                          icon: controller.isSaving.value
                              ? SizedBox(
                                  height: 18.h,
                                  width: 18.h,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Guardar',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                          label: Icon(
                            Icons.edit_note_outlined,
                            color: Colors.white,
                            size: 20.r,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: SizedBox(
                      height: 50.h,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[500],
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        onPressed: () => Get.back(),
                        icon: Text(
                          'Cancelar',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        label: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20.r,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController ctrl) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          TextFormField(
            controller: ctrl,
            style: TextStyle(fontSize: 16.sp, color: Colors.black87),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 6),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black38),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF3B82F6)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Para el correo
  Widget _buildCampoSoloLectura(String label, Rx<dynamic> usuario) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4.h),
          Obx(
            () => Text(
              usuario.value?.email ?? '',
              style: TextStyle(fontSize: 16.sp, color: Colors.black54),
            ),
          ),
          SizedBox(height: 12.h),
          const Divider(color: Colors.black38, thickness: 1),
        ],
      ),
    );
  }

  Widget _buildDateInputField(
    String label,
    TextEditingController ctrl,
    int maxLength,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        TextFormField(
          controller: ctrl,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: maxLength,
          style: TextStyle(fontSize: 16.sp, color: Colors.black87),
          decoration: const InputDecoration(
            isDense: true,
            counterText: '',
            contentPadding: EdgeInsets.symmetric(vertical: 6),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black38),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF3B82F6)),
            ),
          ),
        ),
      ],
    );
  }
}
