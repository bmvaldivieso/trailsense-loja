import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class NuevoRecorridoScreen extends StatelessWidget {
  const NuevoRecorridoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              // Icono superior circular gradient
              Container(
                width: 50.w,
                height: 50.h,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(Icons.route, color: Colors.white, size: 26.sp),
              ),
              SizedBox(height: 16.h),

              // Título "Nuevo Recorrido"
              Text(
                'Nuevo Recorrido',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3142),
                ),
              ),
              SizedBox(height: 20.h),

              // Ilustración central
              SizedBox(
                height: 100.h,
                child: Icon(
                  Icons.map_rounded,
                  size: 90.sp,
                  color: const Color(0xFF5391F5),
                ),
              ),
              SizedBox(height: 12.h),

              // Estrellas de valoración
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => Icon(
                    Icons.star,
                    size: 22.sp,
                    color: index < 4 ? Colors.amber : Colors.grey[300],
                  ),
                ),
              ),
              SizedBox(height: 30.h),

              // Lista de Métricas
              Expanded(
                child: ListView(
                  children: [
                    _buildStatRow('Calorias', '130 cal'),
                    _buildStatRow('KM', '0.3 km'),
                    _buildStatRow('Ritmo Cardiaco', '25 lpm'),
                    _buildStatRow('Velocidad', '10 km/h'),
                    _buildStatRow('Temperatura', '24 Grados'),
                    _buildStatusRow('Estado', 'Bien'),
                  ],
                ),
              ),

              // Controles de grabación (Stop, Pause, Play)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Botón Stop
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 56.w,
                      height: 56.h,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF0033),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.stop_rounded, color: Colors.white, size: 28.sp),
                    ),
                  ),
                  SizedBox(width: 20.w),

                  // Botón Pausa
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 56.w,
                      height: 56.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF3FE),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD0E2FF)),
                      ),
                      child: Icon(Icons.pause, color: const Color(0xFF2D3142), size: 28.sp),
                    ),
                  ),
                  SizedBox(width: 20.w),

                  // Botón Play
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 56.w,
                      height: 56.h,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0066FF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28.sp),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // Botón Terminar Recorrido
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text(
                    'Terminar Recorrido',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              // Bottom Navigation Bar integrador
              _buildBottomNavigationBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3142),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3142),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String statusText) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3142),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFF138A72),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Padding(
      padding: EdgeInsets.only(top: 8.h, bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(icon: Icon(Icons.home_outlined, size: 26.sp, color: const Color(0xFF4C84F6)), onPressed: () {}),
          IconButton(icon: Icon(Icons.map_outlined, size: 26.sp, color: const Color(0xFF4C84F6)), onPressed: () {}),
          IconButton(icon: Icon(Icons.location_on_outlined, size: 26.sp, color: Colors.black87), onPressed: () {}),
          IconButton(icon: Icon(Icons.campaign_outlined, size: 26.sp, color: const Color(0xFF4C84F6)), onPressed: () {}),
          IconButton(icon: Icon(Icons.notifications_none_outlined, size: 26.sp, color: const Color(0xFF4C84F6)), onPressed: () {}),
        ],
      ),
    );
  }
}