
Overrides generated file and symbol names. Omitted members keep `resolverClient`. The shared members (`name`, `file`, `imports`) and the `this` context are described under [`resolver`](/docs/5.x/reference/plugin-options#resolver).

| | |
| --- | --- |
| Type | `ResolverPatch<ResolverClient>` |
| Required | `false` |

```typescript [Partial override]
type ResolverClientPatch = {
  name?(name: string): string
  file?: {
    baseName?(params: { name: string; extname: string }): string
    path?(params: { baseName: string; output: Output }): string
  }
  imports?(options: ResolveImportsOptions): Array<ImportNode>
  className?(name: string): string
  groupName?(name: string): string     // → 'PetClient'
  propertyName?(name: string): string
}
```
