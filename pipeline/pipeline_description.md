# Pipeline: `Sales_Ingestion_Pipeline`

One Fabric data pipeline runs the whole load. Each activity runs only if the previous one succeeds ("On success").

| # | Activity | Type | What it does |
| --- | --- | --- | --- |
| 1 | `Delete_Previous_Working_CSV` | Delete data | Removes the old working copy in `Files/source_files_sales` so reruns stay clean. Never points at `Files/inbox` |
| 2 | `Copy_Sales_CSV` | Copy data | Copies `Files/inbox/SalesData.csv` (delimited text, header row) to `Files/source_files_sales/SalesData.csv` |
| 3 | `Transform_Sales_PySpark` | Notebook | Runs `Sales_Analytics_Notebook` with `table_name = sales_data_stage`; writes the Delta staging table |
| 4 | `Enrich_Customer_Names` | Dataflow | Runs `Sales_Customer_Dataflow`; adds `FirstName` and `LastName`; writes `sales_data_curated` (replace) |

The Warehouse load is **not** a pipeline activity here. After the pipeline succeeds, run `EXEC [Sales].[LoadDataFromStagingLakehouse] @OrderYear = <year>;` from the Warehouse (`sql/02_staging_view_and_load_procedure.sql`). It could be added as a Stored procedure activity after the Dataflow, using `Leadership_Reporting_DWH` and an integer `OrderYear` parameter.

Notes:
- On the very first run the working folder has nothing to delete, so deactivate the Delete activity or run Copy first.
- The source ends on 31 December 2021, so the pipeline has no schedule and is run manually. The Warehouse load is safe to rerun.
- Add a screenshot of the pipeline canvas as `docs/pipeline.png`.
