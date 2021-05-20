using System;
using System.Collections.Generic;

#nullable disable

namespace Database.Model
{
    public partial class PackageDependencyMap
    {
        public int Id { get; set; }
        public int PackageVersionId { get; set; }
        public string PackageName { get; set; }

        public virtual PackageVersion PackageVersion { get; set; }
    }
}
