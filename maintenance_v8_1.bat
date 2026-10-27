@echo off
REM ================================================================
REM   OUTIL DE MAINTENANCE SYSTEME - v8.1
REM   Windows 8 / 8.1 / 10 / 11  -  portable et poste fixe
REM   Necessite les droits administrateur
REM
REM   Auteur    : Sarwgi11
REM   Signature : Sarwgi11
REM   Version   : 8.1
REM   Date      : 27/10/2026
REM   Licence   : fourni tel quel, sans garantie
REM
REM   Principes de cette version :
REM     - diagnostics en lecture seule separes des actions qui modifient
REM     - aucune action destructive sans confirmation explicite
REM     - tout est journalise dans un rapport texte horodate
REM     - les modifications systeme sont reversibles
REM ================================================================

setlocal enabledelayedexpansion
title Outil de maintenance systeme v8.0

set "VERSION=8.1"
set "AUTEUR=Sarwgi11"
set "TOTAL=22"
set "SELF=%~f0"
set "SELFDIR=%~dp0"
set "ALL_MODE=0"
set "ALL_STEP=0"
set "NOPROMPT=0"
set "REBOOT_NEEDED=0"
set "BACKTOMENU=0"
set "CONF=0"
set "TMPOUT=%TEMP%\maint_out_%RANDOM%.tmp"

REM ================================================================
REM   ELEVATION ADMINISTRATEUR
REM ================================================================
net session >nul 2>&1
if not errorlevel 1 goto :elevated

echo.
echo  [UAC] Demande des droits administrateur...
powershell -NoProfile -Command "$a='/c '+[char]34+$env:SELF+[char]34; try { Start-Process -FilePath $env:ComSpec -ArgumentList $a -Verb RunAs -ErrorAction Stop } catch { exit 1 }"
if errorlevel 1 (
    echo.
    echo  [ERREUR] Elevation refusee ou impossible.
    echo  Clic droit sur le fichier ^> Executer en tant qu'administrateur.
    echo.
    pause
)
exit /b

:elevated
color 0A
cd /d "%SELFDIR%" 2>nul

REM ----- Horodatage -----
for /f "usebackq tokens=1,2 delims=@" %%A in (`powershell -NoProfile -Command "(Get-Date).ToString('yyyy-MM-dd_HHmm')+'@'+(Get-Date).ToString('dd/MM/yyyy HH:mm')"`) do (
    set "TS=%%A"
    set "DATE_FR=%%B"
)
if not defined TS set "TS=sans_date"

REM ----- Detection de la version de Windows -----
set "WINCAPTION=Inconnu"
set "WINVER=0.0"
set "WINBUILD=0"
for /f "usebackq tokens=1,2,3 delims=@" %%A in (`powershell -NoProfile -Command "$o=Get-CimInstance Win32_OperatingSystem; $o.Caption+'@'+$o.Version+'@'+$o.BuildNumber"`) do (
    set "WINCAPTION=%%A"
    set "WINVER=%%B"
    set "WINBUILD=%%C"
)
for /f "tokens=1,2 delims=." %%A in ("%WINVER%") do (
    set "WINMAJ=%%A"
    set "WINMIN=%%B"
)
set "OSOK=0"
set "ISWIN8=0"
if "%WINMAJ%"=="10" set "OSOK=1"
if "%WINMAJ%"=="6" if "%WINMIN%"=="2" ( set "OSOK=1" & set "ISWIN8=1" )
if "%WINMAJ%"=="6" if "%WINMIN%"=="3" ( set "OSOK=1" & set "ISWIN8=1" )
if "%OSOK%"=="0" (
    cls
    echo.
    echo  [ERREUR] Systeme non pris en charge.
    echo  Detecte : %WINCAPTION%  version %WINVER%
    echo.
    echo  Cet outil demande Windows 8, 8.1, 10 ou 11.
    echo  Sous Windows 7 et anterieur, PowerShell 2.0 ne connait pas les
    echo  commandes CIM et Storage utilisees ici.
    echo.
    pause
    exit /b 1
)

REM ----- Dossier et fichier de rapport -----
set "RPTDIR=%SELFDIR%rapports"
if defined MAINT_HOME set "RPTDIR=%MAINT_HOME%\rapports"
if not exist "%RPTDIR%\" mkdir "%RPTDIR%" >nul 2>&1
if not exist "%RPTDIR%\" set "RPTDIR=%USERPROFILE%\Documents\Maintenance"
if not exist "%RPTDIR%\" mkdir "%RPTDIR%" >nul 2>&1
set "REPORT=%RPTDIR%\rapport_%COMPUTERNAME%_%TS%.txt"
>"%REPORT%" echo ================================================================ 2>nul
if not exist "%REPORT%" (
    set "RPTDIR=%TEMP%"
    set "REPORT=%TEMP%\rapport_%COMPUTERNAME%_%TS%.txt"
    >"!REPORT!" echo ================================================================
)
>>"%REPORT%" echo   RAPPORT DE MAINTENANCE - v%VERSION%
>>"%REPORT%" echo   Outil par   : %AUTEUR%
>>"%REPORT%" echo   Date        : %DATE_FR%
>>"%REPORT%" echo   Windows     : %WINCAPTION% - version %WINVER% build %WINBUILD%
>>"%REPORT%" echo   Machine     : %COMPUTERNAME%
>>"%REPORT%" echo   Utilisateur : %USERNAME%
>>"%REPORT%" echo ================================================================

goto :welcome


REM ================================================================
REM   SOUS-ROUTINES
REM ================================================================

:log
echo %~1
>>"%REPORT%" echo %~1
exit /b

:sect
echo.
echo  [*] %~1
>>"%REPORT%" echo.
>>"%REPORT%" echo --- %~1 ---
exit /b

REM Execute une commande native, affiche et journalise sa sortie
:cap
%* > "%TMPOUT%" 2>&1
type "%TMPOUT%" 2>nul
>>"%REPORT%" type "%TMPOUT%" 2>nul
exit /b

REM Execute du code PowerShell, affiche et journalise sa sortie
:ps
powershell -NoProfile -ExecutionPolicy Bypass -Command %* > "%TMPOUT%" 2>&1
type "%TMPOUT%" 2>nul
>>"%REPORT%" type "%TMPOUT%" 2>nul
exit /b

REM Question oui/non -> resultat dans CONF (1 = oui, 0 = non)
:confirm
set "CONF=0"
if "%NOPROMPT%"=="1" exit /b
echo.
choice /c ON /n /m "  %~1  [O]ui / [N]on : "
if errorlevel 2 (set "CONF=0") else (set "CONF=1")
echo.
exit /b

:ask_continue
set "BACKTOMENU=0"
if "%NOPROMPT%"=="1" exit /b
echo.
choice /c CM /n /m "  [C] Continuer   [M] Retour au menu : "
if errorlevel 2 set "BACKTOMENU=1"
exit /b

:progress
set /a "PCT=(%~1*100)/%TOTAL%"
set /a "FILLED=PCT/5"
set /a "EMPTY=20-FILLED"
set "BAR="
for /l %%i in (1,1,%FILLED%) do set "BAR=!BAR!#"
for /l %%i in (1,1,%EMPTY%)  do set "BAR=!BAR!-"
echo  [!BAR!] %PCT%%% - etape %~1 sur %TOTAL%
exit /b

:banner
cls
echo.
echo  ================================================================
echo    [%~1/%TOTAL%] %~2
echo  ================================================================
>>"%REPORT%" echo.
>>"%REPORT%" echo ================================================================
>>"%REPORT%" echo   ETAPE %~1 - %~2
>>"%REPORT%" echo ================================================================
call :progress %~1
echo.
exit /b

:need_reboot
set "REBOOT_NEEDED=1"
call :log "  [!] Un redemarrage sera propose en fin de maintenance."
exit /b


REM ================================================================
REM   ECRAN D'ACCUEIL
REM ================================================================
:welcome
cls
echo.
echo  ================================================================
echo    OUTIL DE MAINTENANCE SYSTEME v%VERSION%
echo    %DATE_FR%   -   %COMPUTERNAME% / %USERNAME%
echo  ================================================================
echo.
echo   Rapport de cette session :
echo   %REPORT%
echo.
if "%ISWIN8%"=="1" (
    echo   [INFO] Windows 8 ou 8.1 detecte. Non disponibles sur ce systeme :
    echo          WinGet ^(etape 21^), cache de livraison optimisee,
    echo          rapport de veille powercfg, historique Defender detaille.
    echo          Le reste fonctionne normalement.
    echo.
)
echo   Les etapes 1 a 7 sont en lecture seule : elles n'ecrivent rien.
echo   Les etapes 8 et suivantes modifient le systeme et demandent
echo   confirmation avant toute action irreversible.
echo.
call :confirm "Creer un point de restauration avant de commencer ?"
if "%CONF%"=="1" call :make_restore_point
echo.
pause


REM ================================================================
REM   MENU PRINCIPAL
REM ================================================================
:menu
set "ALL_MODE=0"
set "NOPROMPT=0"
cls
echo.
echo  ================================================================
echo    OUTIL DE MAINTENANCE SYSTEME v%VERSION%   [Win8 / 8.1 / 10 / 11]
echo  ================================================================
echo.
echo   DIAGNOSTIC  ^(lecture seule^)
echo    1.  Rapport systeme et materiel
echo    2.  Sante des disques ^(SMART, espace^)
echo    3.  Programmes et services au demarrage
echo    4.  Audit de securite
echo    5.  Diagnostic reseau
echo    6.  Peripheriques USB / Bluetooth
echo    7.  Performances, fiabilite et erreurs recentes
echo.
echo   NETTOYAGE
echo    8.  Fichiers temporaires et caches Windows
echo    9.  Caches navigateurs et applications
echo    10. Nettoyage WinSxS ^(DISM^)
echo    11. Traces recentes du registre
echo.
echo   REPARATION
echo    12. Verification et reparation systeme ^(DISM + SFC^)
echo    13. Verification du disque ^(CHKDSK^)
echo    14. Reparation de Windows Update
echo    15. Reparation reseau ^(Winsock / TCP-IP^)
echo.
echo   OPTIMISATION ET MISES A JOUR
echo    16. Optimisation disque ^(TRIM / defragmentation^)
echo    17. Energie et sante de la batterie
echo    18. Memoire et fichier d'echange
echo    19. Analyse antivirus Defender
echo    20. Analyse anti-malware MSRT
echo    21. Mise a jour des applications ^(WinGet^)
echo    22. Mise a jour des pilotes graphiques
echo.
echo  ----------------------------------------------------------------
echo    D.  DIAGNOSTIC COMPLET automatique ^(1 a 7, sans interaction^)
echo    A.  TOUT EXECUTER ^(1 a 22^)
echo    T.  Desactiver la telemetrie ^(reversible^)
echo    R.  Restaurer les services desactives
echo    P.  Creer un point de restauration
echo    S.  Sauvegarder le profil vers un disque externe
echo    L.  Ouvrir le rapport de la session
echo    0.  QUITTER
echo  ----------------------------------------------------------------
echo.
set "choix="
set /p choix="  Votre choix : "

if not defined choix goto :menu_err
if "%choix%"=="1"  goto :exec_1
if "%choix%"=="2"  goto :exec_2
if "%choix%"=="3"  goto :exec_3
if "%choix%"=="4"  goto :exec_4
if "%choix%"=="5"  goto :exec_5
if "%choix%"=="6"  goto :exec_6
if "%choix%"=="7"  goto :exec_7
if "%choix%"=="8"  goto :exec_8
if "%choix%"=="9"  goto :exec_9
if "%choix%"=="10" goto :exec_10
if "%choix%"=="11" goto :exec_11
if "%choix%"=="12" goto :exec_12
if "%choix%"=="13" goto :exec_13
if "%choix%"=="14" goto :exec_14
if "%choix%"=="15" goto :exec_15
if "%choix%"=="16" goto :exec_16
if "%choix%"=="17" goto :exec_17
if "%choix%"=="18" goto :exec_18
if "%choix%"=="19" goto :exec_19
if "%choix%"=="20" goto :exec_20
if "%choix%"=="21" goto :exec_21
if "%choix%"=="22" goto :exec_22
if /I "%choix%"=="D" goto :diag_all
if /I "%choix%"=="A" goto :exec_all
if /I "%choix%"=="T" goto :tool_telemetry
if /I "%choix%"=="R" goto :tool_restore_services
if /I "%choix%"=="P" goto :tool_restore_point
if /I "%choix%"=="S" goto :tool_backup
if /I "%choix%"=="L" goto :tool_openreport
if "%choix%"=="0" goto :quit

:menu_err
echo  [ERR] Choix invalide.
timeout /t 2 /nobreak >nul
goto :menu


REM ================================================================
REM   ETAPE 1 - RAPPORT SYSTEME ET MATERIEL
REM ================================================================
:exec_1
call :banner 1 "RAPPORT SYSTEME ET MATERIEL"

call :sect "Systeme d'exploitation"
call :ps "$o=Get-CimInstance Win32_OperatingSystem; Write-Host ('  Version   : '+$o.Caption+' '+$o.OSArchitecture); Write-Host ('  Build     : '+$o.Version); Write-Host ('  Installe  : '+$o.InstallDate); Write-Host ('  Demarre   : '+$o.LastBootUpTime)"

call :sect "Processeur"
call :ps "Get-CimInstance Win32_Processor | Select-Object Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed | Format-List"

call :sect "Memoire installee"
call :ps "Get-CimInstance Win32_PhysicalMemory | Select-Object BankLabel,@{N='Go';E={[math]::Round($_.Capacity/1GB,1)}},Speed,Manufacturer,PartNumber | Format-Table -AutoSize"

call :sect "Carte mere et BIOS"
call :ps "Get-CimInstance Win32_BaseBoard | Select-Object Manufacturer,Product,SerialNumber | Format-List; Get-CimInstance Win32_BIOS | Select-Object Manufacturer,SMBIOSBIOSVersion,ReleaseDate | Format-List"

call :sect "Carte graphique"
call :ps "Get-CimInstance Win32_VideoController | Select-Object Name,DriverVersion,DriverDate | Format-Table -AutoSize"

call :sect "Securite materielle"
call :ps "try { Write-Host ('  Secure Boot : '+(Confirm-SecureBootUEFI)) } catch { Write-Host '  Secure Boot : non disponible (BIOS legacy)' }; try { $t=Get-Tpm; Write-Host ('  TPM present : '+$t.TpmPresent+' / actif : '+$t.TpmReady) } catch { Write-Host '  TPM : information indisponible' }"

call :sect "Temperatures ACPI si exposees"
call :ps "$t=Get-CimInstance -Namespace root/wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue; if ($t) { $t | ForEach-Object { Write-Host ('  '+$_.InstanceName+' : '+[math]::Round($_.CurrentTemperature/10-273.15,1)+' C') } } else { Write-Host '  Non expose par ce materiel (utiliser HWiNFO ou equivalent).' }"

call :sect "Duree de fonctionnement"
call :ps "$d=(Get-Date)-(Get-CimInstance Win32_OperatingSystem).LastBootUpTime; Write-Host ('  '+$d.Days+' j '+$d.Hours+' h '+$d.Minutes+' min')"

call :log "  [OK] Etape 1 terminee."
call :ask_continue
if "%BACKTOMENU%"=="1" goto :menu
goto :exec_end


REM ================================================================
REM   ETAPE 2 - SANTE DES DISQUES
REM ================================================================
:exec_2
call :banner 2 "SANTE DES DISQUES (SMART, ESPACE)"

call :sect "Disques physiques"
call :ps "Get-PhysicalDisk | Select-Object FriendlyName,MediaType,BusType,HealthStatus,OperationalStatus,@{N='Go';E={[math]::Round($_.Size/1GB,1)}} | Format-Table -AutoSize"

call :sect "Compteurs de fiabilite SMART"
call :ps "Get-PhysicalDisk | ForEach-Object { $c=$_ | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue; if ($c) { [PSCustomObject]@{Disque=$_.FriendlyName; TempC=$c.Temperature; HeuresAllume=$c.PowerOnHours; UsurePct=$c.Wear; ErrLecture=$c.ReadErrorsTotal; ErrEcriture=$c.WriteErrorsTotal} } } | Format-Table -AutoSize"

call :sect "Espace par volume"
call :ps "Get-Volume | Where-Object DriveLetter | Select-Object DriveLetter,FileSystemLabel,FileSystem,@{N='LibreGo';E={[math]::Round($_.SizeRemaining/1GB,1)}},@{N='TotalGo';E={[math]::Round($_.Size/1GB,1)}},@{N='LibrePct';E={if($_.Size -gt 0){[math]::Round($_.SizeRemaining/$_.Size*100,1)}else{0}}},HealthStatus | Format-Table -AutoSize"

call :sect "Alertes espace disque"
call :ps "Get-Volume | Where-Object { $_.DriveLetter -and $_.Size -gt 0 -and ($_.SizeRemaining/$_.Size) -lt 0.10 } | ForEach-Object { Write-Host ('  [ALERTE] Volume '+$_.DriveLetter+' : moins de 10 pourcent libre') }; Write-Host '  Analyse terminee.'"

call :sect "Chiffrement BitLocker"
call :ps "if (Get-Command Get-BitLockerVolume -ErrorAction SilentlyContinue) { Get-BitLockerVolume -ErrorAction SilentlyContinue | Select-Object MountPoint,VolumeStatus,ProtectionStatus,EncryptionPercentage | Format-Table -AutoSize } else { Write-Host '  BitLocker non disponible sur cette edition de Windows.' }"

call :log "  [OK] Etape 2 terminee."
call :ask_continue
if "%BACKTOMENU%"=="1" goto :menu
goto :exec_end


REM ================================================================
REM   ETAPE 3 - DEMARRAGE
REM ================================================================
:exec_3
call :banner 3 "PROGRAMMES ET SERVICES AU DEMARRAGE"

call :sect "Cles Run du registre"
call :ps "'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run','HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce','HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run','HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run' | ForEach-Object { $k=$_; if (Test-Path $k) { Write-Host ''; Write-Host ('  '+$k); (Get-ItemProperty $k).PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' } | ForEach-Object { Write-Host ('    '+$_.Name+' = '+$_.Value) } } }"

call :sect "Dossiers de demarrage"
call :ps "@($env:APPDATA+'\Microsoft\Windows\Start Menu\Programs\Startup', $env:PROGRAMDATA+'\Microsoft\Windows\Start Menu\Programs\Startup') | ForEach-Object { Write-Host ''; Write-Host ('  '+$_); Get-ChildItem $_ -ErrorAction SilentlyContinue | ForEach-Object { Write-Host ('    '+$_.Name) } }"

call :sect "Taches planifiees declenchees a l'ouverture de session"
call :ps "Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.State -ne 'Disabled' -and $_.TaskPath -notlike '\Microsoft\*' -and ($_.Triggers | Where-Object { $_.CimClass.CimClassName -match 'LogonTrigger|BootTrigger' }) } | Select-Object TaskName,TaskPath,State | Format-Table -AutoSize"

call :sect "Services tiers en demarrage automatique"
call :ps "Get-CimInstance Win32_Service | Where-Object { $_.StartMode -eq 'Auto' -and $_.PathName -notmatch 'system32|SysWOW64' } | Sort-Object DisplayName | Select-Object Name,DisplayName,State | Format-Table -AutoSize"

call :confirm "Ouvrir le Gestionnaire des taches sur l'onglet Demarrage ?"
if "%CONF%"=="1" start "" taskmgr

call :log "  [OK] Etape 3 terminee."
call :ask_continue
if "%BACKTOMENU%"=="1" goto :menu
goto :exec_end


REM ================================================================
REM   ETAPE 4 - AUDIT DE SECURITE
REM ================================================================
:exec_4
call :banner 4 "AUDIT DE SECURITE"

call :sect "Etat de Windows Defender"
call :ps "if (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue) { Get-MpComputerStatus | Select-Object AntivirusEnabled,RealTimeProtectionEnabled,AntispywareEnabled,AntivirusSignatureLastUpdated,AntivirusSignatureVersion,QuickScanAge | Format-List } else { Write-Host '  Module Defender indisponible (antivirus tiers ?).' }"

call :sect "Antivirus enregistres dans le Centre de securite"
call :ps "Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct -ErrorAction SilentlyContinue | Select-Object displayName,pathToSignedProductExe | Format-Table -AutoSize"

call :sect "Pare-feu"
call :ps "Get-NetFirewallProfile | Select-Object Name,Enabled,DefaultInboundAction,DefaultOutboundAction | Format-Table -AutoSize"

call :sect "Controle de compte utilisateur"
call :ps "$p=Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'; Write-Host ('  EnableLUA                  : '+$p.EnableLUA); Write-Host ('  ConsentPromptBehaviorAdmin : '+$p.ConsentPromptBehaviorAdmin)"

call :sect "Comptes locaux"
call :ps "if (Get-Command Get-LocalUser -ErrorAction SilentlyContinue) { Get-LocalUser | Select-Object Name,Enabled,PasswordRequired,PasswordLastSet,LastLogon | Format-Table -AutoSize } else { Get-CimInstance Win32_UserAccount -Filter 'LocalAccount=True' | Select-Object Name,Disabled,Lockout,PasswordRequired,PasswordExpires | Format-Table -AutoSize }"

call :sect "Membres du groupe Administrateurs"
call :ps "if (Get-Command Get-LocalGroupMember -ErrorAction SilentlyContinue) { Get-LocalGroupMember -SID 'S-1-5-32-544' -ErrorAction SilentlyContinue | Select-Object Name,ObjectClass,PrincipalSource | Format-Table -AutoSize } else { $q=[char]39; $g=Get-CimInstance Win32_Group -Filter ('SID='+$q+'S-1-5-32-544'+$q); if ($g) { Get-CimInstance -Query ('ASSOCIATORS OF {Win32_Group.Domain='+$q+$g.Domain+$q+',Name='+$q+$g.Name+$q+'} WHERE ResultClass=Win32_Account') | Select-Object Caption,SIDType | Format-Table -AutoSize } }"

call :sect "Fichier hosts - lignes actives"
call :ps "$h=Get-Content ($env:SystemRoot+'\System32\drivers\etc\hosts') -ErrorAction SilentlyContinue | Where-Object { $_ -notmatch '^\s*#' -and $_ -match '\S' }; if ($h) { $h | ForEach-Object { Write-Host ('  '+$_) } } else { Write-Host '  Aucune entree personnalisee.' }"

call :sect "Ports en ecoute et processus associes"
call :ps "Get-NetTCPConnection -State Listen | ForEach-Object { $p=Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue; [PSCustomObject]@{Port=$_.LocalPort;Adresse=$_.LocalAddress;PID=$_.OwningProcess;Processus=$p.ProcessName} } | Sort-Object Port -Unique | Format-Table -AutoSize"

call :log "  [OK] Etape 4 terminee."
call :ask_continue
if "%BACKTOMENU%"=="1" goto :menu
goto :exec_end


REM ================================================================
REM   ETAPE 5 - DIAGNOSTIC RESEAU
REM ================================================================
:exec_5
call :banner 5 "DIAGNOSTIC RESEAU"

call :sect "Cartes reseau"
call :ps "Get-NetAdapter | Select-Object Name,InterfaceDescription,Status,LinkSpeed,MacAddress | Format-Table -AutoSize"

call :sect "Adressage IP"
call :ps "Get-NetIPConfiguration | ForEach-Object { Write-Host ''; Write-Host ('  Interface : '+$_.InterfaceAlias); Write-Host ('  IPv4      : '+$_.IPv4Address.IPAddress); Write-Host ('  Passerelle: '+$_.IPv4DefaultGateway.NextHop); Write-Host ('  DNS       : '+($_.DNSServer.ServerAddresses -join ', ')) }"

call :sect "Qualite du lien Wi-Fi"
call :cap netsh wlan show interfaces

call :sect "Tests de connectivite"
ping -n 3 1.1.1.1 >nul 2>&1
if errorlevel 1 (call :log "  [KO] 1.1.1.1 injoignable") else (call :log "  [OK] 1.1.1.1 joignable")
ping -n 3 8.8.8.8 >nul 2>&1
if errorlevel 1 (call :log "  [KO] 8.8.8.8 injoignable") else (call :log "  [OK] 8.8.8.8 joignable")
ping -n 3 www.google.com >nul 2>&1
if errorlevel 1 (call :log "  [KO] Resolution DNS en echec") else (call :log "  [OK] Resolution DNS fonctionnelle")

call :sect "Latence et pertes vers 1.1.1.1"
call :ps "$r=Test-Connection -ComputerName 1.1.1.1 -Count 8 -ErrorAction SilentlyContinue; if ($r) { $ms=$r | ForEach-Object { $_.ResponseTime }; Write-Host ('  Reponses : '+$ms.Count+' sur 8'); Write-Host ('  Min '+($ms | Measure-Object -Minimum).Minimum+' ms  /  Moy '+[math]::Round(($ms | Measure-Object -Average).Average,1)+' ms  /  Max '+($ms | Measure-Object -Maximum).Maximum+' ms') } else { Write-Host '  Aucune reponse.' }"

call :sect "Connexions etablies"
call :ps "Get-NetTCPConnection -State Established | Select-Object LocalPort,RemoteAddress,RemotePort,@{N='Processus';E={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName}} | Sort-Object RemoteAddress | Format-Table -AutoSize"

call :sect "Table de routage"
call :cap route print -4

call :log "  [OK] Etape 5 terminee."
call :ask_continue
if "%BACKTOMENU%"=="1" goto :menu
goto :exec_end


REM ================================================================
REM   ETAPE 6 - PERIPHERIQUES USB / BLUETOOTH
REM ================================================================
:exec_6
call :banner 6 "PERIPHERIQUES USB / BLUETOOTH"

call :sect "Peripheriques USB presents"
call :ps "if (Get-Command Get-PnpDevice -ErrorAction SilentlyContinue) { Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -like 'USB*' } | Select-Object FriendlyName,Status,Class | Sort-Object Class,FriendlyName | Format-Table -AutoSize } else { Get-CimInstance Win32_PnPEntity | Where-Object { $_.PNPDeviceID -like 'USB*' } | Select-Object Name,Status,PNPClass | Sort-Object Name | Format-Table -AutoSize }"

call :sect "Volumes amovibles"
call :ps "Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=2' | Select-Object DeviceID,VolumeName,FileSystem,@{N='Go';E={[math]::Round($_.Size/1GB,1)}},@{N='LibreGo';E={[math]::Round($_.FreeSpace/1GB,1)}} | Format-Table -AutoSize"

call :sect "Peripheriques en erreur"
call :ps "$e=$null; if (Get-Command Get-PnpDevice -ErrorAction SilentlyContinue) { $e=Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Error' -or $_.Status -eq 'Degraded' } | Select-Object FriendlyName,Status,Class } else { $e=Get-CimInstance Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 } | Select-Object Name,ConfigManagerErrorCode }; if ($e) { $e | Format-Table -AutoSize } else { Write-Host '  Aucun peripherique en erreur.' }"

call :sect "Historique des supports USB connectes"
call :ps "Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR' -ErrorAction SilentlyContinue | Select-Object -First 25 -ExpandProperty PSChildName | ForEach-Object { Write-Host ('  '+$_) }"

call :sect "Peripheriques Bluetooth"
call :ps "$b=$null; if (Get-Command Get-PnpDevice -ErrorAction SilentlyContinue) { $b=Get-PnpDevice -Class Bluetooth -ErrorAction SilentlyContinue | Select-Object FriendlyName,Status } else { $b=Get-CimInstance Win32_PnPEntity | Where-Object { $_.PNPClass -eq 'Bluetooth' } | Select-Object Name,Status }; if ($b) { $b | Format-Table -AutoSize } else { Write-Host '  Aucun materiel Bluetooth detecte.' }"

call :log "  [OK] Etape 6 terminee."
call :ask_continue
if "%BACKTOMENU%"=="1" goto :menu
goto :exec_end


REM ================================================================
REM   ETAPE 7 - PERFORMANCES ET FIABILITE
REM ================================================================
:exec_7
call :banner 7 "PERFORMANCES, FIABILITE ET ERREURS RECENTES"

call :sect "Durees des derniers demarrages"
call :ps "$e=Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Diagnostics-Performance/Operational';Id=100} -MaxEvents 5 -ErrorAction SilentlyContinue; if ($e) { $e | ForEach-Object { $x=[xml]$_.ToXml(); $ms=($x.Event.EventData.Data | Where-Object { $_.Name -eq 'BootTime' }).'#text'; Write-Host ('  '+$_.TimeCreated+' : '+[math]::Round([double]$ms/1000,1)+' s') } } else { Write-Host '  Journal de performance indisponible.' }"

call :sect "Erreurs critiques du systeme sur 14 jours"
call :ps "$d=(Get-Date).AddDays(-14); $e=Get-WinEvent -FilterHashtable @{LogName='System';Level=1,2;StartTime=$d} -ErrorAction SilentlyContinue; if ($e) { $e | Group-Object ProviderName | Sort-Object Count -Descending | Select-Object -First 10 Count,Name | Format-Table -AutoSize; Write-Host ''; $e | Select-Object -First 10 TimeCreated,Id,ProviderName | Format-Table -AutoSize } else { Write-Host '  Aucune erreur critique sur la periode.' }"

call :sect "Applications qui plantent le plus"
call :ps "$d=(Get-Date).AddDays(-30); $e=Get-WinEvent -FilterHashtable @{LogName='Application';Id=1000;StartTime=$d} -ErrorAction SilentlyContinue; if ($e) { $e | ForEach-Object { ($_.Properties[0].Value) } | Group-Object | Sort-Object Count -Descending | Select-Object -First 10 Count,Name | Format-Table -AutoSize } else { Write-Host '  Aucun plantage applicatif enregistre.' }"

call :sect "Ecrans bleus - fichiers minidump"
call :ps "$m=Get-ChildItem ($env:SystemRoot+'\Minidump\*.dmp') -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 10; if ($m) { $m | Select-Object LastWriteTime,Name,@{N='Ko';E={[math]::Round($_.Length/1KB)}} | Format-Table -AutoSize; Write-Host '  Analyser ces fichiers avec WinDbg ou BlueScreenView.' } else { Write-Host '  Aucun minidump : pas d ecran bleu enregistre.' }"

call :sect "Processus les plus gourmands en memoire"
call :ps "Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 12 ProcessName,@{N='RAM_Mo';E={[math]::Round($_.WorkingSet64/1MB,1)}},Id | Format-Table -AutoSize"

call :confirm "Generer le rapport energie powercfg ? Cela prend 60 secondes."
if "%CONF%"=="1" (
    echo  [*] Analyse en cours, ne rien lancer pendant 60 secondes...
    powercfg /energy /output "%RPTDIR%\energie_%TS%.html" /duration 60 >nul 2>&1
    if exist "%RPTDIR%\energie_%TS%.html" call :log "  [OK] Rapport energie : %RPTDIR%\energie_%TS%.html"
)

call :log "  [OK] Etape 7 terminee."
call :ask_continue
if "%BACKTOMENU%"=="1" goto :menu
goto :exec_end


REM ================================================================
REM   ETAPE 8 - FICHIERS TEMPORAIRES ET CACHES WINDOWS
REM   Note : les journaux d'evenements ne sont PAS effaces, ils sont
REM   la source des diagnostics des etapes 4 et 7.
REM ================================================================
:exec_8
call :banner 8 "FICHIERS TEMPORAIRES ET CACHES WINDOWS"

for /f "usebackq" %%A in (`powershell -NoProfile -Command "(Get-PSDrive C).Free"`) do set "FREE_BEFORE=%%A"
call :ps "Write-Host ('  Espace libre avant : '+[math]::Round((Get-PSDrive C).Free/1GB,2)+' Go')"

call :log "  [1/7] Dossiers temporaires utilisateur et Windows..."
del /Q /F /S "%TEMP%\*" >nul 2>&1
for /d %%D in ("%TEMP%\*") do rd /S /Q "%%D" >nul 2>&1
del /Q /F /S "%SystemRoot%\Temp\*" >nul 2>&1
for /d %%D in ("%SystemRoot%\Temp\*") do rd /S /Q "%%D" >nul 2>&1

call :log "  [2/7] Rapports d'erreurs Windows..."
del /Q /F /S "%LOCALAPPDATA%\Microsoft\Windows\WER\*" >nul 2>&1
del /Q /F /S "%PROGRAMDATA%\Microsoft\Windows\WER\*" >nul 2>&1

call :log "  [3/7] Caches de miniatures et d'icones..."
del /Q /F "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*.db" >nul 2>&1
del /Q /F "%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache_*.db" >nul 2>&1

call :log "  [4/7] Cache de livraison optimisee..."
sc query DoSvc >nul 2>&1
if not errorlevel 1 (
    net stop DoSvc >nul 2>&1
    del /Q /F /S "%SystemRoot%\SoftwareDistribution\DeliveryOptimization\*" >nul 2>&1
    net start DoSvc >nul 2>&1
) else (
    call :log "      Service absent sur ce systeme, rien a nettoyer."
)

call :log "  [5/7] Cache de telechargement Windows Update..."
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
del /Q /F /S "%SystemRoot%\SoftwareDistribution\Download\*" >nul 2>&1
net start bits >nul 2>&1
net start wuauserv >nul 2>&1

call :log "  [6/7] Anciens journaux d'installation..."
del /Q /F "%SystemRoot%\Logs\CBS\CbsPersist_*.log" >nul 2>&1
del /Q /F "%SystemRoot%\Logs\DISM\dism.log.*" >nul 2>&1

call :confirm "Vider la corbeille ?"
if "%CONF%"=="1" (
    call :log "  [7/7] Corbeille..."
    powershell -NoProfile -Command "if (Get-Command Clear-RecycleBin -ErrorAction SilentlyContinue) { Clear-RecycleBin -Force -ErrorAction SilentlyContinue; exit 0 } else { exit 1 }" >nul 2>&1
    if errorlevel 1 (
        for %%V in (C D E F) do if exist "%%V:\$Recycle.Bin" rd /S /Q "%%V:\$Recycle.Bin" >nul 2>&1
    )
) else (
    call :log "  [7/7] Corbeille conservee."
)

call :ps "if (Test-Path ($env:SystemDrive+'\Windows.old')) { Write-Host '  [INFO] Un dossier Windows.old existe : plusieurs Go recuperables via le Nettoyage de disque, bouton Nettoyer les fichiers systeme.' } else { Write-Host '  [INFO] Pas de dossier Windows.old.' }"

for /f "usebackq" %%A in (`powershell -NoProfile -Command "(Get-PSDrive C).Free"`) do set "FREE_AFTER=%%A"
call :ps "$g=[int64]$env:FREE_AFTER-[int64]$env:FREE_BEFORE; if ($g -gt 0) { Write-Host ('  Espace recupere : '+[math]::Round($g/1MB,1)+' Mo') } else { Write-Host '  Gain negligeable.' }"

call :log "  [OK] Etape 8 terminee."
call :ask_continue
if "%BACKTOMENU%"=="1" goto :menu
goto :exec_end


REM ================================================================
REM   ETAPE 9 - CACHES NAVIGATEURS ET APPLICATIONS
REM   Caches uniquement : ni cookies, ni mots de passe, ni historique.
REM ================================================================
:exec_9
call :banner 9 "CACHES NAVIGATEURS ET APPLICATIONS"

call :sect "Navigateurs en cours d'execution"
call :ps "$p=Get-Process chrome,msedge,firefox,brave,opera -ErrorAction SilentlyContinue; if ($p) { $p | Select-Object -ExpandProperty ProcessName -Unique | ForEach-Object { Write-Host ('  [ATTENTION] '+$_+' est ouvert : son cache sera partiellement verrouille.') } } else { Write-Host '  Aucun navigateur ouvert.' }"

call :confirm "Continuer le nettoyage des caches ?"
if "%CONF%"=="0" if "%NOPROMPT%"=="0" goto :exec_9_end

call :sect "Navigateurs Chromium - tous les profils"
call :ps "$roots=@($env:LOCALAPPDATA+'\Google\Chrome\User Data', $env:LOCALAPPDATA+'\Microsoft\Edge\User Data', $env:LOCALAPPDATA+'\BraveSoftware\Brave-Browser\User Data', $env:APPDATA+'\Opera Software\Opera Stable', $env:LOCALAPPDATA+'\Vivaldi\User Data'); foreach ($r in $roots) { if (Test-Path $r) { $n=0; Get-ChildItem $r -Directory -ErrorAction SilentlyContinue | ForEach-Object { foreach ($c in 'Cache','Code Cache','GPUCache','Service Worker\CacheStorage') { $p=Join-Path $_.FullName $c; if (Test-Path $p) { Get-ChildItem $p -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue; $n++ } } }; Write-Host ('  [OK] '+(Split-Path $r -Leaf)+' : '+$n+' dossiers de cache traites') } }"

call :sect "Firefox - tous les profils"
call :ps "$r=$env:LOCALAPPDATA+'\Mozilla\Firefox\Profiles'; if (Test-Path $r) { Get-ChildItem $r -Directory | ForEach-Object { foreach ($c in 'cache2','startupCache') { $p=Join-Path $_.FullName $c; if (Test-Path $p) { Get-ChildItem $p -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue } } }; Write-Host '  [OK] Firefox' } else { Write-Host '  [--] Firefox absent' }"

call :sect "Applications de bureau"
call :ps "$t=@{'Discord'=$env:APPDATA+'\discord\Cache'; 'Spotify'=$env:LOCALAPPDATA+'\Spotify\Storage'; 'Teams classique'=$env:APPDATA+'\Microsoft\Teams\Cache'; 'Teams (nouveau)'=$env:LOCALAPPDATA+'\Packages\MSTeams_8wekyb3d8bbwe\LocalCache\Microsoft\MSTeams\Cache'; 'Steam htmlcache'=$env:LOCALAPPDATA+'\Steam\htmlcache'}; foreach ($k in $t.Keys) { if (Test-Path $t[$k]) { Get-ChildItem $t[$k] -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue; Write-Host ('  [OK] '+$k) } else { Write-Host ('  [--] '+$k+' absent') } }"

:exec_9_end
call :log "  [OK] Etape 9 terminee."
call :ask_continue
if "%BACKTOMENU%"=="1" goto :menu
goto :exec_end


REM ================================================================
REM   ETAPE 10 - NETTOYAGE WINSXS
REM ================================================================
:exec_10
call :banner 10 "NETTOYAGE WINSXS (DISM)"

call :sect "Analyse du magasin de composants"
DISM.exe /Online /Cleanup-Image /AnalyzeComponentStore

call :sect "Nettoyage standard reversible"
DISM.exe /Online /Cleanup-Image /StartComponentCleanup

echo.
echo  [ATTENTION] ResetBase est IRREVERSIBLE : la desinstallation des
echo  mises a jour Windows deja installees ne sera plus possible.
call :confirm "Appliquer ResetBase ?"
if "%CONF%"=="1" (
    DISM.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
    call :log "  [OK] ResetBase applique."
) else (
    call :log "  [IGNORE] ResetBase non applique."
)

call :log "  [OK] Etape 10 terminee."
call :ask_continue
if "%BACKTOMENU%"=="1" goto :menu
goto :exec_end


REM ================================================================
REM   ETAPE 11 - TRACES RECENTES DU REGISTRE
REM ================================================================
:exec_11
call :banner 11 "TRACES RECENTES DU REGISTRE"

call :sect "Sauvegarde de la ruche HKCU"
reg save HKCU "%RPTDIR%\hkcu_%TS%.hiv" /y >nul 2>&1
if exist "%RPTDIR%\hkcu_%TS%.hiv" (
    call :log "  [OK] Sauvegarde : %RPTDIR%\hkcu_%TS%.hiv"
    call :log "      Restauration : reg restore HKCU chemin_du_fichier"
) else (
    call :log "  [ERREUR] Sauvegarde impossible, nettoyage annule."
    goto :exec_11_end
)

call :sect "Entrees de desinstallation orphelines (signalees, non supprimees)"
call :ps "Get-ChildItem 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall' -ErrorAction SilentlyContinue | ForEach-Object { $v=Get-ItemProperty $_.PsPath -ErrorAction SilentlyContinue; $loc=$v.InstallLocation; if ($loc) { $loc=$loc.Trim([char]34) }; if ($loc -and -not (Test-Path $loc)) { Write-Host ('  [ORPHELIN] '+$v.DisplayName) } }"

call :confirm "Effacer les listes de documents et de recherches recents ?"
if "%CONF%"=="0" goto :exec_11_end

for %%K in (
    "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs"
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU"
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths"
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery"
) do (
    reg delete %%K /va /f >nul 2>&1
    call :log "  [OK] %%~K"
)

:exec_11_end
call :log "  [OK] Etape 11 terminee."
call :ask_continue
if "%BACKTOMENU%"=="1" goto :menu
goto :exec_end


REM ================================================================
REM   ETAPE 12 - REPARATION SYSTEME (DISM PUIS SFC)
REM ================================================================
:exec_12
call :banner 12 "VERIFICATION ET REPARATION SYSTEME"

call :log "  L'ordre correct est DISM puis SFC : DISM repare la source"
call :log "  dont SFC se sert pour remplacer les fichiers endommages."
echo.

call :sect "1/3 - DISM ScanHealth"
DISM.exe /Online /Cleanup-Image /ScanHealth

call :sect "2/3 - DISM RestoreHealth"
DISM.exe /Online /Cleanup-Image /RestoreHealth

call :sect "3/3 - SFC scannow"
sfc /scannow

call :sect "Extrait du journal CBS"
call :ps "$log=$env:SystemRoot+'\Logs\CBS\CBS.log'; if (Test-Path $log) { Get-Content $log -Tail 400 | Select-String 'Cannot repair|Repaired file|corrupt' | Select-Object -Last 12 | ForEach-Object { Write-Host ('  '+$_.Line) } } else { Write-Host '  Journal CBS introuvable.' }"

call :need_reboot
call :log "  [OK] Etape 12 terminee."
call :ask_continue
if "%BACKTOMENU%"=="1" goto :menu
goto :exec_end


REM ================================================================
REM   ETAPE 13 - VERIFICATION DU DISQUE
REM   SSD : analyse en ligne, sans redemarrage ni usure inutile.
REM   HDD : reparation complete planifiee au prochain demarrage.
REM ================================================================
:exec_13
call :banner 13 "VERIFICATION DU DISQUE (CHKDSK)"

set "SYSMEDIA=Inconnu"
for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "$m=''; $p=Get-Partition -DriveLetter C -ErrorAction SilentlyContinue; if ($p) { $m=(Get-PhysicalDisk | Where-Object { $_.DeviceId -eq $p.DiskNumber }).MediaType }; if (-not $m -or $m -eq 'Unspecified') { $m='Inconnu' }; $m"`) do set "SYSMEDIA=%%A"
call :log "  Type du disque systeme : %SYSMEDIA%"
echo.

call :sect "Analyse en ligne du volume C (sans redemarrage)"
chkdsk C: /scan /perf

if /I "%SYSMEDIA%"=="SSD" (
    call :log "  [INFO] Disque SSD : CHKDSK /F /R n'est pas recommande."
    call :log "  L'analyse en ligne ci-dessus suffit. Une reparation hors"
    call :log "  ligne n'a de sens qu'en cas d'erreurs signalees."
    call :confirm "Planifier malgre tout une reparation au prochain demarrage ?"
) else (
    call :confirm "Planifier une reparation complete au prochain demarrage ?"
)

if "%CONF%"=="1" (
    REM Y pour Windows anglais, O pour Windows francais : la reponse
    REM invalide est simplement redemandee par chkdsk.
    (echo Y&echo O)| chkdsk C: /F /R
    call :log "  [OK] Reparation planifiee au prochain demarrage."
    call :need_reboot
) else (
    call :log "  [IGNORE] Aucune reparation hors ligne planifiee."
)

call :log "  [OK] Etape 13 terminee."
call :ask_continue
if "%BACKTOMENU%"=="1" goto :menu
goto :exec_end


REM ================================================================
REM   ETAPE 14 - REPARATION DE WINDOWS UPDATE
REM   Les dossiers sont renommes et non supprimes : retour arriere
REM   possible tant que le nouveau cache n'est pas valide.
REM ================================================================
:exec_14
call :banner 14 "REPARATION DE WINDOWS UPDATE"

call :sect "Arret des services"
for %%S in (wuauserv bits cryptsvc msiserver appidsvc) do (
    net stop %%S >nul 2>&1
    call :log "  [STOP] %%S"
)

call :sect "Renommage des caches"
if exist "%SystemRoot%\SoftwareDistribution" (
    ren "%SystemRoot%\SoftwareDistribution" "SoftwareDistribution.old_%TS%" >nul 2>&1
    if errorlevel 1 (call :log "  [ERREUR] SoftwareDistribution verrouille") else (call :log "  [OK] SoftwareDistribution renomme")
)
if exist "%SystemRoot%\System32\catroot2" (
    ren "%SystemRoot%\System32\catroot2" "catroot2.old_%TS%" >nul 2>&1
    if errorlevel 1 (call :log "  [ERREUR] catroot2 verrouille") else (call :log "  [OK] catroot2 renomme")
)

call :sect "Reenregistrement des bibliotheques"
for %%D in (atl.dll urlmon.dll mshtml.dll jscript.dll vbscript.dll msxml3.dll msxml6.dll actxprxy.dll softpub.dll wintrust.dll dssenh.dll rsaenh.dll cryptdlg.dll oleaut32.dll ole32.dll shell32.dll wuapi.dll wuaueng.dll wups.dll wups2.dll wuwebv.dll qmgr.dll qmgrprxy.dll) do (
    regsvr32 /s "%SystemRoot%\System32\%%D" >nul 2>&1
)
call :log "  [OK] Bibliotheques reenregistrees."

call :sect "Reinitialisation BITS et redemarrage des services"
sc.exe sdset bits "D:(A;CI;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)" >nul 2>&1
for %%S in (cryptsvc appidsvc msiserver bits wuauserv) do (
    net start %%S >nul 2>&1
    call :log "  [START] %%S"
)

call :sect "Recherche de mises a jour"
if exist "%SystemRoot%\System32\UsoClient.exe" (
    "%SystemRoot%\System32\UsoClient.exe" StartScan >nul 2>&1
    call :log "  [OK] Recherche lancee."
) else (
    powershell -NoProfile -Command "(New-Object -ComObject Microsoft.Update.AutoUpdate).DetectNow()" >nul 2>&1
    call :log "  [OK] Recherche lancee."
)

call :log "  [INFO] Les anciens caches sont conserves sous le suffixe .old_%TS%"
call :log "         Ils peuvent etre supprimes une fois les mises a jour validees."
call :need_reboot
call :log "  [OK] Etape 14 terminee."
call :ask_continue
if "%BACKTOMENU%"=="1" goto :menu
goto :exec_end


REM ================================================================
REM   ETAPE 15 - REPARATION RESEAU
REM ================================================================
:exec_15
call :banner 15 "REPARATION RESEAU (WINSOCK / TCP-IP)"

echo  [ATTENTION] Cette etape reinitialise la pile reseau.
echo  Elle peut supprimer les configurations suivantes :
echo    - adresses IP fixes et serveurs DNS manuels
echo    - certains adaptateurs VPN virtuels
echo    - parametres de proxy d'entreprise
echo  A n'executer qu'en cas de probleme reseau reel.
call :confirm "Executer la reparation reseau ?"
if "%CONF%"=="0" goto :exec_15_end

call :sect "Sauvegarde de la configuration actuelle"
netsh -c interface dump > "%RPTDIR%\reseau_avant_%TS%.txt" 2>nul
call :log "  [OK] Sauvegarde : %RPTDIR%\reseau_avant_%TS%.txt"
call :log "      Restauration : netsh -f chemin_du_fichier"

call :sect "Vidage du cache DNS"
call :cap ipconfig /flushdns

call :sect "Reinitialisation Winsock"
call :cap netsh winsock reset

call :sect "Reinitialisation de la pile TCP-IP"
netsh int ip reset "%RPTDIR%\tcpreset_%TS%.log" >nul 2>&1
call :log "  [OK] Journal : %RPTDIR%\tcpreset_%TS%.log"

call :sect "Reinitialisation du proxy"
netsh winhttp reset proxy >nul 2>&1
call :log "  [OK] Proxy WinHTTP reinitialise."

call :sect "Retour aux valeurs par defaut de TCP"
netsh int tcp set global autotuninglevel=normal >nul 2>&1
netsh int tcp set heuristics default >nul 2>&1
call :log "  [OK] Autotuning remis sur normal."

call :sect "Vidage ARP et NetBIOS"
arp -d * >nul 2>&1
nbtstat -R >nul 2>&1
call :log "  [OK]"

call :need_reboot

:exec_15_end
call :log "  [OK] Etape 15 terminee."
call :ask_continue
if "%BACKTOMENU%"=="1" goto :menu
goto :exec_end


REM ================================================================
REM   ETAPE 16 - OPTIMISATION DISQUE
REM ================================================================
:exec_16
call :banner 16 "OPTIMISATION DISQUE (TRIM / DEFRAGMENTATION)"

call :sect "Type de chaque disque"
call :ps "Get-PhysicalDisk | Select-Object DeviceId,FriendlyName,MediaType,@{N='Go';E={[math]::Round($_.Size/1GB,1)}} | Format-Table -AutoSize"

call :sect "Optimisation de chaque volume fixe"
call :ps "Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' } | ForEach-Object { $l=$_.DriveLetter; $p=Get-Partition -DriveLetter $l -ErrorAction SilentlyContinue; $m='Inconnu'; if ($p) { $t=(Get-PhysicalDisk | Where-Object { $_.DeviceId -eq $p.DiskNumber }).MediaType; if ($t -and $t -ne 'Unspecified') { $m=$t } }; if ($_.Size -gt 0 -and ($_.SizeRemaining/$_.Size) -lt 0.15 -and $m -ne 'SSD') { Write-Host ('  [ATTENTION] Volume '+$l+' : moins de 15 pourcent libre') }; Write-Host ('  Volume '+$l+' de type '+$m+' en cours...'); if ($m -eq 'SSD') { Optimize-Volume -DriveLetter $l -ReTrim -ErrorAction SilentlyContinue } elseif ($m -eq 'HDD') { Optimize-Volume -DriveLetter $l -Defrag -ErrorAction SilentlyContinue } else { & defrag ($l+':') /O | Out-Null }; Write-Host ('  [OK] Volume '+$l) }"

call :sect "Planification automatique de l'optimisation"
call :cap schtasks /query /tn "\Microsoft\Windows\Defrag\ScheduledDefrag" /fo list

call :log "  [OK] Etape 16 terminee."
call :ask_continue
if "%BACKTOMENU%"=="1" goto :menu
goto :exec_end


REM ================================================================
REM   ETAPE 17 - ENERGIE ET BATTERIE
REM ================================================================
:exec_17
call :banner 17 "ENERGIE ET SANTE DE LA BATTERIE"

call :sect "Batterie"
call :ps "$b=Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue; if ($b) { foreach ($x in $b) { Write-Host ('  Modele    : '+$x.Name); Write-Host ('  Charge    : '+$x.EstimatedChargeRemaining+' pourcent'); Write-Host ('  Autonomie : '+$x.EstimatedRunTime+' min') } } else { Write-Host '  Aucune batterie : poste fixe.' }"

call :sect "Etats de veille disponibles"
call :cap powercfg /a

call :sect "Plan d'alimentation actif"
call :cap powercfg /getactivescheme

if "%NOPROMPT%"=="1" goto :exec_17_report
echo.
echo   [1] Utilisation normale  ^(equilibre^)
echo   [2] Performances elevees ^(sur secteur, consomme plus^)
echo   [3] Economie d'energie
echo   [4] Ne rien changer
choice /c 1234 /n /m "  Votre choix : "
if errorlevel 4 goto :exec_17_report
if errorlevel 3 (
    powercfg /setactive a1841308-3541-4fab-bc81-f71556f20b4a >nul 2>&1
    call :log "  [OK] Plan Economie d'energie active."
    goto :exec_17_report
)
if errorlevel 2 (
    powercfg /list | findstr /I "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" >nul 2>&1
    if errorlevel 1 (
        call :log "  [INFO] Plan Performances elevees absent sur ce materiel."
        call :log "         Windows utilise le curseur de performance moderne."
    ) else (
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c >nul 2>&1
        call :log "  [OK] Plan Performances elevees active."
    )
    goto :exec_17_report
)
powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e >nul 2>&1
call :log "  [OK] Plan Equilibre active."

:exec_17_report
call :sect "Rapport de sante de la batterie"
powercfg /batteryreport /output "%RPTDIR%\batterie_%TS%.html" >nul 2>&1
if exist "%RPTDIR%\batterie_%TS%.html" (
    call :log "  [OK] %RPTDIR%\batterie_%TS%.html"
    call :log "      Comparer capacite de conception et capacite actuelle."
) else (
    call :log "  [--] Pas de batterie a analyser."
)
powercfg /sleepstudy /output "%RPTDIR%\veille_%TS%.html" >nul 2>&1
if exist "%RPTDIR%\veille_%TS%.html" call :log "  [OK] %RPTDIR%\veille_%TS%.html"

call :log "  [INFO] L'hibernation n'est pas desactivee : elle est necessaire"
call :log "         au demarrage rapide et a la veille prolongee des portables."

call :log "  [OK] Etape 17 terminee."
call :ask_continue
if "%BACKTOMENU%"=="1" goto :menu
goto :exec_end


REM ================================================================
REM   ETAPE 18 - MEMOIRE ET FICHIER D'ECHANGE
REM ================================================================
:exec_18
call :banner 18 "MEMOIRE ET FICHIER D'ECHANGE"

call :sect "Etat de la memoire"
call :ps "$o=Get-CimInstance Win32_OperatingSystem; $t=$o.TotalVisibleMemorySize/1MB; $l=$o.FreePhysicalMemory/1MB; Write-Host ('  Total  : '+[math]::Round($t,2)+' Go'); Write-Host ('  Libre  : '+[math]::Round($l,2)+' Go'); Write-Host ('  Charge : '+[math]::Round(($t-$l)/$t*100,1)+' pourcent')"

call :sect "Fichier d'echange"
call :ps "$s=Get-CimInstance Win32_ComputerSystem; Write-Host ('  Gestion automatique : '+$s.AutomaticManagedPagefile); Get-CimInstance Win32_PageFileUsage | Select-Object Name,AllocatedBaseSize,CurrentUsage,PeakUsage | Format-Table -AutoSize"

call :sect "Processus les plus gourmands"
call :ps "Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 15 ProcessName,@{N='RAM_Mo';E={[math]::Round($_.WorkingSet64/1MB,1)}},Id | Format-Table -AutoSize"

call :sect "Remarque"
call :log "  Aucun reglage memoire n'est modifie : les astuces de registre"
call :log "  du type DisablePagingExecutive ou LargeSystemCache n'apportent"
call :log "  rien sur Windows 10 et 11 et peuvent degrader la stabilite."
call :log "  Si la charge memoire est constamment au-dessus de 85 pourcent,"
call :log "  la solution est d'ajouter de la RAM ou de fermer des programmes."

call :log "  [OK] Etape 18 terminee."
call :ask_continue
if "%BACKTOMENU%"=="1" goto :menu
goto :exec_end


REM ================================================================
REM   ETAPE 19 - ANALYSE DEFENDER
REM ================================================================
:exec_19
call :banner 19 "ANALYSE ANTIVIRUS DEFENDER"

set "MPCMD=%ProgramFiles%\Windows Defender\MpCmdRun.exe"
if not exist "%MPCMD%" set "MPCMD="
if not defined MPCMD (
    call :ps "if (-not (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue)) { Write-Host '  Defender introuvable : un antivirus tiers est probablement installe.' }"
)

call :sect "Mise a jour des signatures"
if defined MPCMD (
    "%MPCMD%" -SignatureUpdate >nul 2>&1
) else (
    powershell -NoProfile -Command "if (Get-Command Update-MpSignature -ErrorAction SilentlyContinue) { Update-MpSignature -ErrorAction SilentlyContinue }" >nul 2>&1
)
call :ps "if (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue) { Get-MpComputerStatus | Select-Object AntivirusSignatureVersion,AntivirusSignatureLastUpdated | Format-List } else { Write-Host '  Module PowerShell Defender absent sur cette version de Windows.' }"

call :sect "Historique des menaces"
call :ps "if (Get-Command Get-MpThreatDetection -ErrorAction SilentlyContinue) { $t=Get-MpThreatDetection -ErrorAction SilentlyContinue | Sort-Object InitialDetectionTime -Descending | Select-Object -First 10; if ($t) { $t | Select-Object InitialDetectionTime,ThreatID,ActionSuccess | Format-Table -AutoSize } else { Write-Host '  Aucune menace enregistree.' } } else { Write-Host '  Historique consultable dans l interface de Defender.' }"

call :sect "Analyse rapide"
if defined MPCMD (
    "%MPCMD%" -Scan -ScanType 1
) else (
    powershell -NoProfile -Command "if (Get-Command Start-MpScan -ErrorAction SilentlyContinue) { Start-MpScan -ScanType QuickScan -ErrorAction SilentlyContinue }"
)
call :log "  [OK] Analyse rapide terminee."

call :confirm "Lancer une analyse complete ? Elle peut durer plus d'une heure."
if "%CONF%"=="1" (
    call :log "  [*] Analyse complete en cours..."
    if defined MPCMD (
        "%MPCMD%" -Scan -ScanType 2
    ) else (
        powershell -NoProfile -Command "if (Get-Command Start-MpScan -ErrorAction SilentlyContinue) { Start-MpScan -ScanType FullScan -ErrorAction SilentlyContinue }"
    )
    call :log "  [OK] Analyse complete terminee."
)

call :log "  [OK] Etape 19 terminee."
call :ask_continue
if "%BACKTOMENU%"=="1" goto :menu
goto :exec_end


REM ================================================================
REM   ETAPE 20 - MSRT
REM ================================================================
:exec_20
call :banner 20 "ANALYSE ANTI-MALWARE (MSRT)"

if not exist "%SystemRoot%\System32\MRT.exe" (
    call :log "  [INFO] MRT.exe absent. Il est livre par Windows Update."
    goto :exec_20_end
)

call :sect "Analyse en cours, cela peut prendre plusieurs minutes"
"%SystemRoot%\System32\MRT.exe" /N /Q

call :sect "Resultat"
call :ps "$l=$env:SystemRoot+'\debug\mrt.log'; if (Test-Path $l) { Get-Content $l -Tail 12 | ForEach-Object { Write-Host ('  '+$_) } } else { Write-Host '  Journal MSRT introuvable.' }"

:exec_20_end
call :log "  [OK] Etape 20 terminee."
call :ask_continue
if "%BACKTOMENU%"=="1" goto :menu
goto :exec_end


REM ================================================================
REM   ETAPE 21 - MISE A JOUR DES APPLICATIONS
REM ================================================================
:exec_21
call :banner 21 "MISE A JOUR DES APPLICATIONS (WINGET)"

where winget >nul 2>&1
if errorlevel 1 (
    call :log "  [ERREUR] WinGet indisponible."
    call :log "  WinGet demande Windows 10 version 1809 ou plus recent."
    call :log "  Sur Windows 10 et 11 : installer Programme d installation d application"
    call :log "  depuis le Microsoft Store. Sous Windows 8, mettre a jour manuellement."
    goto :exec_21_end
)

call :sect "Mises a jour disponibles"
call :cap winget upgrade --include-unknown --accept-source-agreements

call :confirm "Installer toutes les mises a jour listees ?"
if "%CONF%"=="0" goto :exec_21_end

call :sect "Installation"
winget upgrade --all --silent --accept-source-agreements --accept-package-agreements
call :log "  [OK] Mises a jour traitees."

:exec_21_end
call :log "  [OK] Etape 21 terminee."
call :ask_continue
if "%BACKTOMENU%"=="1" goto :menu
goto :exec_end


REM ================================================================
REM   ETAPE 22 - PILOTES GRAPHIQUES
REM ================================================================
:exec_22
call :banner 22 "MISE A JOUR DES PILOTES GRAPHIQUES"

call :sect "Carte graphique detectee"
call :ps "Get-CimInstance Win32_VideoController | Select-Object Name,DriverVersion,DriverDate | Format-Table -AutoSize"

set "GPU="
for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "(Get-CimInstance Win32_VideoController | Select-Object -First 1).Name"`) do set "GPU=%%A"
call :log "  GPU principal : %GPU%"

if "%NOPROMPT%"=="1" goto :exec_22_end

echo %GPU% | findstr /I "nvidia geforce quadro rtx gtx" >nul
if not errorlevel 1 (
    if exist "%ProgramFiles%\NVIDIA Corporation\NVIDIA app\CEF\NVIDIA app.exe" (
        start "" "%ProgramFiles%\NVIDIA Corporation\NVIDIA app\CEF\NVIDIA app.exe"
    ) else (
        start "" "https://www.nvidia.com/fr-fr/drivers/"
    )
    goto :exec_22_end
)
echo %GPU% | findstr /I "amd radeon" >nul
if not errorlevel 1 (
    if exist "%ProgramFiles%\AMD\CNext\CNext\RadeonSoftware.exe" (
        start "" "%ProgramFiles%\AMD\CNext\CNext\RadeonSoftware.exe"
    ) else (
        start "" "https://www.amd.com/fr/support"
    )
    goto :exec_22_end
)
echo %GPU% | findstr /I "intel iris xe arc uhd" >nul
if not errorlevel 1 (
    start "" "https://www.intel.com/content/www/fr/fr/download-center/home.html"
    goto :exec_22_end
)
call :log "  [INFO] Fabricant non identifie."

:exec_22_end
call :log "  [INFO] Sur un portable, preferer le pilote du fabricant du PC"
call :log "         si l'ecran ou la commutation graphique pose probleme."
call :log "  [OK] Etape 22 terminee."
call :ask_continue
if "%BACKTOMENU%"=="1" goto :menu
goto :exec_end


REM ================================================================
REM   OUTILS
REM ================================================================

:tool_restore_point
cls
call :make_restore_point
echo.
pause
goto :menu

:make_restore_point
call :sect "Point de restauration"
powershell -NoProfile -Command "try { Enable-ComputerRestore -Drive $env:SystemDrive -ErrorAction Stop } catch {}" >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v SystemRestorePointCreationFrequency /t REG_DWORD /d 0 /f >nul 2>&1
powershell -NoProfile -Command "try { Checkpoint-Computer -Description ('Maintenance '+(Get-Date -Format 'dd-MM-yyyy HH:mm')) -RestorePointType MODIFY_SETTINGS -ErrorAction Stop; exit 0 } catch { exit 1 }"
if errorlevel 1 (
    call :log "  [ERREUR] Point de restauration impossible."
    call :log "  Verifier que la protection du systeme est activee pour C:"
) else (
    call :log "  [OK] Point de restauration cree."
)
exit /b


:tool_telemetry
cls
echo.
echo  ================================================================
echo    DESACTIVATION DE LA TELEMETRIE
echo  ================================================================
echo.
echo  Services concernes : collecte de diagnostics, Xbox, cartes,
echo  fax, demonstration magasin, partage media.
echo.
echo  Ne sont PAS touches, car ils servent au depannage :
echo    WerSvc   rapports d'erreurs, utilises a l'etape 7
echo    PcaSvc   assistant de compatibilite des programmes
echo    lfsvc    geolocalisation, utilisee par Localiser mon appareil
echo.
call :confirm "Continuer ?"
if "%CONF%"=="0" goto :menu

set "ROLLBACK=%RPTDIR%\restaurer_services_%TS%.cmd"
>"%ROLLBACK%" echo @echo off
>>"%ROLLBACK%" echo REM Restauration de l'etat des services avant maintenance du %DATE_FR%
>>"%ROLLBACK%" echo net session ^>nul 2^>^&1 ^|^| ^(echo Executer en administrateur ^& pause ^& exit /b^)

for %%S in (DiagTrack dmwappushservice MapsBroker Fax XblAuthManager XblGameSave XboxNetApiSvc XboxGipSvc RetailDemo WMPNetworkSvc) do (
    sc query "%%S" >nul 2>&1
    if not errorlevel 1 (
        set "OLDSTART="
        for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "(Get-CimInstance Win32_Service -Filter ('Name='+[char]39+'%%S'+[char]39)).StartMode"`) do set "OLDSTART=%%V"
        set "SCSTART=auto"
        if /I "!OLDSTART!"=="Manual" set "SCSTART=demand"
        if /I "!OLDSTART!"=="Disabled" set "SCSTART=disabled"
        >>"%ROLLBACK%" echo sc config %%S start= !SCSTART!
        net stop "%%S" >nul 2>&1
        sc config "%%S" start= disabled >nul 2>&1
        call :log "  [DESACTIVE] %%S - etat precedent : !OLDSTART!"
    )
)

>>"%ROLLBACK%" echo echo Services restaures. Redemarrez le PC.
>>"%ROLLBACK%" echo pause
call :log ""
call :log "  [OK] Script de restauration : %ROLLBACK%"
call :log "      Le lancer en administrateur pour tout remettre en place."
echo.
pause
goto :menu


:tool_restore_services
cls
echo.
echo  ================================================================
echo    RESTAURATION DES SERVICES DESACTIVES
echo  ================================================================
echo.
dir /B "%RPTDIR%\restaurer_services_*.cmd" 2>nul
if errorlevel 1 (
    echo  Aucun script de restauration trouve dans :
    echo  %RPTDIR%
    echo.
    pause
    goto :menu
)
echo.
echo  Lancer le script correspondant depuis ce dossier,
echo  en tant qu'administrateur.
echo.
call :confirm "Ouvrir le dossier ?"
if "%CONF%"=="1" start "" explorer "%RPTDIR%"
pause
goto :menu


:tool_backup
cls
echo.
echo  ================================================================
echo    SAUVEGARDE DU PROFIL VERS UN DISQUE EXTERNE
echo  ================================================================
echo.
call :sect "Volumes disponibles"
call :ps "Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -ne 'CD-ROM' } | Select-Object DriveLetter,FileSystemLabel,DriveType,@{N='LibreGo';E={[math]::Round($_.SizeRemaining/1GB,1)}} | Format-Table -AutoSize"

call :sect "Taille du profil a sauvegarder"
call :ps "$s=(Get-ChildItem $env:USERPROFILE -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum; Write-Host ('  Environ '+[math]::Round($s/1GB,1)+' Go, dossiers systeme exclus au moment de la copie.')"

echo.
set "DEST="
set /p DEST="  Lettre du disque de destination (ex: E) ou vide pour annuler : "
if not defined DEST goto :menu
set "DEST=%DEST:~0,1%"
if not exist "%DEST%:\" (
    echo  [ERREUR] Le volume %DEST%: n'existe pas.
    pause
    goto :menu
)

set "BCK=%DEST%:\Sauvegardes\%COMPUTERNAME%_%USERNAME%\%TS%"
echo.
echo  Destination : %BCK%
echo  Exclusions  : AppData, caches, fichiers temporaires, OneDrive local.
call :confirm "Demarrer la copie ?"
if "%CONF%"=="0" goto :menu

mkdir "%BCK%" >nul 2>&1
robocopy "%USERPROFILE%" "%BCK%" /E /R:1 /W:1 /MT:8 /XJ ^
 /XD "AppData" "OneDrive" ".cache" "node_modules" "Application Data" "Local Settings" ^
 /XF "*.tmp" "*.temp" "thumbs.db" "desktop.ini" "ntuser.dat*" ^
 /NP /NFL /NDL /TEE /LOG:"%RPTDIR%\sauvegarde_%TS%.log"

if errorlevel 8 (
    call :log "  [ERREUR] La copie s'est terminee avec des erreurs."
) else (
    call :log "  [OK] Sauvegarde terminee : %BCK%"
)
call :log "      Journal : %RPTDIR%\sauvegarde_%TS%.log"
echo.
pause
goto :menu


:tool_openreport
start "" notepad "%REPORT%"
goto :menu


REM ================================================================
REM   ENCHAINEMENTS
REM ================================================================
:diag_all
cls
echo.
echo  ================================================================
echo    DIAGNOSTIC COMPLET AUTOMATIQUE
echo  ================================================================
echo.
echo  Les etapes 1 a 7 vont s'executer sans interaction.
echo  Aucune modification n'est apportee au systeme.
echo  Tout est ecrit dans :
echo  %REPORT%
echo.
pause
set "ALL_MODE=1"
set "NOPROMPT=1"
set "ALL_STEP=1"
set "ALL_LAST=7"
goto :exec_1

:exec_all
cls
echo.
echo  ================================================================
echo    EXECUTION COMPLETE - 22 ETAPES
echo  ================================================================
echo.
echo  Duree indicative : de une a plusieurs heures selon la machine.
echo  Apres chaque etape : C pour continuer, M pour revenir au menu.
echo  La desactivation de la telemetrie n'est PAS incluse ici,
echo  elle reste disponible via l'option T du menu.
echo.
call :confirm "Demarrer ?"
if "%CONF%"=="0" goto :menu
set "ALL_MODE=1"
set "ALL_STEP=1"
set "ALL_LAST=22"
goto :exec_1

:exec_end
if "%ALL_MODE%"=="1" goto :next_all_step
echo.
pause
goto :menu

:next_all_step
set /a "ALL_STEP=ALL_STEP+1"
if !ALL_STEP! leq %ALL_LAST% goto :exec_!ALL_STEP!
set "ALL_MODE=0"
set "NOPROMPT=0"
cls
echo.
echo  ================================================================
echo    SEQUENCE TERMINEE
echo  ================================================================
echo.
echo   Rapport : %REPORT%
echo.
pause
goto :menu


REM ================================================================
REM   SORTIE
REM ================================================================
:quit
cls
echo.
echo  ================================================================
echo    RESUME DE LA SESSION
echo  ================================================================
echo   Date        : %DATE_FR%
echo   Machine     : %COMPUTERNAME%
echo   Utilisateur : %USERNAME%
echo   Rapport     : %REPORT%
echo  ================================================================
echo.
>>"%REPORT%" echo.
>>"%REPORT%" echo Fin de session.

del "%TMPOUT%" >nul 2>&1

if "%REBOOT_NEEDED%"=="1" (
    echo  [!] Une ou plusieurs etapes demandent un redemarrage.
    call :confirm "Redemarrer maintenant ?"
    if "!CONF!"=="1" (
        echo.
        echo  Redemarrage dans 20 secondes. Fermer cette fenetre pour annuler,
        echo  ou taper : shutdown /a
        shutdown /r /t 20
        exit /b 0
    )
    echo  [OK] Redemarrage reporte. Pensez a le faire rapidement.
)

echo.
echo  Fermeture.
timeout /t 3 /nobreak >nul
exit /b 0
