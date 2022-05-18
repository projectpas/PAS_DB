
CREATE Procedure [dbo].[sp_GetWorkOrderBillingInvoiceChildList]
	@WorkOrderId  bigint,
	@WorkOrderPartId bigint
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN		
				
				SELECT * INTO #MyTempTable from 
					(SELECT DISTINCT 
						wosi.WorkOrderShippingId, 
						CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId) >0 THEN wobi.BillingInvoicingId  ELSE NULL END AS WOBillingInvoicingId, 
						CASE WHEN wop.ID IS NOT NULL and (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId) >0  THEN wobi.InvoiceDate ELSE NULL END AS InvoiceDate,
						CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId) >0  THEN wobi.InvoiceNo ELSE NULL END AS InvoiceNo, 
						wos.WOShippingNum, 
						wos.AirwayBill As 'AWB',
						(SUM(wosi.QtyShipped)- (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId)) as QtyToBill, 
						wo.WorkOrderNum as WorkOrderNumber, 
						imt.partnumber, 
						imt.PartDescription, 
						sl.StockLineNumber,
						sl.SerialNumber, 
						cr.[Name] as CustomerName, 
						(SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId) AS QtyBilled,
						'1' as ItemNo,
						wop.WorkOrderId, 
						wop.Id as WorkOrderPartId, 
						CASE WHEN  ISNULL(wosc.conditionName,'') = '' THEN cond.Description ELSE wosc.conditionName END as 'Condition',
						curr.Code as 'CurrencyCode',
						wocd.TotalCost as TotalSales,
						wobi.InvoiceStatus ,
						(CASE when (CASE WHEN wop.ID IS NOT NULL and  (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId and wobii.WorkOrderPartId = @WorkOrderPartId) >0 THEN wobi.BillingInvoicingId  ELSE NULL END) is null  then NULL else wobi.VersionNo end) as VersionNo ,
						imt.ItemMasterId,
						(CASE WHEN wobi.IsVersionIncrease = 1 then 0 else 1 end) IsAllowIncreaseVersion
						,ISNULL(wowf.WorkFlowWorkOrderId,0) WorkFlowWorkOrderId
					FROM DBO.WorkOrderShippingItem wosi WITH(NOLOCK)
						INNER JOIN DBO.WorkOrderShipping wos WITH(NOLOCK) on wosi.WorkOrderShippingId = wos.WorkOrderShippingId
						LEFT JOIN DBO.WorkOrderBillingInvoicing wobi WITH(NOLOCK) on wobi.WorkOrderId = wos.WorkOrderId
						LEFT JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on wobi.BillingInvoicingId = wobii.BillingInvoicingId
						INNER JOIN DBO.WorkOrderPartNumber wop WITH(NOLOCK) on wop.WorkOrderId = wos.WorkOrderId AND wop.ID = wosi.WorkOrderPartNumId
						LEFT JOIN DBO.WorkOrderMPNCostDetails wocd WITH(NOLOCK) on wop.ID = wocd.WOPartNoId
						INNER JOIN DBO.WorkOrderWorkFlow wowf WITH(NOLOCK) on wop.ID = wowf.WorkOrderPartNoId 
						INNER JOIN DBO.WorkOrder wo WITH(NOLOCK) on wo.WorkOrderId = wop.WorkOrderId
						LEFT JOIN dbo.WorkOrderSettlementDetails wosc WITH(NOLOCK) on wop.WorkOrderId = wosc.WorkOrderId AND wop.ID = wosc.workOrderPartNoId AND wosc.WorkOrderSettlementId = 9
						LEFT JOIN DBO.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = wop.ItemMasterId
						LEFT JOIN DBO.Stockline sl WITH(NOLOCK) on sl.StockLineId = wop.StockLineId
						LEFT JOIN DBO.WorkOrderCustomsInfo woc WITH(NOLOCK) on woc.WorkOrderShippingId = wos.WorkOrderShippingId
						LEFT JOIN DBO.Customer cr WITH(NOLOCK) on cr.CustomerId = wo.CustomerId
						LEFT JOIN DBO.Condition cond  WITH(NOLOCK) on cond.ConditionId = wop.ConditionId
						LEFT JOIN DBO.Currency curr WITH(NOLOCK) on curr.CurrencyId = wobi.CurrencyId
					WHERE wos.WorkOrderId = @WorkOrderId AND wop.ID = @WorkOrderPartId 

					GROUP BY wosi.WorkOrderShippingId, wobi.BillingInvoicingId, wobi.InvoiceDate, wobi.InvoiceNo, 
						wos.WOShippingNum, wos.AirwayBill, wo.WorkOrderNum, imt.partnumber, imt.PartDescription, sl.StockLineNumber,
						sl.SerialNumber, cr.[Name], wop.WorkOrderId, wop.ID, wobi.InvoiceStatus,
						CASE WHEN ISNULL(wosc.conditionName,'') = '' THEN cond.Description ELSE wosc.conditionName END,
						curr.Code,wobi.VersionNo,imt.ItemMasterId,wocd.TotalCost 
						, wobii.BillingInvoicingId,wobi.IsVersionIncrease,wowf.WorkFlowWorkOrderId
					) a

					;WITH CTE_Temp AS
						(
							SELECT *,
								ROW_NUMBER() OVER (PARTITION  By WorkOrderShippingId,IsAllowIncreaseVersion  ORDER BY WOBillingInvoicingId desc) AS RowNumber
							FROM #MyTempTable
						)
	
				select * from CTE_Temp t1
				where (((VersionNo is null and IsAllowIncreaseVersion =1) and ((select count(WorkOrderShippingId) from #MyTempTable t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0) and RowNumber =1)
						or ((VersionNo is not null and IsAllowIncreaseVersion =1) and ((select count(WorkOrderShippingId) from #MyTempTable t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0))
						or((VersionNo is null and IsAllowIncreaseVersion =0) and ((select count(WorkOrderShippingId) from #MyTempTable t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0) and RowNumber =1)
						or ((VersionNo is not null and IsAllowIncreaseVersion =0) and ((select count(WorkOrderShippingId) from #MyTempTable t2 where t2.WorkOrderPartId = t1.WorkOrderPartId) >0)))
						AND
						((VersionNo is null and InvoiceStatus is null) or  (VersionNo is not null and InvoiceStatus is not null) or (InvoiceStatus is not null and IsAllowIncreaseVersion = 1))
				order by WOBillingInvoicingId desc	
			drop table  #MyTempTable 
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'sp_GetWorkOrderBillingInvoiceChildList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + '''
													   @Parameter2 = ' + ISNULL(@WorkOrderPartId ,'') +''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END