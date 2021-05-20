# Macrohard hate things being easy.

$connection = [System.IO.File]::ReadAllText($(Get-location).Path + "/connection_string.txt");

dotnet new web -n __temp -o __temp
Push-Location "./__temp"

dotnet add package Microsoft.EntityFrameworkCore.Design
dotnet add package Npgsql.EntityFrameworkCore.PostgreSQL

dotnet user-secrets init --id "scaffold"
dotnet user-secrets set ConnectionStrings:Default "$connection"
dotnet ef dbcontext scaffold Name=ConnectionStrings:Default Npgsql.EntityFrameworkCore.PostgreSQL -o ../Model --force -n Database.Model -c DubstatsContext

Pop-Location
Remove-Item -Recurse "./__temp"