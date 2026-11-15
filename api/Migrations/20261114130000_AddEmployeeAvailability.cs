using api.Data;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace api.Migrations;

[DbContext(typeof(AppDbContext))]
[Migration("20261114130000_AddEmployeeAvailability")]
public partial class AddEmployeeAvailability : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.CreateTable(
            name: "FuncionarioDisponibilidades",
            columns: table => new
            {
                Id = table.Column<Guid>(type: "uuid", nullable: false),
                IdFuncionario = table.Column<Guid>(type: "uuid", nullable: false),
                DiaSemana = table.Column<int>(type: "integer", nullable: false),
                Inicio = table.Column<TimeOnly>(type: "time without time zone", nullable: false),
                Fim = table.Column<TimeOnly>(type: "time without time zone", nullable: false)
            },
            constraints: table =>
            {
                table.PrimaryKey("PK_FuncionarioDisponibilidades", x => x.Id);
                table.ForeignKey(
                    "FK_FuncionarioDisponibilidades_Funcionarios_IdFuncionario",
                    x => x.IdFuncionario,
                    "Funcionarios",
                    "Id",
                    onDelete: ReferentialAction.Cascade);
            });

        migrationBuilder.CreateIndex(
            name: "IX_FuncionarioDisponibilidades_IdFuncionario_DiaSemana",
            table: "FuncionarioDisponibilidades",
            columns: new[] { "IdFuncionario", "DiaSemana" });
    }

    protected override void Down(MigrationBuilder migrationBuilder) =>
        migrationBuilder.DropTable(name: "FuncionarioDisponibilidades");
}
