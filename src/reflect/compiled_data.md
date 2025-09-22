---
aliases:
  - CompiledData
instance-of: datatype
tags:
  - asset
  - reflection
---
**CompiledData** is our binary format for generic data that we compile to disk, normally data that was [[packing|packed]] into [[source_data|SourceData]].

Compiled data heavily utilizes [[reflection]] to generate code that properly serializes reflected types.