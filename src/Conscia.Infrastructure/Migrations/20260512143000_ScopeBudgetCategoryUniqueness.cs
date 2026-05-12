using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Conscia.Infrastructure.Migrations
{
    public partial class ScopeBudgetCategoryUniqueness : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_budgets_UserId_Category",
                table: "budgets");

            migrationBuilder.CreateIndex(
                name: "IX_budgets_UserId_Category",
                table: "budgets",
                columns: new[] { "UserId", "Category" },
                unique: true,
                filter: "\"Scope\" = 'Personal'");

            migrationBuilder.CreateIndex(
                name: "IX_budgets_FamilySpaceId_Category",
                table: "budgets",
                columns: new[] { "FamilySpaceId", "Category" },
                unique: true,
                filter: "\"Scope\" = 'Family'");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_budgets_FamilySpaceId_Category",
                table: "budgets");

            migrationBuilder.DropIndex(
                name: "IX_budgets_UserId_Category",
                table: "budgets");

            migrationBuilder.CreateIndex(
                name: "IX_budgets_UserId_Category",
                table: "budgets",
                columns: new[] { "UserId", "Category" },
                unique: true);
        }
    }
}
