using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Conscia.Infrastructure.Migrations
{
    public partial class AddManagedCategories : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "managed_categories",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    NormalizedName = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    Type = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    Scope = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    FamilySpaceId = table.Column<Guid>(type: "uuid", nullable: true),
                    IconKey = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    ColorKey = table.Column<string>(type: "character varying(40)", maxLength: 40, nullable: false),
                    IsArchived = table.Column<bool>(type: "boolean", nullable: false),
                    IsDefault = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    UpdatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_managed_categories", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_managed_categories_FamilySpaceId",
                table: "managed_categories",
                column: "FamilySpaceId");

            migrationBuilder.CreateIndex(
                name: "IX_managed_categories_FamilySpaceId_Type_NormalizedName",
                table: "managed_categories",
                columns: new[] { "FamilySpaceId", "Type", "NormalizedName" });

            migrationBuilder.CreateIndex(
                name: "IX_managed_categories_UserId",
                table: "managed_categories",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_managed_categories_UserId_Scope_Type_NormalizedName",
                table: "managed_categories",
                columns: new[] { "UserId", "Scope", "Type", "NormalizedName" });
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(name: "managed_categories");
        }
    }
}
