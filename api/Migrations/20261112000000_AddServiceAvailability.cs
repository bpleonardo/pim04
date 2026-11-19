using api.Data;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace api.Migrations;

[DbContext(typeof(AppDbContext))]
[Migration("20261112000000_AddServiceAvailability")]
public partial class AddServiceAvailability : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<bool>(
            name: "Ativo",
            table: "Servicos",
            type: "boolean",
            nullable: false,
            defaultValue: true);
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropColumn(name: "Ativo", table: "Servicos");
    }
}
