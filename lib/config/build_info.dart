/// Set at compile time, e.g.
/// `flutter run --dart-define=BUILD_LABEL=main@7df1ec2`
const String kBuildLabel = String.fromEnvironment(
  'BUILD_LABEL',
  defaultValue: '',
);
