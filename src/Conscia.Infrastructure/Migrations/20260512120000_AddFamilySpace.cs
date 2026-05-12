using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Conscia.Infrastructure.Migrations
{
    public partial class AddFamilySpace : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "family_invites",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    FamilySpaceId = table.Column<Guid>(type: "uuid", nullable: false),
                    Email = table.Column<string>(type: "character varying(256)", maxLength: 256, nullable: false),
                    Role = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    InvitedByUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    AcceptedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    DeclinedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_family_invites", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "family_members",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    FamilySpaceId = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Role = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    JoinedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_family_members", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "family_spaces",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(120)", maxLength: 120, nullable: false),
                    CurrencyCode = table.Column<string>(type: "character varying(3)", maxLength: 3, nullable: false),
                    CreatedByUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    PremiumGraceEndsAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsReadOnly = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_family_spaces", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_family_invites_Email",
                table: "family_invites",
                column: "Email");

            migrationBuilder.CreateIndex(
                name: "IX_family_invites_FamilySpaceId_Email",
                table: "family_invites",
                columns: new[] { "FamilySpaceId", "Email" });

            migrationBuilder.CreateIndex(
                name: "IX_family_members_FamilySpaceId_UserId",
                table: "family_members",
                columns: new[] { "FamilySpaceId", "UserId" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_family_members_UserId",
                table: "family_members",
                column: "UserId",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_family_spaces_CreatedByUserId",
                table: "family_spaces",
                column: "CreatedByUserId");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(name: "family_invites");
            migrationBuilder.DropTable(name: "family_members");
            migrationBuilder.DropTable(name: "family_spaces");
        }
    }
}
