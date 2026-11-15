namespace api.DTOs;

public record ServicePriceChangeDTO(long Id, double OldPrice, double NewPrice, DateTime ChangedAt);
