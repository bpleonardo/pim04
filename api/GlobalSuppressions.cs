// This file is used by Code Analysis to maintain SuppressMessage
// attributes that are applied to this project.
// Project-level suppressions either have no target or are given
// a specific target and scoped to a namespace, type, member, etc.

using System.Diagnostics.CodeAnalysis;

[assembly: SuppressMessage(
    "Style",
    "IDE0305:Simplificar a inicialização de coleção",
    Justification = "`var.ToList()` é mais legível do que `[ .. var ]` em blocos grandes.",
    Scope = "module"
)]

[assembly: SuppressMessage(
    "Style",
    "IDE0290:Usar construtor primário",
    Justification = "O construtor é protegido portanto não é compatível com o uso de construtor primário.",
    Scope = "member",
    Target = "~M:api.Exceptions.AppException.#ctor(System.String,System.Int32,System.String)"
)]
