<#
#requires -version 5

.SYNOPSIS
  Скрипт пост-настройки
.DESCRIPTION
  Скрипт пост-настройки системы Windows на компьютерах Колледжа электроники и приборостроения
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

# Функция для проверки интернет-соединения
function Test-InternetConnection {
  param (
      [string]$remote = "ya.ru"
  )
  try {
      $pingResult = Test-Connection -ComputerName $remote -Count 3 -Quiet
      if ($pingResult) {
          Write-Output "Подключение к интернету установлено!"
          return $true
      } else {
          Write-Output "Нет подключения к инетрнету. Невозможно продолжить!"
          return $false
      }
  } catch {
      Write-Error "Ошибка во время тестирования подключения: $_"
      return $false
  }
}

# Функция для обновления всех пакетов через winget
function Update-AllPackages {
  if (Test-InternetConnection) {
      try {
          Write-Output "Начало обновления приложений..."
          winget upgrade --all
          Write-Output "Все приложения были обновлены!"
      } catch {
          Write-Error "Произошла ошибка во время обновления: $_"
        }
      } else {
      Write-Output "Невозможно продолжить из-за отсутствия подключения к инетрнету!"
  }
}

# Функция для установки пакетов
function Install-Packages {
  $tempWingetFile = [System.IO.Path]::Combine($env:TEMP, "winget-packages.json")
  $wingetPkgListUrl = "https://raw.githubusercontent.com/CAP-SPB/assets/refs/heads/main/Config/winget-packages.json"

  if (Test-InternetConnection) {
    try {
      Invoke-WebRequest -Uri $wingetPkgListUrl -OutFile $tempWingetFile
      Write-Output "Начало установки приложений..."
      winget import $tempWingetFile
      Write-Output "Все приложения были установлены!"
      Remove-Item -Path $tempWingetFile
  } catch {
      Write-Error "An error occurred while downloading or processing the file: $_"
    }
  }
}

# Функция для кастомизации интерфейса
function Customize {

}

# Вызов функций
Update-AllPackages
Install-Packages