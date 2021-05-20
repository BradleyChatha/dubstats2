using System;
using System.Linq;
using Database.Model;
using Microsoft.EntityFrameworkCore;

namespace Database
{
    public static class ModelFunctions
    {
        public static IQueryable<PackageVersion> GetPackageVersions(DubstatsContext context, string pname)
        {
            return context.PackageVersions.FromSqlInterpolated($"SELECT * FROM get_package_version('{pname}')");
        }

        public static IQueryable<Package> GetPackageDependenciesAllVersions(DubstatsContext context, string pname)
        {
            return context.Packages.FromSqlInterpolated($"SELECT * FROM get_package_dependencies_all_versions('{pname}')");
        }
    }
}