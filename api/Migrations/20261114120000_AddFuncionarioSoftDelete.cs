using Microsoft.EntityFrameworkCore.Migrations;

namespace api.Migrations;

public partial class AddFuncionarioSoftDelete : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AlterColumn<string>(
            name: "Endereco",
            table: "Funcionarios",
            type: "text",
            nullable: true,
            oldClrType: typeof(string),
            oldType: "text");

        migrationBuilder.AddColumn<bool>(
            name: "IsDeleted",
            table: "Funcionarios",
            type: "boolean",
            nullable: false,
            defaultValue: false);
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropColumn(
            name: "IsDeleted",
            table: "Funcionarios");

        migrationBuilder.AlterColumn<string>(
            name: "Endereco",
            table: "Funcionarios",
            type: "text",
            nullable: false,
            oldClrType: typeof(string),
            oldType: "text",
            oldNullable: true);
    }
}
