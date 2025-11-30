import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; // 引入定位套件

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '花蓮旅遊神器',
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // 預設中心點 (萬一抓不到位置，就停在花蓮火車站)
  LatLng _currentLocation = const LatLng(23.9930, 121.6011);
  bool _hasPermissions = false;
  final MapController _mapController = MapController(); // 用來控制地圖移動

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLocate(); // App 一啟動就開始抓位置
  }

  // 核心功能：檢查權限並抓取位置
  Future<void> _checkPermissionAndLocate() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. 檢查手機的 GPS 開關有沒有開
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('GPS 沒開');
      return;
    }

    // 2. 檢查 App 有沒有被授權
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission(); // 跳出視窗問使用者
      if (permission == LocationPermission.denied) {
        debugPrint('使用者拒絕了權限');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('使用者永久拒絕權限，沒救了');
      return;
    }

    // 3. 終於可以抓位置了！
    setState(() {
      _hasPermissions = true;
    });

    // 抓取當前位置
    Position position = await Geolocator.getCurrentPosition();
    
    // 更新畫面
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });

    // 讓地圖鏡頭飛過去
    _mapController.move(_currentLocation, 15.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的位置在哪裡？')),
      body: FlutterMap(
        mapController: _mapController, // 綁定控制器
        options: MapOptions(
          initialCenter: _currentLocation,
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.hualien_travel',
          ),
          // 只有拿到權限才顯示藍色小圓點
          if (_hasPermissions)
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentLocation,
                  width: 80,
                  height: 80,
                  child: const Icon(
                    Icons.my_location, // 換成定位圖示
                    color: Colors.blue, // 藍色代表自己
                    size: 40,
                  ),
                ),
              ],
            ),
        ],
      ),
      // 加一個按鈕，按了可以重新定位
      floatingActionButton: FloatingActionButton(
        onPressed: _checkPermissionAndLocate,
        child: const Icon(Icons.gps_fixed),
      ),
    );
  }
}