import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class SesionesScreen extends StatelessWidget {
  const SesionesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
         // Fondo con Imagen de Mapa desde Internet
          Positioned.fill(
            child: Image.network(
              'https://snazzy-maps-cdn.azureedge.net/assets/8097-wy.png?v=20170626083314',
              fit: BoxFit.cover, // Para que cubra toda la pantalla
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFE5E9EC),
                  child: const Center(child: Icon(Icons.map, size: 50, color: Colors.grey)),
                );
              },
            ),
          ),

          // Iconos flotantes sobre la imagen (Botón regresar, Avatar, Pin)
          Positioned(
            top: 60.h,
            left: 20.w,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black, size: 24.sp),
              onPressed: () => Get.back(),
            ),
          ),
          Positioned(
            top: 50.h,
            right: 20.w,
            child: CircleAvatar(
              radius: 20.r,
              backgroundImage: const NetworkImage('https://via.placeholder.com/150'),
            ),
          ),
          // Tarjeta emergente "Recorrido 1"
          Positioned(
            top: 220.h,
            right: 40.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Recorrido 1',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(Icons.chevron_right, size: 18.sp, color: Colors.grey),
                ],
              ),
            ),
          ),

          // Draggable/Panel inferior
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.r),
                  topRight: Radius.circular(30.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 12.h),
                  // Tirador/Handle central
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 5.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text(
                      'RECORRIDOS',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: const Color(0xFF2D3142),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Elemento 1: Nuevo Recorrido
                  _buildRecorridoCard(
                    title: 'Nuevo',
                    rating: 4,
                    distancia: '0 km',
                    caloria: '-',
                    tiempo: '00:00',
                    zona: '-',
                    buttonText: 'Iniciar Nuevo',
                    buttonColor: const Color(0xFF4C84F6),
                    onPressed: () {
                      // Navegación a la segunda pantalla
                      Get.toNamed('/nuevo-recorrido');
                    },
                  ),

                  Divider(height: 1.h, thickness: 1, color: Colors.grey[200]),

                  // Elemento 2: Recorrido A
                  _buildRecorridoCard(
                    title: 'Recorrido A',
                    rating: 4,
                    distancia: null, // No muestra métricas desplegadas
                    caloria: null,
                    tiempo: null,
                    zona: null,
                    buttonText: 'Recorrido Anterior',
                    buttonColor: const Color(0xFF5391F5),
                    onPressed: () {},
                  ),

                  SizedBox(height: 10.h),
                  // Bottom Navigation Bar
                  
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecorridoCard({
    required String title,
    required int rating,
    String? distancia,
    String? caloria,
    String? tiempo,
    String? zona,
    required String buttonText,
    required Color buttonColor,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icono de Recorrido
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.location_on, color: const Color(0xFF38B6FF), size: 30.sp),
              ),
              SizedBox(width: 12.w),
              // Titulo y Calificación
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3142),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          Icons.star,
                          size: 14.sp,
                          color: index < rating ? Colors.amber : Colors.grey[300],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Botón de Acción
              ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: TextStyle(fontSize: 12.sp, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          // Métricas (Distancia, Caloría, Tiempo, Zona) si existen
          if (distancia != null) ...[
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricItem('Distancia', distancia),
                _buildMetricItem('Caloria', caloria!),
                _buildMetricItem('Tiempo', tiempo!),
                _buildMetricItem('Zona', zona!),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.grey[500]),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: const Color(0xFF2D3142)),
        ),
      ],
    );
  }

}