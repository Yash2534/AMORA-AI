# Testing

Run:

```bash
flutter analyze
flutter test
```

The widget suite verifies app launch, every registered route renders, and primary frontend journeys remain exception-free at the supported viewport widths. It specifically catches Flutter rendering exceptions such as `RenderFlex` overflow.
