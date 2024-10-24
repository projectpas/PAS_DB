﻿/*********************             
 ** File:   [GetCreditMemoById]             
 ** Author:  Moin Bloch  
 ** Description: This stored procedure is used to Get Credit Memo Details  
 ** Purpose:           
 ** Date:   18/04/2022        
            
 ** PARAMETERS: @CreditMemoHeaderId bigint  
           
 ** RETURN VALUE:             
 **********************             
 ** Change History             
 **********************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		--------------------------------            
    1    18/04/2022  Moin Bloch			Created  
	2    20/05/2022  Subhash Saliya     Updated  
	3    12/09/2022  AMIT GHEDIYA		Updated for get IsStandAloneCM value.
    4    18/10/2023  BHARGAV SALIYA     Get CurrencyId   
	5	 01/02/2024	 AMIT GHEDIYA	    added isperforma Flage for SO
	6	 19/04/2024	 Devendra Shekh	    added isExchange to select
	7	 19/04/2024	 Devendra Shekh	    added InvoiceTypeId to select and removed isExchange
	8	 27/06/2024	 Moin Bloch	    added AcctingPeriodId 

-- EXEC GetCreditMemoById 8  
  
************************/  
CREATE   PROCEDURE [dbo].[GetCreditMemoById]  
@CreditMemoHeaderId bigint  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY  
  
 Declare @ModuleID int = 61  
 Declare @WOInvoiceTypeId int = 0;
 Declare @SOInvoiceTypeId int = 0;
 Declare @ExchangeInvoiceTypeId int = 0;

 SELECT @WOInvoiceTypeId = CustomerInvoiceTypeId FROM [DBO].[CustomerInvoiceType] WHERE UPPER([ModuleName]) = 'WORKORDER';
 SELECT @SOInvoiceTypeId = CustomerInvoiceTypeId FROM [DBO].[CustomerInvoiceType] WHERE UPPER([ModuleName]) = 'SALESORDER';
 SELECT @ExchangeInvoiceTypeId = CustomerInvoiceTypeId FROM [DBO].[CustomerInvoiceType] WHERE UPPER([ModuleName]) = 'EXCHANGE';
 
 SELECT CM.[CreditMemoHeaderId]  
      ,CM.[CreditMemoNumber]  
      ,CM.[RMAHeaderId]  
      ,CM.[RMANumber]  
      ,CM.[InvoiceId]  
      ,CM.[InvoiceNumber]  
      ,ISNULL(CM.[InvoiceDate],NULL) AS 'InvoiceDate'
      ,CM.[StatusId]  
      ,CM.[Status]  
      ,CM.[CustomerId]  
      ,CM.[CustomerName]  
      ,CM.[CustomerCode]  
      ,CM.[CustomerContactId]  
      ,CM.[CustomerContact]  
      ,CM.[CustomerContactPhone]  
      ,CM.[IsWarranty]  
      ,CM.[IsAccepted]  
      ,CM.[ReasonId]  
	  ,CM.[Reason]  
      ,CM.[DeniedMemo]  
      ,CM.[RequestedById]  
      ,CM.[RequestedBy]  
      ,CM.[ApproverId]  
      ,CM.[ApprovedBy]  
      ,CM.[WONum]  
      ,CM.[WorkOrderId]  
      ,CM.[Originalwosonum]  
      ,CM.[Memo]  
      ,CM.[Notes]  
      ,CM.[ManagementStructureId]  
      ,CM.[IsEnforce]  
      ,CM.[MasterCompanyId]  
      ,CM.[CreatedBy]  
      ,CM.[UpdatedBy]  
      ,CM.[CreatedDate]  
      ,CM.[UpdatedDate]  
      ,CM.[IsActive]  
      ,CM.[IsDeleted]  
	  ,MS.[LastMSLevel]  
      ,MS.[AllMSlevels]  
	  ,CR.[CreditMemoDetailId]  
	  ,CM.[IsWorkOrder]  
	  ,CM.[ReferenceId]  
	  ,ISNULL(CM.[ReturnDate],NULL) AS 'ReturnDate'
	  ,CM.[PDFPath]  
	  ,CM.[FreightBilingMethodId]  
      ,CM.[TotalFreight]  
	  ,CM.[ChargesBilingMethodId]  
      ,CM.[TotalCharges] 
	  ,CM.[AcctingPeriodId] 	  
	  ,CRMA.[ValidDate]  
	  ,CRMA.[CreatedDate] 'RMAIssueDate'  
	  ,CF.CurrencyId
	  ,CASE WHEN CM.[IsWorkOrder]=1 THEN (SELECT ISNULL(WB.PostedDate,NULL) FROM [dbo].[WorkOrderBillingInvoicing] WB WITH (NOLOCK) WHERE WB.[BillingInvoicingId] = CM.[InvoiceId])  
			WHEN ISNULL(CM.InvoiceTypeId, 0) = @ExchangeInvoiceTypeId THEN (SELECT ISNULL(ESB.PostedDate,NULL) FROM [dbo].[ExchangeSalesOrderBillingInvoicing] ESB WITH (NOLOCK) WHERE ESB.[SOBillingInvoicingId] = CM.[InvoiceId])
			ELSE (SELECT ISNULL(SB.PostedDate,NULL) FROM [dbo].[SalesOrderBillingInvoicing] SB WITH (NOLOCK) WHERE SB.[SOBillingInvoicingId] = CM.[InvoiceId] AND ISNULL(SB.[IsProforma],0) = 0)  
			END AS 'PostedDate'   
      ,CASE WHEN CM.[IsWorkOrder]=1 THEN  STUFF((SELECT ', ' + WP.CustomerReference  
			   FROM dbo.WorkOrderBillingInvoicing WI WITH (NOLOCK)  
			   INNER JOIN dbo.WorkOrderPartNumber WP WITH (NOLOCK) ON WI.WorkOrderId=WP.WorkOrderId  
			   WHERE WI.BillingInvoicingId = CM.[InvoiceId]  
			   FOR XML PATH('')), 1, 1, '')   
	   WHEN ISNULL(CM.InvoiceTypeId, 0) = @ExchangeInvoiceTypeId THEN STUFF((SELECT ', ' + ESO.CustomerReference  
			   FROM dbo.[ExchangeSalesOrderBillingInvoicing] ESBI WITH (NOLOCK)  
			   INNER JOIN dbo.ExchangeSalesOrder ESO WITH (NOLOCK) ON ESBI.ExchangeSalesOrderId = ESO.ExchangeSalesOrderId  
			   WHERE ESBI.SOBillingInvoicingId = CM.[InvoiceId]  
			   GROUP BY ESBI.ExchangeSalesOrderId,ESO.CustomerReference
			   FOR XML PATH('')), 1, 1, '')   
       ELSE   
			   STUFF((SELECT ', ' + SO.CustomerReference FROM dbo.SalesOrderBillingInvoicing SI WITH (NOLOCK)  
			   INNER JOIN dbo.SalesOrder SO WITH (NOLOCK) ON SI.SalesOrderId = SO.SalesOrderId  
			   WHERE SI.SOBillingInvoicingId = CM.[InvoiceId] AND ISNULL(SI.[IsProforma],0) = 0
			   FOR XML PATH('')), 1, 1, '')   
			   END AS 'PORONum'  
	  ,CASE WHEN CM.[IsWorkOrder]=1 THEN (SELECT ISNULL(WB.WayBillRef,NULL) FROM [dbo].[WorkOrderBillingInvoicing] WB WITH (NOLOCK) WHERE WB.[BillingInvoicingId] = CM.[InvoiceId])  
			WHEN ISNULL(CM.InvoiceTypeId, 0) = @ExchangeInvoiceTypeId THEN '' 
			ELSE   
			(SELECT TOP 1 ISNULL(SAOS.AirwayBill,NULL) FROM [dbo].[SalesOrderBillingInvoicing] SB WITH (NOLOCK)   
			 LEFT JOIN SalesOrderBillingInvoicingItem SABI ON SB.SOBillingInvoicingId = SABI.SOBillingInvoicingId AND ISNULL(SABI.[IsProforma],0) = 0  
			 LEFT JOIN SalesOrderShipping SAOS ON SABI.SalesOrderShippingId = SAOS.SalesOrderShippingId  --and  SAOS.SalesOrderId = 192  
										   WHERE SB.[SOBillingInvoicingId] = CM.[InvoiceId] AND ISNULL(SB.[IsProforma],0) = 0 )  
          END AS 'Awb' 
	  ,ISNULL(CM.Amount,0) Amount,
	  CM.[IsStandAloneCM]
	 ,ISNULL(CM.InvoiceTypeId, 0) AS InvoiceTypeId
  
  FROM [dbo].[CreditMemo] CM WITH (NOLOCK)   
    INNER JOIN [dbo].[RMACreditMemoManagementStructureDetails] MS WITH (NOLOCK) ON CM.CreditMemoHeaderId = MS.ReferenceID AND MS.ModuleID = @ModuleID  
    LEFT JOIN [dbo].[CustomerRMAHeader] CRMA ON CRMA.RMAHeaderId = CM.RMAHeaderId  
	LEFT JOIN [dbo].[CustomerFinancial] CF WITH (NOLOCK) ON  CM.CustomerId = CF.CustomerId
    OUTER APPLY (SELECT TOP 1 CreditMemoDetailId FROM  CreditMemoDetails CD WITH (NOLOCK) WHERE CD.CreditMemoHeaderId = CM.CreditMemoHeaderId) CR   
  WHERE CM.CreditMemoHeaderId = @CreditMemoHeaderId;  
  
END TRY      
 BEGIN CATCH        
  IF @@trancount > 0  
   PRINT 'ROLLBACK'  
   ROLLBACK TRAN;  
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            , @AdhocComments     VARCHAR(150)    = 'GetCreditMemoById'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@CreditMemoHeaderId, '') + ''  
            , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
            exec spLogException   
                    @DatabaseName           = @DatabaseName  
                    , @AdhocComments          = @AdhocComments  
                    , @ProcedureParameters = @ProcedureParameters  
                    , @ApplicationName        =  @ApplicationName  
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;  
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
            RETURN(1);  
 END CATCH  
END