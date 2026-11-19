using Microsoft.EntityFrameworkCore.Migrations;
namespace api.Migrations;
public partial class AddOfflineAppointments : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<string>("ClientRequestId", "Agendamentos", type: "character varying(32)", maxLength: 32, nullable: true);
        migrationBuilder.AddColumn<string>("LastMutationId", "Agendamentos", type: "character varying(32)", maxLength: 32, nullable: true);
        migrationBuilder.AddColumn<string>("RequestHash", "Agendamentos", type: "text", nullable: true);
        migrationBuilder.AddColumn<long>("Revision", "Agendamentos", type: "bigint", nullable: false, defaultValue: 0L);
        migrationBuilder.CreateIndex("IX_Agendamentos_ClientRequestId", "Agendamentos", "ClientRequestId", unique: true);
    }
    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropIndex("IX_Agendamentos_ClientRequestId", "Agendamentos");
        migrationBuilder.DropColumn("ClientRequestId", "Agendamentos");
        migrationBuilder.DropColumn("LastMutationId", "Agendamentos");
        migrationBuilder.DropColumn("RequestHash", "Agendamentos");
        migrationBuilder.DropColumn("Revision", "Agendamentos");
    }
}
