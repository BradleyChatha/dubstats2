using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.HttpsPolicy;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Database.Model;
using Microsoft.EntityFrameworkCore;
using GraphQL.Server.Ui.Voyager;
using Api.Schema;

namespace Api
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddPooledDbContextFactory<DubstatsContext>(options =>
                options.UseNpgsql(Configuration.GetConnectionString("Default")), 2);
            services.AddControllers();
            services.AddGraphQLServer()
                    .AddQueryType<Query>()
                    .AddType<PackageDependencyMapType>()
                    .AddProjections()
                    .AddFiltering()
                    .AddSorting()
                    .AddMaxExecutionDepthRule(10);
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }

            app.UseHttpsRedirection();
            app.UseRouting();
            app.UseAuthorization();
            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
                endpoints.MapGraphQL();
            });
            app.UseGraphQLVoyager("/graphql-voyager");
        }
    }
}
