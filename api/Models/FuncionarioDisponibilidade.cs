using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace api.Models;

[Index(nameof(IdFuncionario), nameof(DiaSemana))]
public class FuncionarioDisponibilidade
{
    [Key]
    public Guid Id { get; set; }

    [ForeignKey(nameof(Funcionario))]
    public Guid IdFuncionario { get; set; }

    [Range(0, 6)]
    public int DiaSemana { get; set; }

    public TimeOnly Inicio { get; set; }
    public TimeOnly Fim { get; set; }

    public Funcionario Funcionario { get; set; } = null!;
}
