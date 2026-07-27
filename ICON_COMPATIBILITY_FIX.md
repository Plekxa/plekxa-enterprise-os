# Icon compatibility fix (v1.4)

The project no longer imports `lucide-react`.

All interface icons are provided by `components/icons.tsx`, a local typed SVG icon library. This removes package-version export mismatches such as `BarChart3`, `Globe2`, `Globe`, `Music2`, `Clock3`, and similar aliases.

Every icon imported by pages/components and every icon name referenced by sidebar navigation was checked against the local exports before packaging.
