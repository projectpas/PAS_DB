/**********************************************************************************
** Function:    dbo.fnGetSalesOrderSoAmount
** Purpose:     Part-wise SO Amount roll-up for one Sales Order.
**              Extracted verbatim (logic-wise) from the OUTER APPLY "Z" that used
**              to live inside dbo.SearchSOViewData, so the value is unchanged.
**
** WHY A FUNCTION:
**   SearchSOViewData needs this value in two places (once for filter/sort on a
**   candidate set, once for the returned page). Keeping it in one place avoids the
**   two copies drifting apart.
**
** IMPORTANT: this is an INLINE table-valued function (RETURNS TABLE ... RETURN
**   (SELECT ...)) - NOT a scalar UDF and NOT a multi-statement TVF. The optimizer
**   expands the body into the calling query, so there is no per-row invocation
**   penalty and no loss of parallelism. Do NOT convert it to a scalar function or
**   add BEGIN/END, that would reintroduce exactly the problem we are fixing.
**
** SIMPLIFICATIONS APPLIED (all provably value-preserving):
**   1. The original joined "DBO.SalesOrder quote" purely to say
**      quote.SalesOrderId = SO.SalesOrderId. That whole table access is removed;
**      the id is now the parameter.
**   2. The original had a nested OUTER APPLY "U" that fetched UnitSalesPrice from
**      SalesOrderPartV1 for the SAME SalesOrderPartId it was already sitting on:
**          OUTER APPLY (SELECT ISNULL(SOQPS2.UnitSalesPrice,0)
**                       FROM SalesOrderPartV1 SOQPS2
**                       LEFT JOIN SalesOrderStocklineV1 stk2 ON ...
**                       WHERE SOQPS2.SalesOrderId   = quote.SalesOrderId
**                         AND SOQPS2.SalesOrderPartId = SOP.SalesOrderPartId
**                       GROUP BY SOQPS2.UnitSalesPrice) U
**      stk2 contributed no columns, and the GROUP BY only de-duplicated the rows
**      the stk2 join had just created. U.UnitSalesPrice is therefore identical to
**      SOP.UnitSalesPrice. That removes a correlated sub-plan (plus a view access
**      and a join) for every part of every Sales Order.
**   3. GROUP BY U.UnitSalesPrice, SOP.SalesOrderPartId, SOP.QtyRequested
**      becomes  GROUP BY SOP.SalesOrderPartId, SOP.QtyRequested, SOP.UnitSalesPrice
**      (same grouping, same result).
***********************************************************************************/
CREATE   FUNCTION dbo.fnGetSalesOrderSoAmount
(
	@SalesOrderId BIGINT
)
RETURNS TABLE
AS
RETURN
(
	SELECT SUM(X.NetSales) AS SoAmount
	FROM
	(
		SELECT
			(
				CASE
					WHEN ISNULL(SOP.QtyRequested, 0) =
					     ISNULL(SUM(CASE WHEN stk.SalesOrderStocklineId IS NOT NULL
					                     THEN stk.QtyOrder
					                     ELSE SOP.QtyOrder
					                END), 0)
					THEN 0
					ELSE
					(
						(
							ISNULL(SUM(
								CASE WHEN stk.SalesOrderStocklineId IS NOT NULL
								     THEN stk.QtyOrder
								     ELSE CASE WHEN ISNULL(SOP.QtyOrder, 0) > 0
								               THEN ISNULL(SOP.QtyOrder, 0)
								               ELSE ISNULL(SOP.QtyRequested, 0)
								          END
								END), 0) * -1
							+ ISNULL(SOP.QtyRequested, 0)
						) * ISNULL(SOP.UnitSalesPrice, 0)
					)
				END
			)
			+
			ISNULL(SUM(
				CASE WHEN SC.SalesOrderStocklineId IS NOT NULL
				     THEN ISNULL(SC.NetSaleAmount,    0)
				     ELSE ISNULL(SOQPS.NetSaleAmount, 0)
				END), 0)                                            AS NetSales
		FROM dbo.SalesOrderPartV1 SOP WITH (NOLOCK)
		INNER JOIN dbo.SalesOrderPartCost SOQPS WITH (NOLOCK)
			ON  SOQPS.SalesOrderId     = SOP.SalesOrderId
			AND SOQPS.SalesOrderPartId = SOP.SalesOrderPartId
		LEFT JOIN dbo.SalesOrderStocklineV1 stk WITH (NOLOCK)
			ON stk.SalesOrderPartId = SOP.SalesOrderPartId
		LEFT JOIN dbo.SalesOrderStockLineCost SC WITH (NOLOCK)
			ON  SC.SalesOrderStocklineId = stk.SalesOrderStocklineId
			AND SC.SalesOrderId          = SOP.SalesOrderId
		WHERE SOP.SalesOrderId = @SalesOrderId
		GROUP BY SOP.SalesOrderPartId, SOP.QtyRequested, SOP.UnitSalesPrice
	) X
);