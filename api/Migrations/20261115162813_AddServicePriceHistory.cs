using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace api.Migrations
{
    /// <inheritdoc />
    public partial class AddServicePriceHistory : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "ServicePriceChanges",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    ServiceId = table.Column<Guid>(type: "uuid", nullable: true),
                    ServiceName = table.Column<string>(type: "text", nullable: false),
                    OldPrice = table.Column<double>(type: "double precision", precision: 6, scale: 2, nullable: false),
                    NewPrice = table.Column<double>(type: "double precision", precision: 6, scale: 2, nullable: false),
                    ChangedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ServicePriceChanges", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ServicePriceChanges_Servicos_ServiceId",
                        column: x => x.ServiceId,
                        principalTable: "Servicos",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ServicePriceChanges_ServiceId",
                table: "ServicePriceChanges",
                column: "ServiceId");
            migrationBuilder.Sql("""
                CREATE FUNCTION public.record_service_price_change() RETURNS trigger
                LANGUAGE plpgsql AS $audit$
                BEGIN
                    INSERT INTO public."ServicePriceChanges"
                        ("ServiceId", "ServiceName", "OldPrice", "NewPrice", "ChangedAt")
                    VALUES (NEW."Id", NEW."Nome", OLD."Preco", NEW."Preco", clock_timestamp());
                    RETURN NEW;
                END;
                $audit$;

                CREATE TRIGGER service_price_changed
                AFTER UPDATE OF "Preco" ON public."Servicos"
                FOR EACH ROW WHEN (OLD."Preco" IS DISTINCT FROM NEW."Preco")
                EXECUTE FUNCTION public.record_service_price_change();
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("DROP TRIGGER service_price_changed ON public.\"Servicos\"; DROP FUNCTION public.record_service_price_change();");
            migrationBuilder.DropTable(
                name: "ServicePriceChanges");
        }
    }
}
