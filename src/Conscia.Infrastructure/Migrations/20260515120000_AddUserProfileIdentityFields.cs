using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Conscia.Infrastructure.Migrations
{
    /// <inheritdoc />
    [Migration("20260515120000_AddUserProfileIdentityFields")]
    public partial class AddUserProfileIdentityFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "DisplayName",
                table: "users",
                type: "character varying(120)",
                maxLength: 120,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ProfilePictureKey",
                table: "users",
                type: "character varying(512)",
                maxLength: 512,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DisplayName",
                table: "users");

            migrationBuilder.DropColumn(
                name: "ProfilePictureKey",
                table: "users");
        }
    }
}
