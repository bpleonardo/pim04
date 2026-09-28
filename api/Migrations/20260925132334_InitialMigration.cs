using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace api.Migrations
{
    /// <inheritdoc />
    public partial class InitialMigration : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Clientes",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    DtNascimento = table.Column<DateOnly>(type: "date", nullable: true),
                    Nome = table.Column<string>(type: "text", nullable: false),
                    Telefone = table.Column<string>(
                        type: "character varying(13)",
                        maxLength: 13,
                        nullable: true
                    ),
                    CPF = table.Column<string>(
                        type: "character varying(11)",
                        maxLength: 11,
                        nullable: true
                    ),
                    Email = table.Column<string>(type: "text", nullable: true),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Clientes", x => x.Id);
                }
            );

            migrationBuilder.CreateTable(
                name: "Funcionarios",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Endereco = table.Column<string>(type: "text", nullable: false),
                    Nome = table.Column<string>(type: "text", nullable: false),
                    Telefone = table.Column<string>(
                        type: "character varying(13)",
                        maxLength: 13,
                        nullable: true
                    ),
                    CPF = table.Column<string>(
                        type: "character varying(11)",
                        maxLength: 11,
                        nullable: true
                    ),
                    Email = table.Column<string>(type: "text", nullable: true),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Funcionarios", x => x.Id);
                }
            );

            migrationBuilder.CreateTable(
                name: "Servicos",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Nome = table.Column<string>(type: "text", nullable: false),
                    Descricao = table.Column<string>(type: "text", nullable: true),
                    Preco = table.Column<double>(
                        type: "double precision",
                        precision: 6,
                        scale: 2,
                        nullable: false
                    ),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Servicos", x => x.Id);
                }
            );

            migrationBuilder.CreateTable(
                name: "Agendamentos",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    IdCliente = table.Column<Guid>(type: "uuid", nullable: false),
                    IdFuncionario = table.Column<Guid>(type: "uuid", nullable: false),
                    DataAgendamento = table.Column<DateTime>(
                        type: "timestamp with time zone",
                        nullable: false
                    ),
                    DataConclusao = table.Column<DateTime>(
                        type: "timestamp with time zone",
                        nullable: true
                    ),
                    Status = table.Column<string>(
                        type: "character varying(9)",
                        maxLength: 9,
                        nullable: false
                    ),
                    ValorTotal = table.Column<double>(
                        type: "double precision",
                        precision: 6,
                        scale: 2,
                        nullable: true
                    ),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Agendamentos", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Agendamentos_Clientes_IdCliente",
                        column: x => x.IdCliente,
                        principalTable: "Clientes",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict
                    );
                    table.ForeignKey(
                        name: "FK_Agendamentos_Funcionarios_IdFuncionario",
                        column: x => x.IdFuncionario,
                        principalTable: "Funcionarios",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );

            migrationBuilder.CreateTable(
                name: "Usuarios",
                columns: table => new
                {
                    IdFuncionario = table.Column<Guid>(type: "uuid", nullable: false),
                    Login = table.Column<string>(type: "text", nullable: false),
                    Senha = table.Column<string>(type: "text", nullable: false),
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Usuarios", x => x.IdFuncionario);
                    table.ForeignKey(
                        name: "FK_Usuarios_Funcionarios_IdFuncionario",
                        column: x => x.IdFuncionario,
                        principalTable: "Funcionarios",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade
                    );
                }
            );

            migrationBuilder.CreateTable(
                name: "ServicosRealizados",
                columns: table => new
                {
                    IdAgendamento = table.Column<Guid>(type: "uuid", nullable: false),
                    IdServico = table.Column<Guid>(type: "uuid", nullable: false),
                    Valor = table.Column<double>(
                        type: "double precision",
                        precision: 6,
                        scale: 2,
                        nullable: false
                    ),
                },
                constraints: table =>
                {
                    table.PrimaryKey(
                        "PK_ServicosRealizados",
                        x => new { x.IdServico, x.IdAgendamento }
                    );
                    table.ForeignKey(
                        name: "FK_ServicosRealizados_Agendamentos_IdAgendamento",
                        column: x => x.IdAgendamento,
                        principalTable: "Agendamentos",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade
                    );
                    table.ForeignKey(
                        name: "FK_ServicosRealizados_Servicos_IdServico",
                        column: x => x.IdServico,
                        principalTable: "Servicos",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict
                    );
                }
            );

            migrationBuilder.CreateIndex(
                name: "IX_Agendamentos_IdCliente",
                table: "Agendamentos",
                column: "IdCliente"
            );

            migrationBuilder.CreateIndex(
                name: "IX_Agendamentos_IdFuncionario",
                table: "Agendamentos",
                column: "IdFuncionario"
            );

            migrationBuilder.CreateIndex(
                name: "IX_Clientes_CPF",
                table: "Clientes",
                column: "CPF",
                unique: true
            );

            migrationBuilder.CreateIndex(
                name: "IX_Funcionarios_CPF",
                table: "Funcionarios",
                column: "CPF",
                unique: true
            );

            migrationBuilder.CreateIndex(
                name: "IX_Funcionarios_Email",
                table: "Funcionarios",
                column: "Email",
                unique: true
            );

            migrationBuilder.CreateIndex(
                name: "IX_Servicos_Nome",
                table: "Servicos",
                column: "Nome",
                unique: true
            );

            migrationBuilder.CreateIndex(
                name: "IX_ServicosRealizados_IdAgendamento",
                table: "ServicosRealizados",
                column: "IdAgendamento"
            );

            migrationBuilder.CreateIndex(
                name: "IX_Usuarios_Login",
                table: "Usuarios",
                column: "Login",
                unique: true
            );
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(name: "ServicosRealizados");

            migrationBuilder.DropTable(name: "Usuarios");

            migrationBuilder.DropTable(name: "Agendamentos");

            migrationBuilder.DropTable(name: "Servicos");

            migrationBuilder.DropTable(name: "Clientes");

            migrationBuilder.DropTable(name: "Funcionarios");
        }
    }
}
