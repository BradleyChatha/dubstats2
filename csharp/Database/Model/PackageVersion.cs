using System;
using System.Collections.Generic;

#nullable disable

namespace Database.Model
{
    public partial class PackageVersion
    {
        public PackageVersion()
        {
            PackageDependencyMaps = new HashSet<PackageDependencyMap>();
            PackageUpdates = new HashSet<PackageUpdate>();
        }

        public int Id { get; set; }
        public string Semver { get; set; }
        public string PackageName { get; set; }

        public virtual Package PackageNameNavigation { get; set; }
        public virtual ICollection<PackageDependencyMap> PackageDependencyMaps { get; set; }
        public virtual ICollection<PackageUpdate> PackageUpdates { get; set; }
    }
}
