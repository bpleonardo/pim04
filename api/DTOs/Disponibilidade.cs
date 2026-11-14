using System.ComponentModel.DataAnnotations;

namespace api.DTOs;

public readonly record struct IntervaloDisponibilidadeDTO(TimeOnly Inicio, TimeOnly Fim);

public readonly record struct DiaDisponibilidadeDTO(
    [property: Range(0, 6)] int DiaSemana,
    IReadOnlyList<IntervaloDisponibilidadeDTO> Intervalos
);

public readonly record struct DisponibilidadeDTO(IReadOnlyList<DiaDisponibilidadeDTO> Dias);
