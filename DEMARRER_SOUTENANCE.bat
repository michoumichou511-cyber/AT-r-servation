@echo off
setlocal EnableDelayedExpansion
title AT Reservations - Soutenance
chcp 65001 >NUL

echo ==========================================
echo  DEMARRAGE COMPLET AT RESERVATIONS
echo  Soutenance - Algerie Telecom
echo ==========================================
echo.

REM ------------------------------------------------------------
REM [1/4] MySQL XAMPP
REM ------------------------------------------------------------
echo [1/4] Demarrage MySQL (XAMPP)...
tasklist /FI "IMAGENAME eq mysqld.exe" 2>NUL | find /I "mysqld.exe" >NUL
if errorlevel 1 (
  start "" /B "C:\xampp\mysql\bin\mysqld.exe" --defaults-file="C:\xampp\mysql\bin\my.ini" --standalone
  timeout /t 6 /nobreak >NUL
  echo    MySQL demarre.
) else (
  echo    MySQL deja actif.
)
echo.

REM ------------------------------------------------------------
REM [2/4] Laravel Backend (port 8000)
REM ------------------------------------------------------------
echo [2/4] Demarrage Laravel Backend (port 8000)...
start "Laravel Backend" cmd /k "cd /d C:\Users\loulou\ProjetFinFormation\backend && C:\xampp\php\php.exe artisan serve --host=127.0.0.1 --port=8000"
timeout /t 4 /nobreak >NUL
echo    Laravel : http://127.0.0.1:8000
echo.

REM ------------------------------------------------------------
REM [3/4] Frontend React + Vite (port 5173)
REM ------------------------------------------------------------
echo [3/4] Demarrage Frontend React (port 5173)...
start "Frontend React" cmd /k "cd /d C:\Users\loulou\ProjetFinFormation\frontend && npm run dev"
timeout /t 6 /nobreak >NUL
echo    React  : http://localhost:5173
echo.

REM ------------------------------------------------------------
REM [4/4] Flutter Web (port 3000)
REM ------------------------------------------------------------
echo [4/4] Demarrage Flutter Web (port 3000)...
if exist "C:\Users\loulou\ProjetFinFormation\mobile\at_reservations_mobile\build\web\index.html" (
  start "Flutter Web" cmd /k "cd /d C:\Users\loulou\ProjetFinFormation\mobile\at_reservations_mobile\build\web && python -m http.server 3000"
  timeout /t 3 /nobreak >NUL
  echo    Mobile : http://localhost:3000
) else (
  echo    [SKIP] build/web introuvable. Lancer : flutter build web --release
)
echo.

REM ------------------------------------------------------------
REM Diagnostic readiness
REM ------------------------------------------------------------
echo ==========================================
echo  VERIFICATION DES SERVICES
echo ==========================================
timeout /t 4 /nobreak >NUL

for %%S in (
  "http://127.0.0.1:8000/api/health Laravel"
  "http://localhost:5173            React"
  "http://localhost:3000            Mobile"
) do (
  for /f "tokens=1,2" %%A in (%%S) do (
    curl -s -o NUL -w "%%B: HTTP %%{http_code}\n" -m 3 %%A 2>NUL || echo %%B: KO
  )
)

echo.
echo ==========================================
echo  TOUT EST PRET POUR LA SOUTENANCE
echo ==========================================
echo  Web React  : http://localhost:5173
echo  Backend    : http://127.0.0.1:8000
echo  Mobile Web : http://localhost:3000
echo.
echo  Comptes demo (Password@123) :
echo    Admin      : admin@at.dz
echo    Validateur : validateur@at.dz
echo    Demandeur  : demandeur@at.dz
echo    Agent DML  : agent.dml@at.dz
echo.
echo  Appuyez sur une touche pour fermer cette fenetre.
echo  Les services tournent dans leurs propres fenetres.
pause >NUL
