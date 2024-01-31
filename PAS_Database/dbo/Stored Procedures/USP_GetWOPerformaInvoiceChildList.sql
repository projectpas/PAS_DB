/*************************************************************           
 ** File:     [USP_GetWOPerformaInvoiceChildList]           
 ** Author:	  Devendra Shekh
 ** Description: This SP IS Used to get list of performa Invoices for WO Part    
 ** Purpose:         
 ** Date:   01/31/2024	
          
 ** PARAMETERS:             
         
 ** RETURN VALUE:           
  
 **************************************************************    
 ** Change History           
 **************************************************************           
 ** PR   	Date         Author				Change Description            
 ** --   	--------     -------			--------------------------------     
	1    01/31/2024		 Devendra Shekh		CREATED

	EXEC [USP_GetWOPerformaInvoiceChildList] 3543,3013

**************************************************************/ 

CREATE   Procedure [dbo].[USP_GetWOPerformaInvoiceChildList]
	@WorkOrderId  BIGINT,
	@WorkOrderPartId BIGINT
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN		

				SELECT * INTO #MyTempTable2 FROM 
				(SELECT DISTINCT 
					CASE WHEN wos.WorkOrderShippingId IS NOT NULL THEN wos.WorkOrderShippingId 
						 ELSE CASE WHEN wosisn.WorkOrderShippingId IS NOT NULL THEN wosisn.WorkOrderShippingId ELSE 0 END END AS WorkOrderShippingId, 
					CASE WHEN wop.ID IS NOT NULL AND  (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId AND wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 1) >0 THEN wobi.BillingInvoicingId  ELSE NULL END AS WOBillingInvoicingId, 
					CASE WHEN wop.ID IS NOT NULL AND (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId AND wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 1) >0  THEN wobi.InvoiceDate ELSE NULL END AS InvoiceDate,
					CASE WHEN wop.ID IS NOT NULL AND  (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId AND wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 1) >0  THEN wobi.InvoiceNo ELSE NULL END AS InvoiceNo, 
					CASE WHEN ISNULL(wos.WOShippingNum, '') = ''  THEN '' ELSE wos.WOShippingNum END AS WOShippingNum, 
				    CASE WHEN ISNULL(wos.AirwayBill, '') = '' THEN '' ELSE wos.AirwayBill END As 'AWB',
					CASE WHEN ISNULL(wos.WorkOrderShippingId, 0) != 0 
						 THEN (SUM(wosi.QtyShipped)- (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId AND wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 1))
						 ELSE (SUM(wop.Quantity)- (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId AND wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 1)) END AS QtyToBill, 
					wo.WorkOrderNum AS WorkOrderNumber, 
					CASE WHEN ISNULL(wobi.IsVersionIncrease, 0) = 1 AND wobi.ItemMasterId > 0 THEN imv.PartNumber ELSE 
					CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0  THEN wop.RevisedPartNumber ELSE imt.PartNumber END END AS 'PartNumber',
					CASE WHEN ISNULL(wobi.IsVersionIncrease, 0) = 1 AND wobi.ItemMasterId > 0 THEN imv.PartDescription ELSE 
					CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0  THEN wop.RevisedPartDescription ELSE imt.PartDescription END END AS 'PartDescription',
					sl.StockLineNumber,
					CASE WHEN ISNULL(wobi.IsVersionIncrease, 0) = 1 AND ISNULL(wobi.RevisedSerialNumber, '') != '' THEN wobi.RevisedSerialNumber 
					ELSE CASE WHEN ISNULL(wop.RevisedSerialNumber, '') = '' THEN sl.SerialNumber ELSE wop.RevisedSerialNumber END END AS 'SerialNumber', 
					cr.[Name] AS CustomerName, 
					(SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId AND wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 1) AS QtyBilled,
					'1' AS ItemNo,
					wop.WorkOrderId, 
					wop.Id AS WorkOrderPartId, 
					cond.Memo AS 'Condition',
					curr.Code AS 'CurrencyCode',
					(CASE WHEN (CASE WHEN wop.ID IS NOT NULL AND (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId AND wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 1) >0 THEN wobi.BillingInvoicingId  ELSE NULL END) IS NULL THEN 0 ELSE wobi.SubTotal END) AS TotalSales,
					wobi.InvoiceStatus ,
					(CASE WHEN (CASE WHEN wop.ID IS NOT NULL AND (SELECT COUNT(*) FROM DBO.WorkOrderBillingInvoicingItem wobii WHERE wobii.BillingInvoicingId = Wobi.BillingInvoicingId AND wobii.WorkOrderPartId = @WorkOrderPartId AND ISNULL(wobii.IsPerformaInvoice, 0) = 1) >0 THEN wobi.BillingInvoicingId  ELSE NULL END) IS NULL THEN NULL ELSE wobi.VersionNo END) AS VersionNo ,
					CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedItemmasterid ELSE imt.ItemMasterId END As ItemMasterId,
					(CASE WHEN wobi.IsVersionIncrease = 1 THEN 0 ELSE 1 END) IsAllowIncreaseVersion
					,ISNULL(wowf.WorkFlowWorkOrderId,0) WorkFlowWorkOrderId
					,ISNULL(wop.IsFinishGood,0)IsFinishGood
					,wobi.Notes
				FROM DBO.WorkOrderPartNumber wop WITH(NOLOCK)							
					LEFT JOIN dbo.WorkOrderWorkFlow wof WITH(NOLOCK) on wop.WorkOrderId = wof.WorkOrderId AND wof.WorkOrderPartNoId = @WorkOrderPartId
					LEFT JOIN DBO.WorkOrderBillingInvoicing wobi WITH(NOLOCK) on wobi.WorkOrderId = wop.WorkOrderId AND ISNULL(wobi.IsPerformaInvoice, 0) = 1
					LEFT JOIN DBO.WorkOrderBillingInvoicingItem wobii WITH(NOLOCK) on wobi.BillingInvoicingId = wobii.BillingInvoicingId AND ISNULL(wobii.IsPerformaInvoice, 0) = 1
					--LEFT JOIN DBO.WorkOrderMPNCostDetails wocd WITH(NOLOCK) on wop.ID = wocd.WOPartNoId
					INNER JOIN DBO.WorkOrderWorkFlow wowf WITH(NOLOCK) on wop.ID = wowf.WorkOrderPartNoId 
					INNER JOIN DBO.WorkOrder wo WITH(NOLOCK) on wo.WorkOrderId = wop.WorkOrderId
					LEFT JOIN DBO.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = wop.ItemMasterId
					LEFT JOIN DBO.ItemMaster imv WITH(NOLOCK) on imv.ItemMasterId = wobi.ItemMasterId
					LEFT JOIN DBO.Stockline sl WITH(NOLOCK) on sl.StockLineId = wop.StockLineId
					LEFT JOIN DBO.Customer cr WITH(NOLOCK) on cr.CustomerId = wo.CustomerId
					LEFT JOIN DBO.Condition cond  WITH(NOLOCK) on cond.ConditionId = wobi.ConditionId
					LEFT JOIN DBO.Currency curr WITH(NOLOCK) on curr.CurrencyId = wobi.CurrencyId
					LEFT JOIN DBO.WorkOrderShipping wos WITH(NOLOCK) on wos.WorkOrderId = wop.WorkOrderId AND wobi.WorkOrderShippingId = wos.WorkOrderShippingId
					LEFT JOIN DBO.WorkOrderShippingItem wosi WITH(NOLOCK) on wos.WorkOrderShippingId = wosi.WorkOrderShippingId AND wosi.WorkOrderPartNumId = wop.ID
					LEFT JOIN DBO.WorkOrderShipping wossn WITH(NOLOCK) on wop.WorkOrderId = wossn.WorkOrderId
					LEFT JOIN DBO.WorkOrderShippingItem wosisn WITH(NOLOCK) on wossn.WorkOrderShippingId = wosisn.WorkOrderShippingId AND wosisn.WorkOrderPartNumId = wop.ID
				WHERE wop.WorkOrderId = @WorkOrderId AND wop.ID = @WorkOrderPartId 
				
				GROUP BY wobi.BillingInvoicingId, wobi.InvoiceDate, wobi.InvoiceNo, 
					wo.WorkOrderNum, imt.partnumber, imt.PartDescription, sl.StockLineNumber,
					sl.SerialNumber, cr.[Name], wop.WorkOrderId, wop.ID, wobi.InvoiceStatus,
					--,wocd.TotalCost
					cond.Memo,curr.Code,wobi.VersionNo,imt.ItemMasterId,wobi.SubTotal 
					, wobii.WOBillingInvoicingItemId,wobi.IsVersionIncrease,wowf.WorkFlowWorkOrderId,wop.RevisedItemmasterid,wop.RevisedPartNumber,wop.RevisedPartDescription, wos.WorkOrderShippingId,wop.IsFinishGood
					,wobi.ItemMasterId,imv.PartNumber,imv.PartDescription,wop.RevisedSerialNumber,wobi.RevisedSerialNumber,wobi.Notes,wos.WOShippingNum,wos.AirwayBill,wos.WorkOrderShippingId
					,wosisn.WorkOrderShippingId
				) a

				;WITH CTE_Temp AS
				(
					SELECT *,
						ROW_NUMBER() OVER (PARTITION  By WorkOrderShippingId,IsAllowIncreaseVersion  ORDER BY WOBillingInvoicingId desc) AS RowNumber
					FROM #MyTempTable2
				)
				SELECT * FROM CTE_Temp t1
				WHERE (((VersionNo IS NULL AND IsAllowIncreaseVersion =1) AND ((SELECT count(WorkOrderShippingId) FROM #MyTempTable2 t2 WHERE t2.WorkOrderPartId = t1.WorkOrderPartId) >0) AND RowNumber =1)
						OR ((VersionNo IS NOT NULL AND IsAllowIncreaseVersion =1) AND ((SELECT count(WorkOrderShippingId) FROM #MyTempTable2 t2 WHERE t2.WorkOrderPartId = t1.WorkOrderPartId) >0))
						OR((VersionNo IS NULL AND IsAllowIncreaseVersion =0) AND ((SELECT count(WorkOrderShippingId) FROM #MyTempTable2 t2 WHERE t2.WorkOrderPartId = t1.WorkOrderPartId) >0) AND RowNumber =1)
						OR ((VersionNo IS NOT NULL AND IsAllowIncreaseVersion =0) AND ((SELECT count(WorkOrderShippingId) FROM #MyTempTable2 t2 WHERE t2.WorkOrderPartId = t1.WorkOrderPartId) >0)))
						AND
						((VersionNo IS NULL AND InvoiceStatus IS NULL) OR  (VersionNo IS NOT NULL AND InvoiceStatus IS NOT NULL) OR (InvoiceStatus IS NOT NULL AND IsAllowIncreaseVersion = 1))
				ORDER BY WOBillingInvoicingId desc	
				drop table  #MyTempTable2 
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWOPerformaInvoiceChildList' 
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