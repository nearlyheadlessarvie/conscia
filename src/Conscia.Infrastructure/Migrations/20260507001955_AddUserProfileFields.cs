using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Conscia.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddUserProfileFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "budgets",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Category = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    MonthlyLimit = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    CurrentSpend = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    CurrencyCode = table.Column<string>(type: "character varying(3)", maxLength: 3, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_budgets", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "receipts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    TransactionId = table.Column<Guid>(type: "uuid", nullable: false),
                    S3Key = table.Column<string>(type: "character varying(512)", maxLength: 512, nullable: false),
                    ExtractedData = table.Column<string>(type: "jsonb", nullable: true),
                    OcrConfidence = table.Column<double>(type: "double precision", nullable: false),
                    NeedsReview = table.Column<bool>(type: "boolean", nullable: false),
                    Status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_receipts", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "user_subscriptions",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Tier = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    Platform = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    OriginalTransactionId = table.Column<string>(type: "character varying(512)", maxLength: 512, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_user_subscriptions", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "users",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Email = table.Column<string>(type: "character varying(256)", maxLength: 256, nullable: false),
                    PreferredCurrency = table.Column<string>(type: "character varying(3)", maxLength: 3, nullable: false),
                    Locale = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    SpendingPersonality = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    IncomeRange = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    OccupationType = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    HouseholdSize = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    HasCompletedOnboarding = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_users", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "user_identities",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Provider = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    ProviderSub = table.Column<string>(type: "character varying(256)", maxLength: 256, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_user_identities", x => x.Id);
                    table.ForeignKey(
                        name: "FK_user_identities_users_UserId",
                        column: x => x.UserId,
                        principalTable: "users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_budgets_UserId",
                table: "budgets",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_budgets_UserId_Category",
                table: "budgets",
                columns: new[] { "UserId", "Category" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_receipts_TransactionId",
                table: "receipts",
                column: "TransactionId");

            migrationBuilder.CreateIndex(
                name: "IX_user_identities_Provider_ProviderSub",
                table: "user_identities",
                columns: new[] { "Provider", "ProviderSub" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_user_identities_UserId",
                table: "user_identities",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_user_subscriptions_OriginalTransactionId",
                table: "user_subscriptions",
                column: "OriginalTransactionId",
                unique: true,
                filter: "\"OriginalTransactionId\" IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_user_subscriptions_UserId",
                table: "user_subscriptions",
                column: "UserId");

            migrationBuilder.CreateIndex(
                name: "IX_users_Email",
                table: "users",
                column: "Email",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "budgets");

            migrationBuilder.DropTable(
                name: "receipts");

            migrationBuilder.DropTable(
                name: "user_identities");

            migrationBuilder.DropTable(
                name: "user_subscriptions");

            migrationBuilder.DropTable(
                name: "users");
        }
    }
}
