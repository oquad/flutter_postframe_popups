# Development

From the package root:

```sh
flutter pub get
bash tool/check.sh
```

The check script runs formatting, strict analyzer diagnostics, readability
metrics, package and example tests, the spotlight tests in Chrome, and
`flutter pub publish --dry-run`. Chrome must be installed for the browser tests.
The dry run checks the archive without uploading it; server-side name approval
still happens during an actual publish.

## Readability policy

Analysis enables strict casts, inference, and raw types. Explicit lint rules
are errors. Example code inherits the same configuration. Public APIs require
documentation; asynchronous work must be awaited or deliberately detached.

The free MIT-licensed Dart Code Linter 4.4.2 is a maintained Dart Code Metrics
fork. No paid license is required.

Limits: complexity <= 5, nesting <= 3, method/function parameters <= 5,
methods per class <= 10, source lines per function <= 40, and maintainability
index >= 65. Test registration code is exempt from size metrics; lint rules
still apply. Production code needs no metric suppressions or analyzer exclusions.

## Example layout

`example/lib/demos/` contains the package usage. Dialog/sheet content lives in
`content/`, with result feedback and optional custom presenters in `support/`.
The application and navigation shell stay outside the demos.

Run `flutter pub get` and `flutter run -d chrome` from `example/` to try it.
