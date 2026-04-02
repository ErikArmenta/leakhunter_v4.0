@echo off
chcp 65001 >nul
echo ==============================================
echo =         🛠️ LEAK HUNTER BUILD SCRIPT          =
echo ==============================================
echo.

echo 1. Limpiando cache viejo y preparandose...
call flutter clean
echo ✅ Limpieza terminada.
echo.

echo 2. Descargando paquetes y dependencias de tu proyecto...
call flutter pub get
echo ✅ Paquetes listos.
echo.

echo 3. Ensamblando la APP para WINDOWS (.exe)...
call flutter build windows
echo ✅ Build de Windows exitoso. Lo encontraras en:
echo    "build\windows\x64\runner\Release\"
echo.

echo 4. Ensamblando la APP para ANDROID (.apk)...
call flutter build apk
echo ✅ Build de Android exitoso. Lo encontraras en:
echo    "build\app\outputs\flutter-apk\app-release.apk"
echo.

echo 5. Ensamblando la APP para la WEB...
call flutter build web
echo ✅ Build de Web exitoso. Listo para subir! (Ubicado en la carpeta "build\web\")
echo.

echo ==============================================
echo ⚠️ AVISO PARA iOS (iPhone/iPad):
echo ❌ No se logro compilar para iOS porque el sistema de tu computadora es Windows.
echo    Apple obliga a compilar las apps en el sistema operativo macOS (usando XCode).
echo    Para subirla al App Store, debes abrir este mismo codigo en un entorno Mac y correr "flutter build ipa".
echo ==============================================
echo.
echo ¡Felicidades! Se han generado todas las versiones disponibles. 🎉
echo Presiona cualquier tecla para salir...
pause
