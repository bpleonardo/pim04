using Microsoft.EntityFrameworkCore.Migrations;

namespace api.Migrations;

public partial class AddRefreshSessions : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.CreateTable(
            name: "RefreshSessions",
            columns: table => new
            {
                Jti = table.Column<Guid>(type: "uuid", nullable: false),
                EmployeeId = table.Column<Guid>(type: "uuid", nullable: false),
                ExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_RefreshSessions", row => row.Jti);
                table.ForeignKey("FK_RefreshSessions_Usuarios_EmployeeId",
                    row => row.EmployeeId, "Usuarios", "IdFuncionario",
                    onDelete: ReferentialAction.Cascade);
            });

        migrationBuilder.CreateIndex("IX_RefreshSessions_EmployeeId",
            "RefreshSessions", "EmployeeId");
    }

    protected override void Down(MigrationBuilder migrationBuilder) =>
        migrationBuilder.DropTable("RefreshSessions");
}
