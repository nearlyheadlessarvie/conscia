using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Conscia.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class RemoveBudgetCurrentSpend : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CurrentSpend",
                table: "budgets");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<decimal>(
                name: "CurrentSpend",
                table: "budgets",
                type: "numeric(18,2)",
                precision: 18,
                scale: 2,
                nullable: false,
                defaultValue: 0m);
        }
    }
}
