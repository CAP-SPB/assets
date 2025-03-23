#requires -version 5
<#
.SYNOPSIS
  Скрипт пост-настройки
.DESCRIPTION
  Скрипт пост-настройки системы Windows на компьютерах Колледжа электроники и информационных технологий
.INPUTS
  None
.OUTPUTS
  None
.NOTES
  Version:        1.0
  Author:         konnlori
  Creation Date:  20.03.2025
  Purpose/Change: Первая версия
#>

# Глобальная переменная для хранения состояния интернет-соединения
$global:isInternetAvailable = Test-InternetConnection

function Init {
  # Инициализация скрипта
  Write-Host "Начало выполнения скрипта..."

  if ($global:isInternetAvailable) {
    try {
      Update-AllPackages
      Install-Packages
      Resize-TitleBar
      Resize-ScrollBar
      Increase-WallpaperQuality
      Enable-VerboseMessages
    } catch {
      Write-Error "Произошла ошибка во время выполнения скрипта: $_"
    }
  }
}

# Тест соединения
function Test-InternetConnection {
  param (
      [string]$remote = "ya.ru"
  )

  try {
      $pingResult = Test-Connection -ComputerName $remote -Count 3 -Quiet
      if ($pingResult) {
          Write-Host "Подключение к интернету установлено!"
          return $true
      } else {
          Write-Host "Нет подключения к интернету. Невозможно продолжить!"
          return $false
      }
  } catch {
      Write-Error "Ошибка во время тестирования подключения: $_"
      return $false
  }
}

# Обновление всех пакетов
function Update-AllPackages {
  try {
    Write-Host "Начало обновления приложений..."
    winget upgrade --all
    Write-Host "Все приложения были обновлены!"
    return $true
  } catch {
    throw "Произошла ошибка во время обновления: $_"
  }
}

# Установка необходимых пакетов
function Install-Packages {
  $tempWingetFile = [System.IO.Path]::Combine($env:TEMP, "winget-packages.json")
  $wingetPkgListUrl = "https://raw.githubusercontent.com/CAP-SPB/assets/refs/heads/main/Config/winget-packages.json"

  try {
    Invoke-WebRequest -Uri $wingetPkgListUrl -OutFile $tempWingetFile
    Write-Host "Начало установки приложений..."
    winget import $tempWingetFile
    Write-Host "Все приложения были установлены!"
    Remove-Item -Path $tempWingetFile
    return $true
  } catch {
    throw "Произошла ошибка при загрузке или обработке файла: $_"
  }
}

# Уменьшить размер заголовков окон
function Resize-TitleBar {
  try {
    New-ItemProperty -Path 'HKCU:\Control Panel\Desktop\WindowMetrics' -Name 'CaptionHeight' -Value '-270' -PropertyType DWORD -Force
    Write-Host "Размер заголовка окна изменён"
    return $true
  } catch {
    throw "Не удалось изменить размер заголовка окна: $_"
  }
}

# Уменьшить размер полос прокрутки
function Resize-ScrollBar {
  try {
    New-ItemProperty -Path 'HKCU:\Control Panel\Desktop\WindowMetrics' -Name 'ScrollWidth' -Value '-210' -PropertyType DWORD -Force
    Write-Host "Размер полос прокрутки изменён"
    return $true
  } catch {
    throw "Не удалось изменить размер полос прокрутки: $_"
  }
}

# Отключение сжатия обоев
function Increase-WallpaperQuality {
  try {
    New-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'JPEGImportQuality' -Value '100' -PropertyType DWORD -Force
    Write-Host "Сжатие обоев отключено"
    return $true
  } catch {
    throw "Не удалось отключить сжатие обоев: $_"
  }
}

# Подробные сообщения загрузки и выключения
function Enable-VerboseMessages {
  try {
    New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'verbosestatus' -Value '1' -PropertyType DWORD -Force
    Write-Host "Подробные сообщения загрузки включены"
    return $true
  } catch {
    throw "Не удалось включить подробные сообщения о загрузке: $_"
  }
}

# Групповые политики
function Group-Policy {
  # Установка обоев
  try {
    $wallpaperUrl = "https://github.com/CAP-SPB/assets/raw/refs/heads/main/Images/CapLogo.bmp"
    $wallpaperPath = "$env:ProgramData\CapWallpaper.bmp"
  
    Invoke-WebRequest -Uri $wallpaperUrl -OutFile $wallpaperPath
    Set-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows\Personalization' -Name 'DesktopWallpaper' -Value $wallpaperPath -Force
    New-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows\Personalization' -Name 'DesktopWallpaperStyle' -Value 2 -PropertyType DWORD -Force
    RUNDLL32.EXE user32.dll,UpdatePerUserSystemParameters
  } catch {
    throw "Не удалось установить обои: $_"
  }

  # Запретить Microsoft Store
  try {
    Set-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\WindowsStore' -Name 'RemoveWindowsStore' -Value 1 -Type DWORD
  } catch {
    throw "Не удалось запретить Microsoft Store: $_"
  }

  # Запретить посещение сайтов
  try {
  $domainsToBlock = @(
    "store.steampowered.com",
    "store.epicgames.com",
    "heroicgameslauncher.com",
    "playnite.link",
    "minecraft.net",
    "ubisoft.com",
    "ea.com",
    "download.battle.net",
    "vkplay.ru",
    "prismlauncher.org",
    "atlauncher.com"
  )

  $hostsFilePath = "C:\Windows\System32\drivers\etc\hosts"

  foreach ($domain in $domainsToBlock) {
    Add-Content -Path $hostsFilePath -Value "127.0.0.1 `t $domain"
}
  ipconfig /flushdns
  } catch {
    throw ("Произошла ошибка записи в hosts: $_")
  }
}

# Политики AppLocker
function AppLocker-Policy {

}

# Главная функция
Initialize