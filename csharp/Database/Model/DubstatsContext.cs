using System;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata;

#nullable disable

namespace Database.Model
{
    public partial class DubstatsContext : DbContext
    {
        // public DubstatsContext()
        // {
        // }

        public DubstatsContext(DbContextOptions<DubstatsContext> options)
            : base(options)
        {
        }

        public virtual DbSet<Migration> Migrations { get; set; }
        public virtual DbSet<NextPackageNameWhichNeedsUpdating> NextPackageNameWhichNeedsUpdatings { get; set; }
        public virtual DbSet<Package> Packages { get; set; }
        public virtual DbSet<PackageDependencyMap> PackageDependencyMaps { get; set; }
        public virtual DbSet<PackageUpdate> PackageUpdates { get; set; }
        public virtual DbSet<PackageVersion> PackageVersions { get; set; }

        protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
        {
            if (!optionsBuilder.IsConfigured)
            {
                optionsBuilder.UseNpgsql("Name=ConnectionStrings:Default");
            }
        }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.HasAnnotation("Relational:Collation", "en_US.UTF-8");

            modelBuilder.Entity<Migration>(entity =>
            {
                entity.HasKey(e => e.Name)
                    .HasName("migrations_pkey");

                entity.ToTable("migrations");

                entity.Property(e => e.Name).HasColumnName("name");
            });

            modelBuilder.Entity<NextPackageNameWhichNeedsUpdating>(entity =>
            {
                entity.HasNoKey();

                entity.ToTable("next_package_name_which_needs_updating");

                entity.Property(e => e.Name)
                    .HasMaxLength(50)
                    .HasColumnName("name");
            });

            modelBuilder.Entity<Package>(entity =>
            {
                entity.HasKey(e => e.Name)
                    .HasName("package_pkey");

                entity.ToTable("package");

                entity.Property(e => e.Name)
                    .HasMaxLength(50)
                    .HasColumnName("name");

                entity.Property(e => e.LastUpdate)
                    .HasColumnName("last_update")
                    .HasDefaultValueSql("'1970-01-01 00:00:00'::timestamp without time zone");

                entity.Property(e => e.NextUpdate)
                    .HasColumnName("next_update")
                    .HasComputedColumnSql("(last_update + update_interval)", true);

                entity.Property(e => e.UpdateInterval)
                    .HasColumnName("update_interval")
                    .HasDefaultValueSql("'7 days'::interval");
            });

            modelBuilder.Entity<PackageDependencyMap>(entity =>
            {
                entity.ToTable("package_dependency_map");

                entity.HasIndex(e => new { e.PackageVersionId, e.PackageName }, "cs_package_dependency_map_version_id_name")
                    .IsUnique();

                entity.HasIndex(e => e.PackageName, "idx_package_dependency_map_package_name");

                entity.HasIndex(e => e.PackageVersionId, "idx_package_dependency_map_package_version_id");

                entity.Property(e => e.Id)
                    .HasColumnName("id")
                    .UseIdentityAlwaysColumn();

                entity.Property(e => e.PackageName)
                    .IsRequired()
                    .HasMaxLength(50)
                    .HasColumnName("package_name");

                entity.Property(e => e.PackageVersionId).HasColumnName("package_version_id");

                entity.HasOne(d => d.PackageVersion)
                    .WithMany(p => p.PackageDependencyMaps)
                    .HasForeignKey(d => d.PackageVersionId)
                    .HasConstraintName("fk_package_dependency_map_package_version");
            });

            modelBuilder.Entity<PackageUpdate>(entity =>
            {
                entity.ToTable("package_update");

                entity.HasIndex(e => new { e.PackageVersionId, e.StartDate }, "cs_package_version_id_start_date")
                    .IsUnique();

                entity.HasIndex(e => e.PackageVersionId, "idx_package_update_package_version_id");

                entity.Property(e => e.Id)
                    .HasColumnName("id")
                    .UseIdentityAlwaysColumn();

                entity.Property(e => e.DownloadsTotal).HasColumnName("downloads_total");

                entity.Property(e => e.Forks).HasColumnName("forks");

                entity.Property(e => e.Issues).HasColumnName("issues");

                entity.Property(e => e.PackageVersionId).HasColumnName("package_version_id");

                entity.Property(e => e.Score).HasColumnName("score");

                entity.Property(e => e.Stars).HasColumnName("stars");

                entity.Property(e => e.StartDate).HasColumnName("start_date");

                entity.Property(e => e.Watchers).HasColumnName("watchers");

                entity.HasOne(d => d.PackageVersion)
                    .WithMany(p => p.PackageUpdates)
                    .HasForeignKey(d => d.PackageVersionId)
                    .HasConstraintName("fk_package_update_package_version");
            });

            modelBuilder.Entity<PackageVersion>(entity =>
            {
                entity.ToTable("package_version");

                entity.HasIndex(e => new { e.Semver, e.PackageName }, "cs_semver_package_name")
                    .IsUnique();

                entity.HasIndex(e => e.PackageName, "idx_package_version_package_name");

                entity.Property(e => e.Id)
                    .HasColumnName("id")
                    .UseIdentityAlwaysColumn();

                entity.Property(e => e.PackageName)
                    .IsRequired()
                    .HasMaxLength(50)
                    .HasColumnName("package_name");

                entity.Property(e => e.Semver)
                    .IsRequired()
                    .HasMaxLength(50)
                    .HasColumnName("semver");

                entity.HasOne(d => d.PackageNameNavigation)
                    .WithMany(p => p.PackageVersions)
                    .HasForeignKey(d => d.PackageName)
                    .HasConstraintName("fk_package_version_package");
            });

            OnModelCreatingPartial(modelBuilder);
        }

        partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
    }
}
