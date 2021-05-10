if (-Not (Test-Path "./connection_string.txt")) {
    throw "Please make a file called connection_string.txt, and put the Postgres connection string there."
}

Copy-Item -Path "./connection_string.txt" -Destination "/usr/local/bin" -Force

foreach ($item in ("d/migrator", "d/updater", "d/discoverer")) {
    Push-Location $item
    & dub build
    Copy-Item -Path "./bin/" -Destination "/usr/local/bin/" -Force -Recurse
    Pop-Location
}

Copy-Item -Path "./systemd/" -Destination "/etc/systemd/system/" -Force -Recurse

Write-Host "Done!"