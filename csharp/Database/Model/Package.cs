using System;
using System.Collections.Generic;

#nullable disable

namespace Database.Model
{
    public partial class Package
    {
        public Package()
        {
            PackageVersions = new HashSet<PackageVersion>();
        }

        public string Name { get; set; }
        public TimeSpan UpdateInterval { get; set; }
        public DateTime? LastUpdate { get; set; }
        public DateTime? NextUpdate { get; set; }

        public virtual ICollection<PackageVersion> PackageVersions { get; set; }
    }
}
