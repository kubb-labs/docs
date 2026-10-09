
Controls generated JSDoc.

| | |
| --- | --- |
| Type | `'full' \| 'brief' \| 'none'` |
| Required | `false` |
| Default | `'full'` |

::field-group

:::field{name="'full'"}
Default value. Keeps complete descriptions and tags.
:::

:::field{name="'brief'"}
Keeps the first sentence and other tags. Descriptions over 150 characters without a sentence ending are cut at the last word before 120.
:::

:::field{name="'none'"}
Omits JSDoc but keeps the generated-by banner.
:::

::
