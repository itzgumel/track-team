/// Cascade selection LGA -> Ward -> Health Facility -> Distribution Point.
/// Every level is optional; a null level means "all".
class GeoFilter {
  const GeoFilter({
    this.lga,
    this.ward,
    this.healthFacility,
    this.distributionPoint,
  });

  final String? lga;
  final String? ward;
  final String? healthFacility;
  final String? distributionPoint;

  bool get isEmpty =>
      lga == null &&
      ward == null &&
      healthFacility == null &&
      distributionPoint == null;

  /// Narrows to a new LGA, resetting the dependent levels.
  GeoFilter selectLga(String? value) => GeoFilter(lga: value);

  GeoFilter selectWard(String? value) => GeoFilter(lga: lga, ward: value);

  GeoFilter selectHealthFacility(String? value) =>
      GeoFilter(lga: lga, ward: ward, healthFacility: value);

  GeoFilter selectDistributionPoint(String? value) => GeoFilter(
        lga: lga,
        ward: ward,
        healthFacility: healthFacility,
        distributionPoint: value,
      );
}
