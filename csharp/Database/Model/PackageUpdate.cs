using System;
using System.Collections.Generic;

#nullable disable

namespace Database.Model
{
    public partial class PackageUpdate
    {
        public int Id { get; set; }
        public int PackageVersionId { get; set; }
        public int DownloadsTotal { get; set; }
        public int Stars { get; set; }
        public int Watchers { get; set; }
        public int Forks { get; set; }
        public int Issues { get; set; }
        public double Score { get; set; }
        public DateTime StartDate { get; set; }

        public virtual PackageVersion PackageVersion { get; set; }
    }
}
