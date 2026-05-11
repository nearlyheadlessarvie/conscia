using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Conscia.Infrastructure.Migrations
{
    public partial class AddEmailConfirmedToUsers : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "EmailConfirmed",
                table: "users",
                type: "boolean",
                nullable: false,
                defaultValue: true);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "EmailConfirmed",
                table: "users");
        }
    }
}
