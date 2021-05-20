using System.Linq;
using System.Threading.Tasks;
using Database.Model;
using HotChocolate;
using HotChocolate.Data;
using HotChocolate.Types;
using Microsoft.EntityFrameworkCore;

#nullable enable

namespace Api.Schema
{
    public class PackageDependencyMapType : ObjectType<PackageDependencyMap>
    {
        protected override void Configure(IObjectTypeDescriptor<PackageDependencyMap> descriptor)
        {
            descriptor
                .Field("packageNameNavigation")
                .ResolveWith<Resolvers>(r => r.GetPackageNameNavigation(default!, default!))
                .UseDbContext<DubstatsContext>()
                .UseProjection();
        }

        class Resolvers
        {
            public Task<Package?> GetPackageNameNavigation([ScopedService] DubstatsContext db, PackageDependencyMap map)
            {
                return db.Packages.FirstOrDefaultAsync(p => p.Name == map.PackageName);
            }
        }
    }
}