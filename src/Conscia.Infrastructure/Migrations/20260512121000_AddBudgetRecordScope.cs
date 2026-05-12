using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Conscia.Infrastructure.Migrations
{
    public partial class AddBudgetRecordScope : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "FamilySpaceId",
                table: "budgets",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Scope",
                table: "budgets",
                type: "character varying(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "Personal");

            migrationBuilder.AddColumn<DateTime>(
                name: "SharedAt",
                table: "budgets",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "SharedByUserId",
                table: "budgets",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_budgets_FamilySpaceId",
                table: "budgets",
                column: "FamilySpaceId");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_budgets_FamilySpaceId",
                table: "budgets");

            migrationBuilder.DropColumn(name: "FamilySpaceId", table: "budgets");
            migrationBuilder.DropColumn(name: "Scope", table: "budgets");
            migrationBuilder.DropColumn(name: "SharedAt", table: "budgets");
            migrationBuilder.DropColumn(name: "SharedByUserId", table: "budgets");
        }
    }
}
