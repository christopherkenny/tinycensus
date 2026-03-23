# tinycensus: Lightweight Interface to the US Census Bureau API

`tinycensus` provides lightweight, metadata-driven access to the [US
Census Bureau API](https://www.census.gov/data/developers.html). The
package is organized around product-specific retrieval helpers such as
[`tc_get_acs()`](https://christophertkenny.com/tinycensus/reference/tc_get_acs.md),
[`tc_get_decennial()`](https://christophertkenny.com/tinycensus/reference/tc_get_decennial.md),
[`tc_get_pep()`](https://christophertkenny.com/tinycensus/reference/tc_get_pep.md),
[`tc_get_cbp()`](https://christophertkenny.com/tinycensus/reference/tc_get_cbp.md),
[`tc_get_pdb()`](https://christophertkenny.com/tinycensus/reference/tc_get_pdb.md),
[`tc_get_flows()`](https://christophertkenny.com/tinycensus/reference/tc_get_flows.md),
and
[`tc_get_timeseries()`](https://christophertkenny.com/tinycensus/reference/tc_get_timeseries.md),
rather than a single generic user-facing query function.

## Details

It also includes task-oriented metadata helpers for discovering
datasets, variables, geographies, and tables, along with flexible
geography inputs and optional geometry joins through `tinytiger`.

## See also

Useful links:

- <https://christophertkenny.com/tinycensus/>

- <https://github.com/christopherkenny/tinycensus>

- Report bugs at <https://github.com/christopherkenny/tinycensus/issues>

## Author

**Maintainer**: Christopher T. Kenny <ctkenny@proton.me>
([ORCID](https://orcid.org/0000-0002-9386-6860))
