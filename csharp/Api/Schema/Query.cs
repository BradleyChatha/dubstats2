using System.Collections.Generic;
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
    public class Query
    {
        [UseDbContext(typeof(DubstatsContext))]
        [UsePaging]
        [UseProjection]
        public IQueryable<Package> GetPackages([ScopedService] DubstatsContext db) => db.Packages.OrderBy(p => p.LastUpdate);

        [UseDbContext(typeof(DubstatsContext))]
        [UseProjection]
        public Task<Package?> GetPackageAsync([ScopedService] DubstatsContext db, string name) => db.Packages.FirstOrDefaultAsync(p => p.Name == name);
    }
}