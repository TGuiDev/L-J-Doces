Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$mobileRoot = Resolve-Path (Join-Path $scriptRoot "..")

$commands = @(
    @("flutter", "test", "test/viewmodel/attendant_product_registration_viewmodel_test.dart"),
    @("flutter", "test", "test/viewmodel/attendant_product_registration_supabase_test.dart"),
    @("flutter", "test", "test/viewmodel")
)

$requiredPaths = @(
    "test/viewmodel/attendant_product_registration_viewmodel_test.dart",
    "test/viewmodel/attendant_product_registration_supabase_test.dart",
    "test/viewmodel"
)

Push-Location $mobileRoot
try {
    foreach ($path in $requiredPaths) {
        if (-not (Test-Path $path)) {
            Write-Host ("Arquivo ou pasta de teste nao encontrado: " + $path)
            exit 1
        }
    }

    foreach ($command in $commands) {
        Write-Host ""
        Write-Host ("Executando: " + ($command -join " "))

        $executable = $command[0]
        $arguments = $command[1..($command.Length - 1)]

        & $executable @arguments

        if ($LASTEXITCODE -ne 0) {
            Write-Host ""
            Write-Host ("Falha no comando: " + ($command -join " "))
            exit $LASTEXITCODE
        }
    }

    Write-Host ""
    Write-Host "Todos os testes de cadastro de produtos foram executados com sucesso."
}
finally {
    Pop-Location
}
